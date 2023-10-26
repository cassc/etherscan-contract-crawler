//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IClientTokenStoreFactory {
  event ClaimContractSet(address _claimContract);
  event StoreCreated(address _store, address _owner);
  function claimContract() external view returns (address);
  function createNewStore() external returns (address);
}