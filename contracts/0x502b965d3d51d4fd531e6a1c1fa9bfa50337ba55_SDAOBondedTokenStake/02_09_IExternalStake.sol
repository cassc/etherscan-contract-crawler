pragma solidity ^0.6.0;

interface IExternalStake {
    function submitStakeFor(address staker, uint256 stakeAmount) external returns(bool);
}