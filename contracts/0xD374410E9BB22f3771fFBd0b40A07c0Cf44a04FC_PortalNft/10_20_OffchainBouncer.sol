// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
* @title Offchain whitelist module using vouchers
* @author NFTNick.eth
*/

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract OffchainBouncer is AccessControl, Ownable, EIP712 {
  bytes32 public constant BOUNCER_ROLE = keccak256("BOUNCER_ROLE");

  struct NFTVoucher {
    address minter;
    uint mintLimit;
    uint256 start;
    bytes signature;
  }

  /// @notice Used to define who's capable of generating the whitelist. 
  function addBouncer(address bouncer_) external onlyOwner {
    _setupRole(BOUNCER_ROLE, payable(bouncer_));
  }

  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(address minter,uint mintLimit,uint256 start)"),
        voucher.minter,
        voucher.mintLimit,
        voucher.start
      )
    ));
  }

  /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
  /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  /// @param voucher An NFTVoucher describing an unminted NFT.
  function _verify(NFTVoucher calldata voucher) internal view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  /// @notice Used for signing the voucher being generated
  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }
}