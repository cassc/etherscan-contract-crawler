//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import './OperatorHub.sol';
import './ERC721Mintable.sol';

contract HomeGate is OperatorHub {
  uint64 constant PREFIX = 0xef4810cde406e3f5; // random number

  constructor(HashStore _hashStore, uint8 requiredOperators, address[] memory initialOperators)
    OperatorHub(_hashStore, requiredOperators, initialOperators) {
  }

  function canWithdraw(
    bytes32 transactionHash,
    address tokenContract,
    address recipient,
    uint256 value
  ) public view returns (bool) {
    require(tokenContract != address(0x0), "should provide a token contract");
    require(recipient != address(0x0), "should provide a recipient");
    require(value > 0, "should provide value");
    require(transactionHash > 0, "TX hash should be provided");

    bytes32 hash = prefixed(keccak256(abi.encodePacked(PREFIX, transactionHash, tokenContract, recipient, value)));

    return !hashStore.hashes(hash);
  }

  function withdraw(
    bytes32 transactionHash,
    address tokenContract,
    address recipient,
    uint256 value,
    uint8[] memory v,
    bytes32[] memory r,
    bytes32[] memory s
  ) external {
    require(tokenContract != address(0x0), "should provide a token contract");
    require(value > 0, "should provide value");
    require(transactionHash > 0, "TX hash should be provided");
    require(recipient == msg.sender, "should be the recipient");

    bytes32 hash = prefixed(keccak256(abi.encodePacked(PREFIX, transactionHash, tokenContract, recipient, value)));

    hashStore.addHash(hash);

    require(v.length > 0, "should provide signatures at least one signature");
    require(v.length == r.length, "should the same number of inputs for signatures (r)");
    require(v.length == s.length, "should the same number of inputs for signatures (s)");

    require(checkSignatures(hash, v.length, v, r, s) >= requiredOperators, "not enough signatures to proceed");

    ERC721Mintable(tokenContract).transfer(recipient, value);

    LogWithdraw(transactionHash, tokenContract, recipient, value);
  }

  /**
   * @dev Transfers tokens to the new HomeGate contract
   * Can only be called by the current owner.
   */
  function transferTokens(address[] memory tokenContracts, address recipient) public onlyOwner {
    for (uint i = 0; i < tokenContracts.length; i++) {
      ERC721Mintable tokenContract = ERC721Mintable(tokenContracts[i]);
      tokenContract.transfer(recipient, tokenContract.balanceOf(address(this)));
    }
  }

  /**
   * @dev Transfers tokens of the token contract and HashStore to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function migrate(address[] memory tokenContracts, address newOwner) public onlyOwner {
    transferTokens(tokenContracts, newOwner);
    transferHashStoreOwnership(newOwner);
  }

  event LogWithdraw(bytes32 transactionHash, address tokenContract, address recipient, uint256 value);
}