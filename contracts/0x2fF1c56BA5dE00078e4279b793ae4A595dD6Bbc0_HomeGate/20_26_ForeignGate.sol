//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './OperatorHub.sol';
import './ERC721Mintable.sol';

contract ForeignGate is OperatorHub {
  uint64 constant PREFIX = 0x9da38c22b41d70ee; // random number

  constructor(HashStore _hashStore, uint8 requiredOperators_, address[] memory initialOperators)
    OperatorHub(_hashStore, requiredOperators_, initialOperators) {
  }

  function canMint(
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

  function mint(
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

    ERC721Mintable(tokenContract).mint(recipient, value);

    emit LogMint(transactionHash, tokenContract, recipient, value);
  }

  /**
   * @dev Transfers ownership of the token contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferTokenOwnership(address[] memory tokenContracts, address newOwner) public onlyOwner {
    for (uint i = 0; i < tokenContracts.length; i++) {
      Ownable tokenContract = Ownable(tokenContracts[i]);
      tokenContract.transferOwnership(newOwner);
    }
  }

  /**
   * @dev Transfers ownership of the token contract and HashStore to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function migrate(address[] memory tokenContracts, address newOwner) public onlyOwner {
    transferTokenOwnership(tokenContracts, newOwner);
    transferHashStoreOwnership(newOwner);
  }

  event LogMint(bytes32 transactionHash, address tokenContract, address recipient, uint256 value);
}