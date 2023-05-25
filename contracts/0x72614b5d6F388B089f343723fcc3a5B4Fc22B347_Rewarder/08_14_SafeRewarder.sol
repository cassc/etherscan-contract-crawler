// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Rewarder {}

library SafeRewarder {
    event UpdateUserFailed(Rewarder rewarder, uint256 poolId, address user,  uint256 rewardableDeposit, string reason);
    event ClaimFailed(Rewarder rewarder, uint256 poolId, address user, address to, string reason);

    function updateUser(Rewarder rewarder, uint256 poolId, address user, uint256 rewardableDeposit) internal {
        (bool success, bytes memory returndata) = address(rewarder).call(abi.encodeWithSignature("updateUser(uint256,address,uint256)", poolId, user, rewardableDeposit));
        if(!success) {
            emit UpdateUserFailed(rewarder, poolId, user,  rewardableDeposit, string(returndata));
        }
    }

    function claim(Rewarder rewarder, uint256 poolId, address user, address to) internal {
        (bool success, bytes memory returndata) = address(rewarder).call(abi.encodeWithSignature("claim(uint256,address,address)", poolId, user, to));
        if(!success) {
            emit ClaimFailed(rewarder, poolId, user, to, string(returndata));
        }
    }
}