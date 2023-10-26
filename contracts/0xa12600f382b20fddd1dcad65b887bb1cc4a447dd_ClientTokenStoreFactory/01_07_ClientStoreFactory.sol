// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {ClientTokenStore} from './ClientTokenStore.sol';
import {IClientTokenStoreFactory} from './interfaces/IClientTokenStoreFactory.sol';
import {Ownable} from 'oz/access/Ownable.sol';

contract ClientTokenStoreFactory is IClientTokenStoreFactory, Ownable {
  address public claimContract;

  constructor(address _claimContract) {
    claimContract = _claimContract;
  }

  function setClaimContract(address _claimContract) external onlyOwner {
    claimContract = _claimContract;
  }

  function createNewStore() external returns (address) {
    ClientTokenStore newStore = new ClientTokenStore(claimContract);
    newStore.transferOwnership(msg.sender);
    emit StoreCreated(address(newStore), msg.sender);
    return address(newStore);
  }
}