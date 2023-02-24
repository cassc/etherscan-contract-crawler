// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/ISocket.sol";
import "../utils/Ownable.sol";
import "../interfaces/ICapacitorFactory.sol";
import "../interfaces/ISwitchboard.sol";
import {AccessControl} from "../utils/AccessControl.sol";

abstract contract SocketConfig is ISocket, Ownable(msg.sender) {
    struct PlugConfig {
        address siblingPlug;
        ICapacitor capacitor__;
        IDecapacitor decapacitor__;
        ISwitchboard inboundSwitchboard__;
        ISwitchboard outboundSwitchboard__;
    }

    ICapacitorFactory public capacitorFactory__;

    // siblingChainSlug => capacitor address
    mapping(address => uint256) public capacitorToSlug;

    // switchboard => siblingChainSlug => ICapacitor
    mapping(address => mapping(uint256 => ICapacitor)) public capacitors__;
    // switchboard => siblingChainSlug => IDecapacitor
    mapping(address => mapping(uint256 => IDecapacitor)) public decapacitors__;

    // plug | remoteChainSlug => (siblingPlug, capacitor__, decapacitor__, inboundSwitchboard__, outboundSwitchboard__)
    mapping(uint256 => PlugConfig) internal _plugConfigs;

    event SwitchboardAdded(
        address switchboard,
        uint256 siblingChainSlug,
        address capacitor,
        address decapacitor
    );
    event CapacitorFactorySet(address capacitorFactory);

    error SwitchboardExists();
    error InvalidConnection();

    function setCapacitorFactory(address capacitorFactory_) external onlyOwner {
        capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
        emit CapacitorFactorySet(capacitorFactory_);
    }

    function registerSwitchBoard(
        address switchBoardAddress_,
        uint32 siblingChainSlug_,
        uint32 capacitorType_
    ) external {
        // only capacitor checked, decapacitor assumed will exist if capacitor does
        if (
            address(capacitors__[switchBoardAddress_][siblingChainSlug_]) !=
            address(0)
        ) revert SwitchboardExists();

        (
            ICapacitor capacitor__,
            IDecapacitor decapacitor__
        ) = capacitorFactory__.deploy(capacitorType_, siblingChainSlug_);

        capacitorToSlug[address(capacitor__)] = siblingChainSlug_;
        capacitors__[switchBoardAddress_][siblingChainSlug_] = capacitor__;
        decapacitors__[switchBoardAddress_][siblingChainSlug_] = decapacitor__;

        emit SwitchboardAdded(
            switchBoardAddress_,
            siblingChainSlug_,
            address(capacitor__),
            address(decapacitor__)
        );
    }

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external override {
        if (
            address(capacitors__[inboundSwitchboard_][siblingChainSlug_]) ==
            address(0) ||
            address(capacitors__[outboundSwitchboard_][siblingChainSlug_]) ==
            address(0)
        ) revert InvalidConnection();

        PlugConfig storage _plugConfig = _plugConfigs[
            (uint256(uint160(msg.sender)) << 96) | siblingChainSlug_
        ];

        _plugConfig.siblingPlug = siblingPlug_;
        _plugConfig.capacitor__ = capacitors__[outboundSwitchboard_][
            siblingChainSlug_
        ];
        _plugConfig.decapacitor__ = decapacitors__[inboundSwitchboard_][
            siblingChainSlug_
        ];
        _plugConfig.inboundSwitchboard__ = ISwitchboard(inboundSwitchboard_);
        _plugConfig.outboundSwitchboard__ = ISwitchboard(outboundSwitchboard_);

        emit PlugConnected(
            msg.sender,
            siblingChainSlug_,
            _plugConfig.siblingPlug,
            address(_plugConfig.inboundSwitchboard__),
            address(_plugConfig.outboundSwitchboard__),
            address(_plugConfig.capacitor__),
            address(_plugConfig.decapacitor__)
        );
    }

    function getPlugConfig(
        address plugAddress_,
        uint256 siblingChainSlug_
    )
        external
        view
        returns (
            address siblingPlug,
            address inboundSwitchboard__,
            address outboundSwitchboard__,
            address capacitor__,
            address decapacitor__
        )
    {
        PlugConfig memory _plugConfig = _plugConfigs[
            (uint256(uint160(plugAddress_)) << 96) | siblingChainSlug_
        ];

        return (
            _plugConfig.siblingPlug,
            address(_plugConfig.inboundSwitchboard__),
            address(_plugConfig.outboundSwitchboard__),
            address(_plugConfig.capacitor__),
            address(_plugConfig.decapacitor__)
        );
    }
}