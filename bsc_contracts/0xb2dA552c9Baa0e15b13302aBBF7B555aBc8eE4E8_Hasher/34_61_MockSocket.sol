// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint256 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

contract MockSocket {
    uint256 public immutable _chainSlug;

    error WrongRemotePlug();
    error WrongIntegrationType();

    struct PlugConfig {
        address remotePlug;
        bytes32 inboundIntegrationType;
        bytes32 outboundIntegrationType;
    }

    // integrationType => remoteChainSlug => address
    mapping(bytes32 => mapping(uint256 => bool)) public configExists;
    // plug => remoteChainSlug => config(verifiers, capacitors, decapacitors, remotePlug)
    mapping(address => mapping(uint256 => PlugConfig)) public plugConfigs;

    error InvalidIntegrationType();

    constructor() {
        _chainSlug = 1;

        configExists[keccak256(abi.encode("FAST"))][1] = true;
        configExists[keccak256(abi.encode("SLOW"))][1] = true;
        configExists[keccak256(abi.encode("NATIVE_BRIDGE"))][1] = true;

        configExists[keccak256(abi.encode("FAST"))][2] = true;
        configExists[keccak256(abi.encode("SLOW"))][2] = true;
        configExists[keccak256(abi.encode("NATIVE_BRIDGE"))][2] = true;
    }

    function setPlugConfig(
        uint256 remoteChainSlug_,
        address remotePlug_,
        string memory inboundIntegrationType_,
        string memory outboundIntegrationType_
    ) external {
        bytes32 inboundIntegrationType = keccak256(
            abi.encode(inboundIntegrationType_)
        );
        bytes32 outboundIntegrationType = keccak256(
            abi.encode(outboundIntegrationType_)
        );
        if (
            !configExists[inboundIntegrationType][remoteChainSlug_] ||
            !configExists[outboundIntegrationType][remoteChainSlug_]
        ) revert InvalidIntegrationType();

        PlugConfig storage plugConfig = plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        plugConfig.remotePlug = remotePlug_;
        plugConfig.inboundIntegrationType = inboundIntegrationType;
        plugConfig.outboundIntegrationType = outboundIntegrationType;
    }

    function getPlugConfig(
        uint256 remoteChainSlug_,
        address plug_
    )
        external
        view
        returns (
            address capacitor,
            address decapacitor,
            address verifier,
            address remotePlug,
            bytes32 outboundIntegrationType,
            bytes32 inboundIntegrationType
        )
    {
        PlugConfig memory plugConfig = plugConfigs[plug_][remoteChainSlug_];
        return (
            address(0),
            address(0),
            address(0),
            plugConfig.remotePlug,
            plugConfig.outboundIntegrationType,
            plugConfig.inboundIntegrationType
        );
    }

    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable returns (uint256) {
        PlugConfig memory srcPlugConfig = plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        PlugConfig memory dstPlugConfig = plugConfigs[srcPlugConfig.remotePlug][
            _chainSlug
        ];

        if (dstPlugConfig.remotePlug != msg.sender) revert WrongRemotePlug();
        if (
            srcPlugConfig.outboundIntegrationType !=
            dstPlugConfig.inboundIntegrationType &&
            srcPlugConfig.inboundIntegrationType !=
            dstPlugConfig.outboundIntegrationType
        ) revert WrongIntegrationType();

        IPlug(srcPlugConfig.remotePlug).inbound{gas: msgGasLimit_}(
            _chainSlug,
            payload_
        );
    }
}