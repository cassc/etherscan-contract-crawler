pragma solidity 0.5.16;

interface IETF {
  function rebase(uint256 epoch, uint256 supplyDelta, bool positive) external;
  function mint(address to, uint256 amount) external;
  function getPriorBalance(address account, uint blockNumber) external view returns (uint256);
  function mintForReferral(address to, uint256 amount) external;
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function transferForRewards(address to, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);
}