pragma solidity ^0.6.0;

interface IAutoStakeFor {
    function stakeFor(address _for, uint256 amount) external;
}