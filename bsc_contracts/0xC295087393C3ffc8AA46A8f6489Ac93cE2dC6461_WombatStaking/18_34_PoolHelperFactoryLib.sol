// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../wombat/WombatPoolHelper.sol";

/// @title PoolHelperFactoryLib
/// @author Magpie Team
/// @notice WombatStaking is the contract that interacts with ALL Wombat contract
/// @dev all functions except harvest are restricted either to owner or to other contracts from the magpie protocol
/// @dev the owner of this contract holds a lot of power, and should be owned by a multisig
library PoolHelperFactoryLib {
    function createWombatPoolHelper(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _lpToken,
        address _wombatStaking,
        address _masterMagpie,
        address _rewarder,
        address _mWom,
        bool _isNative
    ) public returns(address) 
    {
        WombatPoolHelper pool = new WombatPoolHelper(_pid, _stakingToken, _depositToken, _lpToken, _wombatStaking, _masterMagpie, _rewarder, _mWom, _isNative);
        return address(pool);
    }
}