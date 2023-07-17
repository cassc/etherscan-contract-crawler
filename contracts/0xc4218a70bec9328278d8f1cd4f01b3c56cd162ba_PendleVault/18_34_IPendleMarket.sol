pragma solidity 0.8.7;

interface IPendleMarket {
    function redeemRewards(address user) external;
    function getRewardTokens() external returns(address[] memory);
}