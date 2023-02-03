// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";

import { Trust } from "sense-v1-utils/Trust.sol";

import { AutoRoller, DividerLike, OwnedAdapterLike, RollerUtils, PeripheryLike } from "./AutoRoller.sol";
import { BaseSplitCodeFactory } from "./BaseSplitCodeFactory.sol";

interface RollerPeripheryLike {
    function approve(ERC20,address) external;
}

contract AutoRollerFactory is Trust, BaseSplitCodeFactory {
    error RollerQuantityLimitExceeded();

    DividerLike internal immutable divider;
    address     internal immutable balancerVault;

    PeripheryLike       public periphery;
    RollerPeripheryLike public rollerPeriphery;
    RollerUtils         public utils;

    mapping(address => AutoRoller[]) public rollers;

    constructor(
        DividerLike _divider,
        address _balancerVault,
        address _periphery,
        address _rollerPeriphery,
        RollerUtils _utils
    ) Trust(msg.sender) BaseSplitCodeFactory(type(AutoRoller).creationCode) {
        divider         = _divider;
        balancerVault   = _balancerVault;
        periphery       = PeripheryLike(_periphery);
        rollerPeriphery = RollerPeripheryLike(_rollerPeriphery);
        utils           = _utils;
    }

    function create(
        OwnedAdapterLike adapter,
        address rewardRecipient,
        uint256 targetDuration
    ) external returns (AutoRoller autoRoller) {
        ERC20 target = ERC20(address(adapter.target()));

        uint256 id = rollers[address(adapter)].length;

        if (id > 0 && !isTrusted[msg.sender]) revert RollerQuantityLimitExceeded();

        bytes memory constructorArgs = abi.encode(
            target,
            divider,
            address(periphery),
            address(periphery.spaceFactory()),
            address(balancerVault),
            adapter,
            utils,
            rewardRecipient
        );
        bytes32 salt = keccak256(abi.encode(constructorArgs, id));

        autoRoller = AutoRoller(super._create(constructorArgs, salt));

        // Factory must have adapter auth so that it can give auth to the roller
        adapter.setIsTrusted(address(autoRoller), true);

        autoRoller.setParam("TARGET_DURATION", targetDuration);
        autoRoller.setParam("OWNER", msg.sender);

        // Allow the new roller to move the roller periphery's target
        rollerPeriphery.approve(target, address(autoRoller));

        // Allow the adapter to move the roller periphery's underlying & target if it can't already
        ERC20 underlying = ERC20(adapter.underlying());
        if (underlying.allowance(address(rollerPeriphery), address(adapter)) == 0) {
            rollerPeriphery.approve(underlying, address(adapter));
        }
        if (target.allowance(address(rollerPeriphery), address(adapter)) == 0) {
            rollerPeriphery.approve(target, address(adapter));
        }

        rollers[address(adapter)].push(autoRoller);

        emit RollerCreated(address(adapter), address(autoRoller));
    }

    /// @notice Update the address for the Periphery
    /// @param newPeriphery The Periphery addresss to set
    function setPeriphery(address newPeriphery) external requiresTrust {
        emit PeripheryChanged(address(periphery), newPeriphery);
        periphery = PeripheryLike(newPeriphery);
    }

    /// @notice Update the address for the Roller Periphery
    /// @param newRollerPeriphery The Roller Periphery addresss to set
    function setRollerPeriphery(address newRollerPeriphery) external requiresTrust {
        emit RollerPeripheryChanged(address(rollerPeriphery), newRollerPeriphery);
        rollerPeriphery = RollerPeripheryLike(newRollerPeriphery);
    }

    /// @notice Update the address for the Utils
    /// @param newUtils The Utils addresss to set
    function setUtils(address newUtils) external requiresTrust {
        emit UtilsChanged(address(utils), newUtils);
        utils = RollerUtils(newUtils);
    }

    event PeripheryChanged(address indexed adapter, address autoRoller);
    event RollerPeripheryChanged(address indexed adapter, address autoRoller);
    event UtilsChanged(address indexed adapter, address autoRoller);
    event RollerCreated(address indexed adapter, address autoRoller);
}