// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./ERC721NTUpgradeable.sol";
import "@gnus.ai/contracts-upgradeable-diamond/security/PausableUpgradeable.sol";
import "@gnus.ai/contracts-upgradeable-diamond/access/AccessControlUpgradeable.sol";
import "@gnus.ai/contracts-upgradeable-diamond/proxy/utils/Initializable.sol";
import "@gnus.ai/contracts-upgradeable-diamond/proxy/utils/UUPSUpgradeable.sol";
import "@gnus.ai/contracts-upgradeable-diamond/utils/cryptography/ECDSAUpgradeable.sol";
import {InitializableStorage} from "@gnus.ai/contracts-upgradeable-diamond/proxy/utils/InitializableStorage.sol";
import {ERC721Storage} from "@gnus.ai/contracts-upgradeable-diamond/token/ERC721/ERC721Storage.sol";
import {OriginStorage} from "./OriginStorage.sol";

/// @custom:security-contact [email protected]
contract OriginBeta is
  Initializable,
  ERC721NTUpgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  UUPSUpgradeable
{
  using ECDSAUpgradeable for bytes32;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

  struct OriginApproval {
    bool admin;
    uint256 nonce;
    bytes signature;
    bytes rootSignature;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    InitializableStorage.layout()._initialized = true;
  }

  function initialize() public initializer {
    __ERC721_init("OriginBeta", "OGNB");
    __Pausable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(UPGRADER_ROLE, msg.sender);
    OriginStorage.layout().baseURI = "https://api.originsecured.com/origin/metadata/";
  }

  function _baseURI() internal view override(ERC721NTUpgradeable) returns (string memory) {
    return OriginStorage.layout().baseURI;
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
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
    require(
      OriginStorage.layout().usedNonces[approval.nonce] == false,
      "Origin: nonce already used"
    );
    require(
      digest.recover(approval.rootSignature) == OriginStorage.layout().root,
      "Origin: invalid root origin signature"
    );
    require(
      approval.admin || digest.recover(approval.signature) == OriginStorage.layout().keys[tokenId],
      "Origin: invalid origin signature"
    );
    OriginStorage.layout().usedNonces[approval.nonce] = true;
  }

  function mint(
    address to,
    address origin,
    uint256 tokenId,
    OriginApproval memory approval
  ) public whenNotPaused {
    bytes32 digest = keccak256(
      abi.encodePacked(this.mint.selector, to, origin, tokenId, approval.nonce)
    );

    OriginStorage.layout().keys[tokenId] = origin;
    _checkSignatures(tokenId, digest, approval);
    _safeMint(to, tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  // The following functions are overrides required by Solidity.

  function burn(uint256 tokenId, OriginApproval memory approval) public whenNotPaused {
    bytes32 digest = keccak256(abi.encodePacked(this.burn.selector, tokenId, approval.nonce));
    _checkSignatures(tokenId, digest, approval);
    if (bytes(OriginStorage.layout()._tokenURIs[tokenId]).length != 0) {
      delete OriginStorage.layout()._tokenURIs[tokenId];
    }
    super._burn(tokenId);
  }

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

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721NTUpgradeable)
    returns (string memory)
  {
    require(_exists(tokenId), "Origin: URI query for nonexistent token");
    string memory _tokenURI = OriginStorage.layout()._tokenURIs[tokenId];

    if (bytes(_tokenURI).length > 0) {
      return _tokenURI;
    }

    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721NTUpgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    // TODO: Origin interface
    // return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    return super.supportsInterface(interfaceId);
  }

  // ERC721Upgradeable overrider to block transfers
}