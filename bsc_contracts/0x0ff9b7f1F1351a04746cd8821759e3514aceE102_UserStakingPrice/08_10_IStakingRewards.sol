pragma solidity ^0.5.17;

interface IStakingRewards {

    function balanceOf(address account) external view returns (uint256);

}