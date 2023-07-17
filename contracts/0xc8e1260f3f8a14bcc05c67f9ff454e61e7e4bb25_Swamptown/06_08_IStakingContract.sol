pragma solidity ^0.8.4;
interface IStakingContract {
  function balanceOf(address owner) external view returns (uint256);
  function stakedCreaturesByOwner(address account)
        external
        view
        returns (uint256[] memory);
}