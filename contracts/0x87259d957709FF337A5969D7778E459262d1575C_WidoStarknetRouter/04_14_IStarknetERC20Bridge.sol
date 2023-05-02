pragma solidity 0.8.7;

interface IStarknetERC20Bridge  {
    function deposit(uint256 amount, uint256 l2Recipient) external payable;

    function withdraw(uint256 amount, address recipient) external;
}