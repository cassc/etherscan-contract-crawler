// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

error NonContract();

enum Ownership {
  UNKNOWN,
  OWNED,
  UNOWNED
}

library EtchUtils {
  function verify(
    bytes32 messageHash,
    bytes memory signature,
    address signer
  ) internal pure returns (bool) {
    return
      signer ==
      ECDSAUpgradeable.recover(
        ECDSAUpgradeable.toEthSignedMessageHash(messageHash),
        signature
      );
  }

  function isOwned(
    address _contract,
    uint256 _id,
    address _sender
  ) internal view returns (Ownership) {
    if (!AddressUpgradeable.isContract(_contract)) revert NonContract();
    if (
      !IERC721Upgradeable(_contract).supportsInterface(0x80ac58cd) &&
      _contract != 0x9DFE69c0C52fa76d47Eef3f5aaE3e0Bcf73F7EE1
    ) {
      return Ownership.UNKNOWN;
    }
    bytes memory call;
    if (_contract == 0x9DFE69c0C52fa76d47Eef3f5aaE3e0Bcf73F7EE1) {
      call = abi.encodeWithSignature("punkIndexToAddress(uint256)", _id);
    } else {
      call = abi.encodeWithSignature("ownerOf(uint256)", _id);
    }
    (, bytes memory result) = address(_contract).staticcall(call);
    address nftOwner = abi.decode(result, (address));
    return nftOwner == _sender ? Ownership.OWNED : Ownership.UNOWNED;
  }
}