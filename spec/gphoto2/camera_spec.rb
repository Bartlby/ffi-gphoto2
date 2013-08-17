require 'spec_helper'

module GPhoto2
  describe Camera do
    let(:port) { double('entry', name: 'model', value: 'usb:250,006') }

    describe '.autodetect' do
      it 'returns a list of device entries' do
        abilities_list = double('camera_abilities_list')
        camera_list = double('camera_list')

        Context.stub(:stub)
        CameraAbilitiesList.stub(:new).and_return(abilities_list)
        abilities_list.stub(:detect).and_return(camera_list)
        camera_list.stub(:to_a).and_return([])

        expect(Camera.autodetect).to be_kind_of(Array)
      end
    end

    describe '.first' do
      context 'when devices are automatically detected' do
        it 'returns a new Camera using the first entry' do
          Camera.stub(:autodetect).and_return([port])
          expect(Camera.first).to be_kind_of(Camera)
        end
      end

      context 'when no devices are detected' do
        it 'raises a RuntimeError' do
          Camera.stub(:autodetect).and_return([])
          expect { Camera.first }.to raise_error(RuntimeError)
        end
      end
    end

    describe '.open' do
      let(:camera) { double('camera') }
      before { Camera.stub(:new).and_return(camera) }

      context 'when a block is given' do
        it 'yeilds a new camera instance' do
          expect(Camera).to receive(:open).and_yield(camera)
          Camera.open(port) { |c| }
        end

        it 'finalizes the camera when the block terminates' do
          expect(camera).to receive(:finalize)
          Camera.open(port) { |c| }
        end
      end

      context 'when no block is given' do
        it 'returns a new camera instance' do
           expect(Camera.open(port)).to eq(camera)
        end
      end
    end

    describe '#capture' do
      let(:camera) { Camera.new(port) }
      let(:path) { double('camera_file_path') }
      let(:file) { double('camera_file') }

      before do
        camera.stub(:_capture).and_return(path)
        camera.stub(:file_get).and_return(file)
      end

      it 'saves the camera configuration' do
        expect(camera).to receive(:save)
        camera.capture
      end

      it 'returns a new CameraFile' do
        expect(camera).to receive(:_capture)
        expect(camera).to receive(:file_get).with(path)
        expect(camera.capture).to eq(file)
      end
    end

    describe '#window' do
      let(:camera) { Camera.new(port) }
      let(:window) { double('camera_widget') }

      it 'always returns the same CameraWidget instance' do
        camera.stub(:get_config).and_return(window)
        expect(camera.window).to eq(window)
        expect(camera.window).to eq(window)
      end
    end

    describe '#config' do
      it 'returns a map of configuration widgets' do
        camera = Camera.new(port)
        window = double('camera_widget')
        camera.stub(:window).and_return(window)
        window.stub(:flatten).and_return({ 'iso' => window })

        expect(camera.config).to eq({ 'iso' => window })
      end
    end

    describe '#[]' do
      let(:window) { double('camera_widget') }

      let(:camera) do
        camera = Camera.new(port)
        camera.stub(:config).and_return({ 'iso' => window })
        camera
      end

      context 'when the specified key exists' do
        it 'returns a CameraWidget' do
          expect(camera['iso']).to eq(window)
        end
      end

      context 'when the specified key does not exist' do
        it 'returns nil' do
          expect(camera['shutterspeed2']).to be_nil
        end
      end
    end

    describe '#[]=' do
      let(:window) do
        window = double('camera_widget')
        expect(window).to receive(:value=).with(400)
        window
      end

      let(:camera) do
        camera = Camera.new(port)
        camera.stub(:[]).and_return(window)
        camera
      end

      it "set a widget's value" do
        camera['iso'] = 400
      end

      it 'marks the camera as dirty' do
        camera['iso'] = 400
        expect(camera).to be_dirty
      end

      it 'returns the passed value' do
        expect(camera['iso'] = 400).to eq(400)
      end
    end

    describe '#dirty?' do
      context 'when the configuration changed' do
        it 'returns true' do
          camera = Camera.new(port)
          camera.stub_chain(:[], :value=)

          camera['iso'] = 400

          expect(camera).to be_dirty
        end
      end

      context 'when the configuration has not changed' do
        it 'returns false' do
          camera = Camera.new(port)
          expect(camera).not_to be_dirty 
        end
      end
    end

    describe '#save' do
      let(:camera) do
        camera = Camera.new(port)
        camera.stub_chain(:[], :value=)
        camera.stub(:set_config)
        camera
      end

      context 'when the camera is marked as dirty' do
        it 'returns true' do
          camera['iso'] = 400
          expect(camera.save).to be_true
        end

        it 'marks the camera as not dirty' do
          camera['iso'] = 400
          camera.save
          expect(camera).not_to be_dirty
        end
      end

      context 'when the camera is not marked as dirty' do
        it 'returns false' do
          expect(camera.save).to be_false
        end
      end
    end
  end
end
