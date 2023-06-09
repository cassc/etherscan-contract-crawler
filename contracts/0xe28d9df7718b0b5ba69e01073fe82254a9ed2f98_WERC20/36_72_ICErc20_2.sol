pragma solidity 0.6.12;

interface ICErc20_2 {
  function underlying() external returns (address);

  function mint(uint mintAmount) external returns (uint);

  function redeem(uint redeemTokens) external returns (uint);

  function balanceOf(address user) external view returns (uint);

  function setMintRate(uint mintRate) external;
}