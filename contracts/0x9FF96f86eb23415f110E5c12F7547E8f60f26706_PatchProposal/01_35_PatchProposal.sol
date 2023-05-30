// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { LoopbackProxy } from "../v1/LoopbackProxy.sol";
import { AdminUpgradeableProxy } from "./AdminUpgradeableProxy.sol";

import { GovernancePatchUpgrade } from "./GovernancePatchUpgrade.sol";
import { TornadoStakingRewards } from "./TornadoStakingRewards.sol";
import { RelayerRegistry } from "./RelayerRegistry.sol";

/**
 * @notice Proposal which should patch governance against the metamorphic contract replacement vulnerability and also fix several issues which have appeared as a result of the attack.
 */
contract PatchProposal {
    // Address of the old staking proxy
    address public constant oldStakingProxyAddress = 0x2FC93484614a34f26F7970CBB94615bA109BB4bf;

    // Address of the registry proxy
    address public constant registryProxyAddress = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;

    // Address of the gas compensation vault
    address public constant gasCompensationVaultAddress = 0xFA4C1f3f7D5dd7c12a9Adb82Cd7dDA542E3d59ef;

    // Address of the user vault
    address public constant userVaultAddress = 0x2F50508a8a3D323B91336FA3eA6ae50E55f32185;

    // Address of the governance proxy
    address payable public constant governanceProxyAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;

    // Torn token
    IERC20 public constant TORN = IERC20(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);

    // The staking proxy (pointing to a new implementation (with same code)) that we've deployed
    address public immutable deployedStakingProxyContractAddress;

    // The registry implementation (with same code) that we've deployed
    address public immutable deployedRelayerRegistryImplementationAddress;

    constructor(
        address _deployedStakingProxyContractAddress,
        address _deployedRelayerRegistryImplementationAddress
    ) public {
        deployedStakingProxyContractAddress = _deployedStakingProxyContractAddress;
        deployedRelayerRegistryImplementationAddress = _deployedRelayerRegistryImplementationAddress;
    }

    /// @notice Function to execute the proposal.
    function executeProposal() external {
        // Get the old staking contract
        TornadoStakingRewards oldStaking = TornadoStakingRewards(oldStakingProxyAddress);

        // Get the small amount of TORN left
        oldStaking.withdrawTorn(TORN.balanceOf(address(oldStaking)));

        // Upgrade the registry proxy
        AdminUpgradeableProxy(payable(registryProxyAddress)).upgradeTo(
            deployedRelayerRegistryImplementationAddress
        );

        // Now upgrade the governance implementation to the vulnerability resistant one
        LoopbackProxy(governanceProxyAddress).upgradeTo(
            address(
                new GovernancePatchUpgrade(
                deployedStakingProxyContractAddress,
                gasCompensationVaultAddress,
                userVaultAddress
                )
            )
        );

        // Transfer TORN in compensation to the staking proxy
        TORN.transfer(deployedStakingProxyContractAddress, 94_092 ether);
    }
}