import AVFoundation

public class TracerAudioUnit: AUAudioUnit, @unchecked Sendable {
    // C++ Objects
    var kernel = TracerDSPKernel()
    var processHelper: AUProcessHelper?
    var inputBus = BufferedInputBus()

    private var outputBus: AUAudioUnitBus?
    private var _inputBusses: AUAudioUnitBusArray!
    private var _outputBusses: AUAudioUnitBusArray!

    @objc override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions) throws {
        // Tracer only tracks a single monophonic pitch, so both busses are fixed mono.
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        try super.init(componentDescription: componentDescription, options: options)
        outputBus = try AUAudioUnitBus(format: format)
        outputBus?.maximumChannelCount = 1

        // Create the input and output busses.
        inputBus.initialize(format, 1)

        // Create the input and output bus arrays.
        _inputBusses = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.input, busses: [inputBus.bus!])
        _outputBusses = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [outputBus!])

        processHelper = AUProcessHelper(&kernel, &inputBus)
    }

    public override var inputBusses: AUAudioUnitBusArray {
        return _inputBusses
    }

    public override var outputBusses: AUAudioUnitBusArray {
        return _outputBusses
    }

    public override var channelCapabilities: [NSNumber] {
        get {
            return [NSNumber(value: 1), NSNumber(value: 1)]
        }
    }

    public override var maximumFramesToRender: AUAudioFrameCount {
        get {
            return kernel.maximumFramesToRender()
        }

        set {
            kernel.setMaximumFramesToRender(newValue)
        }
    }

    public override var shouldBypassEffect: Bool {
        get {
            return kernel.isBypassed()
        }

        set {
            kernel.setBypass(newValue)
        }
    }

    // MARK: - MIDI
    public override var midiOutputNames: [String] {
        return ["Tracer MIDI Out"]
    }

    // MARK: - Rendering
    public override var internalRenderBlock: AUInternalRenderBlock {
        return processHelper!.internalRenderBlock()
    }

    // Allocate resources required to render.
    // Subclassers should call the superclass implementation.
    public override func allocateRenderResources() throws {
        let inputChannelCount = self.inputBusses[0].format.channelCount
        let outputChannelCount = self.outputBusses[0].format.channelCount

        if outputChannelCount != inputChannelCount {
            setRenderResourcesAllocated(false)
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
        }

        inputBus.allocateRenderResources(self.maximumFramesToRender)

        if let midiBlock = self.midiOutputEventBlock {
            kernel.setMIDIOutputEventBlock(midiBlock)
        }
        kernel.initialize(Int32(inputChannelCount), Int32(outputChannelCount), outputBus!.format.sampleRate)
        processHelper?.setChannelCount(UInt32(inputChannelCount), UInt32(outputChannelCount))

        try super.allocateRenderResources()
    }

    // Deallocate resources allocated in allocateRenderResources().
    // Subclassers should call the superclass implementation.
    public override func deallocateRenderResources() {
        kernel.deInitialize()
        super.deallocateRenderResources()
    }

    public func setupParameterTree(_ parameterTree: AUParameterTree) {
        self.parameterTree = parameterTree

        // Set the Parameter default values before setting up the parameter callbacks.
        for param in parameterTree.allParameters {
            kernel.setParameter(param.address, param.value)
        }

        setupParameterCallbacks()
    }

    private func setupParameterCallbacks() {
        // implementorValueObserver is called when a parameter changes value.
        parameterTree?.implementorValueObserver = { [weak self] param, value -> Void in
            self?.kernel.setParameter(param.address, value)
        }

        // implementorValueProvider is called when the value needs to be refreshed.
        parameterTree?.implementorValueProvider = { [weak self] param in
            return self!.kernel.getParameter(param.address)
        }

        // A function to provide string representations of parameter values.
        parameterTree?.implementorStringFromValueCallback = { param, valuePtr in
            guard let value = valuePtr?.pointee else {
                return "-"
            }
            return NSString.localizedStringWithFormat("%.f", value) as String
        }
    }
}
