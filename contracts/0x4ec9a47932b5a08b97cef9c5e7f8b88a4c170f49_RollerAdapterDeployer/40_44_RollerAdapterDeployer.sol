// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;
import { AutoRoller, OwnedAdapterLike } from "./AutoRoller.sol";
import { AutoRollerFactory } from "./AutoRollerFactory.sol";
import { Divider } from "sense-v1-core/Divider.sol";
import { Periphery } from "sense-v1-core/Periphery.sol";

interface OwnableFactoryLike {
    function rlvFactory() external view returns (address);
    function deployAdapter(address, bytes memory) external returns (address);
}

contract RollerAdapterDeployer {
    Divider public immutable divider;

    constructor(address _divider) {
        divider = Divider(_divider);
    }

    /// @notice Deploys an OwnableERC4626Adapter and a Roller contract
    /// @param factory The adapter factory
    /// @param target The target address
    /// @param data ABI encoded reward tokens address array
    /// @param rewardRecipient The address of the reward recipient
    /// @param targetDuration The targeted duration in months for newly rolled series
    function deploy(address factory, address target, bytes memory data, address rewardRecipient, uint256 targetDuration) external returns (address adapter, AutoRoller autoRoller) {
        adapter = Periphery(divider.periphery()).deployAdapter(factory, target, data);
        AutoRollerFactory rlvFactory = AutoRollerFactory(OwnableFactoryLike(factory).rlvFactory());
        autoRoller = rlvFactory.create(OwnedAdapterLike(adapter), rewardRecipient, targetDuration);
        autoRoller.setParam("OWNER", msg.sender);

        emit RollerAdapterDeployed(address(autoRoller), adapter);
    }

    /* ========== EVENTS ========== */

    event RollerAdapterDeployed(address autoRoller, address adapter);
}