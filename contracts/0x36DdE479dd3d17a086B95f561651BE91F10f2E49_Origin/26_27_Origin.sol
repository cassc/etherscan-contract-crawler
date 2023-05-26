// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import {PausableUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/contracts/security/PausableUpgradeable.sol";
import {AccessControlUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/contracts/access/AccessControlUpgradeable.sol";
import {Initializable} from "@gnus.ai/contracts-upgradeable-diamond/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ECDSAUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/contracts/utils/cryptography/ECDSAUpgradeable.sol";
import {InitializableStorage} from "@gnus.ai/contracts-upgradeable-diamond/contracts/proxy/utils/InitializableStorage.sol";
import {ERC721Storage} from "@gnus.ai/contracts-upgradeable-diamond/contracts/token/ERC721/ERC721Storage.sol";
import "./ERC721NTUpgradeable.sol";
import {OriginStorage} from "./OriginStorage.sol";

struct OriginApproval {
  uint256 nonce;
  bytes signature;
  bytes rootSignature;
}

error InvalidTo();
error InvalidSignature();
error NonceUsed();
error RootNotSet();

/// @custom:security-contact [email protected]
contract Origin is
  Initializable,
  ERC721NTUpgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  UUPSUpgradeable
{
  using ECDSAUpgradeable for bytes32;

  function initialize(address _admin, address _root, string calldata _baseUri) public initializer {
    __ERC721_init("OriginSecured", "ORIGIN");
    __Pausable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    OriginStorage.layout().baseURI = _baseUri;
    OriginStorage.layout().root = _root;
  }

  function _baseURI() internal view override(ERC721NTUpgradeable) returns (string memory) {
    return OriginStorage.layout().baseURI;
  }

  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function setBaseURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    OriginStorage.layout().baseURI = newuri;
  }

  function setOriginRoot(address root) public onlyRole(DEFAULT_ADMIN_ROLE) {
    OriginStorage.layout().root = root;
  }

  function _checkSignatures(
    uint256 tokenId,
    bytes32 digest,
    OriginApproval memory approval
  ) private {
    if (OriginStorage.layout().usedNonces[approval.nonce] == true) revert NonceUsed();
    if (OriginStorage.layout().root == address(0)) revert RootNotSet();

    if (digest.recover(approval.rootSignature) != OriginStorage.layout().root)
      revert InvalidSignature();

    // if (digest.recover(approval.signature) != OriginStorage.layout().tokenIds[tokenId])
    //   revert InvalidSignature();

    OriginStorage.layout().usedNonces[approval.nonce] = true;
  }

  function mint(address to, uint256 tokenId, OriginApproval memory approval) public whenNotPaused {
    bytes32 digest = keccak256(abi.encodePacked(this.mint.selector, to, tokenId, approval.nonce));

    if (msg.sender != to) revert InvalidTo();

    OriginStorage.layout().tokenIds[tokenId] = to;

    _checkSignatures(tokenId, digest, approval);
    _safeMint(to, tokenId);
  }

  /// @dev TODO: Admin Mint function

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

  // The following functions are overrides required by Solidity.

  function burn(uint256 tokenId, OriginApproval memory approval) public whenNotPaused {
    bytes32 digest = keccak256(abi.encodePacked(this.burn.selector, tokenId, approval.nonce));
    _checkSignatures(tokenId, digest, approval);
    if (bytes(OriginStorage.layout()._tokenURIs[tokenId]).length != 0) {
      delete OriginStorage.layout()._tokenURIs[tokenId];
    }
    super._burn(tokenId);
  }

  /// @dev TODO: Admin Burn function

  function migrate(
    address to,
    uint256 tokenId,
    OriginApproval memory approval
  ) public whenNotPaused {
    bytes32 digest = keccak256(
      abi.encodePacked(this.migrate.selector, to, tokenId, approval.nonce)
    );
    _checkSignatures(tokenId, digest, approval);
    super._transfer(ERC721Storage.layout()._owners[tokenId], to, tokenId);
  }

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721NTUpgradeable) returns (string memory) {
    require(_exists(tokenId), "Origin: URI query for nonexistent token");
    string memory _tokenURI = OriginStorage.layout()._tokenURIs[tokenId];

    if (bytes(_tokenURI).length > 0) {
      return _tokenURI;
    }

    return super.tokenURI(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721NTUpgradeable, AccessControlUpgradeable) returns (bool) {
    // TODO: Origin interface
    // return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    return super.supportsInterface(interfaceId);
  }

  // ERC721Upgradeable overrider to block transfers
}