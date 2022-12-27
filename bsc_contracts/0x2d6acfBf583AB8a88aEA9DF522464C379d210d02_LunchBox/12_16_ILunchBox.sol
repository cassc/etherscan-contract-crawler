// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with the LunchBox contract.
*/
interface ILunchBox {
    function stakeForSeniorage(uint256 busdAmount) external;
    function stakeForSeniorage(
        uint256 zoinksAmount,
        uint256 btcAmount,
        uint256 ethAmount,
        uint256 snacksAmount,
        uint256 btcSnacksAmount,
        uint256 ethSnacksAmount,
        uint256 zoinksBusdAmountOutMin,
        uint256 btcBusdAmountOutMin,
        uint256 ethBusdAmountOutMin
    )
        external;
    function stakeForSnacksPool(
        uint256 snacksAmount,
        uint256 btcSnacksAmount,
        uint256 ethSnacksAmount,
        uint256 zoinksBusdAmountOutMin,
        uint256 btcBusdAmountOutMin,
        uint256 ethBusdAmountOutMin
    )
        external;
    function updateRewardForUser(address user) external;
    function updateTotalSupplyFactor(uint256 totalSupplyBefore) external;
    function getReward(address user) external;
}