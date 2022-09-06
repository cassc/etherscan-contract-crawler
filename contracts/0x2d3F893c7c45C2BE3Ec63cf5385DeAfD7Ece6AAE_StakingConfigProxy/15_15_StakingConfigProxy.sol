// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "@ankr.com/contracts/libs/ManageableProxy.sol";
import "@ankr.com/contracts/staking/StakingConfig.sol";

contract StakingConfigProxy is ManageableProxy {

    constructor(
        uint32 activeValidatorsLength,
        uint32 epochBlockInterval,
        uint32 misdemeanorThreshold,
        uint32 felonyThreshold,
        uint32 validatorJailEpochLength,
        uint32 undelegatePeriod,
        uint256 minValidatorStakeAmount,
        uint256 minStakingAmount,
        address governanceAddress,
        address treasuryAddress,
        uint64 lockPeriod
    ) ManageableProxy(
        IGovernable(address(this)), _deployDefault(), abi.encodeWithSelector(StakingConfig.initialize.selector,
        activeValidatorsLength,
        epochBlockInterval,
        misdemeanorThreshold,
        felonyThreshold,
        validatorJailEpochLength,
        undelegatePeriod,
        minValidatorStakeAmount,
        minStakingAmount,
        governanceAddress,
        treasuryAddress,
        lockPeriod
        )
    ) {
    }

    function _deployDefault() internal returns (address) {
        StakingConfig impl = new StakingConfig{
        salt : keccak256("StakingConfigV0")
        }();
        return address(impl);
    }
}