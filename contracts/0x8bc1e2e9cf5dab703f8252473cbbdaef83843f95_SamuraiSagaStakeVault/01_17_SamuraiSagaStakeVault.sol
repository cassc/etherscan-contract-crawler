// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@minting-station/contracts/contracts/NftStakeVault.sol";
import "./interfaces/IMintableERC20.sol";

/** @title SamuraiSagaStakeVault
 */
contract SamuraiSagaStakeVault is NftStakeVault {
    constructor(IERC721 _nftCollection, IMintableERC20 _rewardToken) 
        NftStakeVault(_nftCollection, _rewardToken) {
    }

    function _sendRewards(address destination, uint256 amount) internal override {
        IMintableERC20(address(rewardToken)).mint(destination, amount);
    }
}