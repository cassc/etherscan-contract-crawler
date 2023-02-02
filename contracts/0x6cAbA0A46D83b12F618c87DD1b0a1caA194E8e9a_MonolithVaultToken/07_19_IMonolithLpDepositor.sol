pragma solidity >=0.5.0;

interface IMonolithLpDepositor {
    function gaugeForPool(address pool) external view returns (address);

    function multiRewarder() external view returns (address);

    function userBalances(address, address) external view returns (uint256);

    function deposit(address pool, uint256 amount, address[] calldata rewardTokens) external;

    function withdraw(address pool, uint256 amount) external;

    function poke(address pool, address[] calldata rewardTokens, address to) external;
}