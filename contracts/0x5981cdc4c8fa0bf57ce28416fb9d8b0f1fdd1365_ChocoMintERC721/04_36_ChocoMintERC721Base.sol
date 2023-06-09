// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../interfaces/IChocoMintERC721.sol";

import "../utils/AdminController.sol";
import "../utils/DefaultApproval.sol";
import "../utils/FreezableProvenance.sol";
import "../utils/FreezableRoot.sol";
import "../utils/FreezableTokenURI.sol";
import "../utils/FreezableRoyalty.sol";
import "../utils/TotalSupply.sol";
import "../utils/TxValidatable.sol";

abstract contract ChocoMintERC721Base is
  Initializable,
  ContextUpgradeable,
  EIP712Upgradeable,
  ERC2771ContextUpgradeable,
  ERC721Upgradeable,
  ERC721BurnableUpgradeable,
  AdminController,
  DefaultApproval,
  FreezableProvenance,
  FreezableRoot,
  FreezableTokenURI,
  FreezableRoyalty,
  TotalSupply,
  TxValidatable
{
  function freezeProvenance() external onlyAdminOrOwner {
    _freezeProvenance();
  }

  function setProvenance(string memory _provenance, bool freezing) external onlyAdminOrOwner {
    _setProvenance(_provenance, freezing);
  }

  function freezeRoot() external onlyAdminOrOwner {
    _freezeRoot();
  }

  function setRoot(bytes32 _root, bool freezing) external onlyAdminOrOwner {
    _setRoot(_root, freezing);
  }

  function freezeTokenURI() external onlyAdminOrOwner {
    _freezeAllTokenStaticURI();
    _freezeTokenURIBase();
  }

  function freezeAllTokenStaticURI() external onlyAdminOrOwner {
    _freezeAllTokenStaticURI();
  }

  function freezeTokenStaticURI(uint256 tokenId) external onlyAdminOrOwner {
    _freezeTokenStaticURI(tokenId);
  }

  function freezeTokenURIBase() external onlyAdminOrOwner {
    _freezeTokenURIBase();
  }

  function setTokenStaticURI(
    uint256 tokenId,
    string memory tokenStaticURI,
    bool freezing
  ) external onlyAdminOrOwner {
    _setTokenStaticURI(tokenId, tokenStaticURI, freezing);
  }

  function setTokenURIBase(string memory tokenURIBase, bool freezing) external onlyAdminOrOwner {
    _setTokenURIBase(tokenURIBase, freezing);
  }

  function freezeRoyalty() external onlyAdminOrOwner {
    _freezeAllTokenRoyalty();
    _freezeDefaultRoyalty();
  }

  function freezeAllTokenRoyalty() external onlyAdminOrOwner {
    _freezeAllTokenRoyalty();
  }

  function freezeDefaultRoyalty() external onlyAdminOrOwner {
    _freezeDefaultRoyalty();
  }

  function freezeTokenRoyalty(uint256 tokenId) external onlyAdminOrOwner {
    _freezeTokenRoyalty(tokenId);
  }

  function setTokenRoyalty(
    uint256 tokenId,
    RoyaltyLib.RoyaltyData memory royaltyData,
    bool freezing
  ) external onlyAdminOrOwner {
    _setTokenRoyalty(tokenId, royaltyData, freezing);
  }

  function setDefaultRoyalty(RoyaltyLib.RoyaltyData memory royaltyData, bool freezing) external onlyAdminOrOwner {
    _setDefaultRoyalty(royaltyData, freezing);
  }

  function initialize(
    string memory name,
    string memory version,
    string memory symbol,
    address trustedForwarder,
    address[] memory defaultApprovals
  ) public initializer {
    __Ownable_init_unchained();
    __EIP712_init_unchained(name, version);
    __ERC721_init_unchained(name, symbol);
    __ERC2771Context_init_unchained(trustedForwarder);
    for (uint256 i = 0; i < defaultApprovals.length; i++) {
      _setDefaultApproval(defaultApprovals[i], true);
    }
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, FreezableRoyalty)
    returns (bool)
  {
    return interfaceId == type(IChocoMintERC721).interfaceId || super.supportsInterface(interfaceId);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override(ERC721Upgradeable, DefaultApproval)
    returns (bool)
  {
    return super.isApprovedForAll(owner, operator);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, FreezableTokenURI)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function _mint(address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, TotalSupply) {
    super._mint(to, tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721Upgradeable, FreezableRoyalty, FreezableTokenURI, TotalSupply)
  {
    super._burn(tokenId);
  }

  function _msgSender() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address) {
    return super._msgSender();
  }

  function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes memory) {
    return super._msgData();
  }

  function _baseURI() internal view virtual override(ERC721Upgradeable, FreezableTokenURI) returns (string memory) {
    return super._baseURI();
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    override(ERC721Upgradeable, DefaultApproval)
    returns (bool)
  {
    return super._isApprovedOrOwner(spender, tokenId);
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}