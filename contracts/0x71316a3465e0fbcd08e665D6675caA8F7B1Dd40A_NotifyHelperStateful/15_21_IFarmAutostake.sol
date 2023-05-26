pragma solidity 0.5.16;

interface IFarmAutostake {
  function refreshAutoStake() external;
  function stake(uint256 amount) external;
  function exit() external;
  function balanceOf(address who) external view returns(uint256);
}