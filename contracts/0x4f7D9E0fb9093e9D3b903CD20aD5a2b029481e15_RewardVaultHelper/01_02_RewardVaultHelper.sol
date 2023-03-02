// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;
pragma experimental ABIEncoderV2 ;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardVaultHelper {

    constructor (){}

    struct Balance {
        uint balance;
        uint totalHelds;
    }

    function getRewardVaultBalances(IRewardVault rewardVault, address[] calldata tokens) external view returns (Balance[] memory results){
        results = new Balance[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            uint balance = IERC20(tokens[i]).balanceOf(address(rewardVault));
            uint totalShares = rewardVault.totalShare(IERC20(tokens[i]));
            results[i] = Balance(balance, totalShares);
        }
        return results;
    }
}

interface IRewardVault {
    function totalShare(IERC20 token) external view returns (uint);
}