// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { StakingFundsVault } from "./StakingFundsVault.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract StakingFundsVaultDeployer {

    event NewVaultDeployed(address indexed instance);

    /// @notice Implementation at the time of deployment
    address public implementation;

    /// @notice Beacon referenced by each deployment of a staking funds vault
    address public beacon;

    constructor(address _upgradeManager) {
        implementation = address(new StakingFundsVault());
        beacon = address(new UpgradeableBeacon(implementation, _upgradeManager));
    }

    function deployStakingFundsVault(address _liquidStakingManager, address _tokenFactory) external returns (address) {
        address newVault = address(new BeaconProxy(
                beacon,
                abi.encodeCall(
                    StakingFundsVault(payable(implementation)).init,
                    (_liquidStakingManager, LPTokenFactory(_tokenFactory))
                )
            ));

        emit NewVaultDeployed(newVault);

        return newVault;
    }
}