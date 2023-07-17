pragma solidity ^0.8.4;
interface INftContract {
  function balanceOf(address owner) external view returns (uint256);
}