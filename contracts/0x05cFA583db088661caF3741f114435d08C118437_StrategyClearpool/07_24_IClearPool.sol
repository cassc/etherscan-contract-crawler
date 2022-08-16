//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IClearPool {
    function provide(uint256 currencyAmount) external;
    function redeem(uint256 tokens) external;
}

interface IClearPoolFactory {
    function withdrawReward(address[] memory pools) external;
}