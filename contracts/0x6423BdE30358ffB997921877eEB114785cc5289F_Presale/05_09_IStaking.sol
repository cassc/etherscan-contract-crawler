pragma solidity ^0.8.9;

interface IStaking {

    function stakePresale(address _to, uint256 _amount, uint256 _ethDeposited) external;

}