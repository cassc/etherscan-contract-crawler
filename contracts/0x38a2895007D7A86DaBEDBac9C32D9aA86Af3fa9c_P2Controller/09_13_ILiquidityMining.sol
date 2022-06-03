pragma solidity ^0.8.2;

interface ILiquidityMining {

    function updateBorrow(address xToken, address collection, uint256 amount, address account, uint256 orderId, bool isDeposit) external; 

    function updateSupply(address xToken, uint256 amount, address account, bool isDeposit) external;
}