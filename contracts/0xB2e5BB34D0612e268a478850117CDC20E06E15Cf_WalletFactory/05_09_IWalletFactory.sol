pragma solidity ^0.8.0;

interface IWalletFactory {
  function verify(bytes calldata, bytes calldata) external view returns (bool);
  function comissionsAddress() external view returns (address);
}