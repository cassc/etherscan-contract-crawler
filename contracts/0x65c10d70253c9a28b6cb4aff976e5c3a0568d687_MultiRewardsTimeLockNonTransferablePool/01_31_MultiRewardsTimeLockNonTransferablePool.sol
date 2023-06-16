// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./MultiRewardsTimeLockPool.sol";

contract MultiRewardsTimeLockNonTransferablePool is MultiRewardsTimeLockPool {
    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address[] memory _rewardTokens,
        address[] memory _escrowPools,
        uint256[] memory _escrowPortions,
        uint256[] memory _escrowDurations,
        uint256 _maxBonus,
        uint256 _maxLockDuration
    ) MultiRewardsTimeLockPool(_name, _symbol, _depositToken, _rewardTokens, _escrowPools, _escrowPortions, _escrowDurations, _maxBonus, _maxLockDuration) {

    }

    // disable transfers
    function _transfer(address _from, address _to, uint256 _amount) internal override {
        revert("NON_TRANSFERABLE");
    }
}