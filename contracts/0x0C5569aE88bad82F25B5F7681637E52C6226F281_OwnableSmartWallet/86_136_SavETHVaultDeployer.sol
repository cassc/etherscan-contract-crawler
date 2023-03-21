pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { SavETHVault } from "./SavETHVault.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract SavETHVaultDeployer {

    event NewVaultDeployed(address indexed instance);

    /// @notice Implementation at the time of deployment
    address public implementation;

    /// @notice Beacon referenced by each deployment of a savETH vault
    address public beacon;

    constructor(address _upgradeManager) {
        implementation = address(new SavETHVault());
        beacon = address(new UpgradeableBeacon(implementation, _upgradeManager));
    }

    function deploySavETHVault(address _liquidStakingManger, address _lpTokenFactory) external returns (address) {
        address newVault = address(new BeaconProxy(
                beacon,
                abi.encodeCall(
                    SavETHVault(payable(implementation)).init,
                    (_liquidStakingManger, LPTokenFactory(_lpTokenFactory))
                )
            ));

        emit NewVaultDeployed(newVault);

        return newVault;
    }
}