pragma solidity ^0.8.1;
interface IExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}