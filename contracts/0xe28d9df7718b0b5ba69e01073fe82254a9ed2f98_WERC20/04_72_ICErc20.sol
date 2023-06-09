pragma solidity 0.6.12;

interface ICErc20 {
  function underlying() external returns (address);

  function mint(uint mintAmount) external returns (uint);

  function redeem(uint redeemTokens) external returns (uint);

  function balanceOf(address user) external view returns (uint);

  function borrowBalanceCurrent(address account) external returns (uint);

  function borrowBalanceStored(address account) external view returns (uint);

  function borrow(uint borrowAmount) external returns (uint);

  function repayBorrow(uint repayAmount) external returns (uint);
}