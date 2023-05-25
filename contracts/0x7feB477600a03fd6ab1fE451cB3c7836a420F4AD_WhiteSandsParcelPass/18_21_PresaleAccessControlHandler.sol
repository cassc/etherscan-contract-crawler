// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./DeveloperAccessControl.sol";
import "./IPresaleAccessControlHandler.sol";
import "./Sales.sol";

/**
 * @title White Sands - Presale Mint Access Control Handler
 *
 * @notice This is a decoupled contract responsible for handling access control for presale minting. The main contract,
 * which will be running a presale mint, would defer to this contract to determine if the calling wallet is able to
 * participate in the presale and if they can mint the requested number of tokens.
 *
 * This contract is decoupled so that it can be replaced in the future for further presale events.
 */
contract PresaleAccessControlHandler is IPresaleAccessControlHandler, DeveloperAccessControl, Pausable, ERC165 {
  using ERC165Checker for address;

  address public trustedSigner;

  /// Defines the different phases of the sale.
  ///
  /// 1 token limit in phase 1 (priority presale)
  /// 2 token limit in phase 2 (reserve + priority presale)
  enum SalePhase {
    kNone,
    kPriorityPresale,
    kReservePresale,
    kPublicSale
  }

  constructor(address owner, address _trustedSigner) DeveloperAccessControl(owner) {
    trustedSigner = _trustedSigner;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IPresaleAccessControlHandler).interfaceId || super.supportsInterface(interfaceId);
  }

  function pause() external onlyUnlocked {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /// Minting method for people on the access list that can mint before the public sale.
  ///
  /// The combination of the nonce and senders address is signed by the trusted signer wallet.
  function verifyCanMintPresaleTokens(
    address minter,
    uint32 balance,
    uint64 presaleStart,
    uint64 /*_unused*/,
    uint32 count,
    uint256 nonce,
    bytes calldata signature
  ) external view virtual override returns (bool, bytes memory) {
    if (count != 1 || balance >= 1) {
      return (false, "wallet exceeded presale limit");
    }

    uint64 timestamp = uint64(block.timestamp);
    uint64 priorityStart = presaleStart;
    uint64 reserveStart = priorityStart + 6 hours;
    uint64 publicStart = priorityStart + 24 hours;
    uint8 flags = uint8(nonce & 0xff);

    SalePhase phase;
    if (timestamp < priorityStart) {
      return (false, "Presale has not started");
    } else if (timestamp >= priorityStart && timestamp < reserveStart) {
      phase = SalePhase.kPriorityPresale;
    } else if (timestamp >= reserveStart && timestamp < publicStart) {
      phase = SalePhase.kReservePresale;
    } else {
      return (false, "Presale has finished");
    }

    if (flags < 1 || flags > 2) {
      return (false, "Invalid presale access modifier");
    }

    if (flags > uint8(phase)) {
      return (false, "No access to current presale phase");
    }

    address signer = recoverSignerAddress(nonce, minter, signature);
    if (signer != trustedSigner) {
      return (false, "could not verify minting wallet");
    }

    return (true, bytes(""));
  }

  function recoverSignerAddress(
    uint256 nonce,
    address sender,
    bytes calldata signature
  ) internal pure returns (address) {
    bytes32 message = keccak256(abi.encode(nonce, sender));

    bytes32 digest = ECDSA.toEthSignedMessageHash(message);
    return ECDSA.recover(digest, signature);
  }

  function setTrustedSigner(address signer) external onlyUnlocked {
    trustedSigner = signer;
  }

  function getTrustedSigner() external view returns (address) {
    return trustedSigner;
  }
}