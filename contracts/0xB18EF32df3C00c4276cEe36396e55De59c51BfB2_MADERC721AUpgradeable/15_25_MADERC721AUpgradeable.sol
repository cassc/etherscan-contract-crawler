// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./SLERC721AUpgradeable.sol";
import "./extensions/StreetlabERC721ABurnable.sol";
import "./extensions/StreetlabERC721AStakeable.sol";

/// @title SLERC721AUpgradeable
/// @author Julien Bessaguet
/// @notice NFT contract for Nifty Jutsu
contract MADERC721AUpgradeable is
  SLERC721AUpgradeable,
  StreetlabERC721ABurnable
{
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
      _disableInitializers();
  }

  function initialize(
    string memory name_,
    string memory symbol_
  ) public initializerERC721A initializer {
    __SLERC721AUpgradeable_init(name_, symbol_);
  }

  /// @inheritdoc ERC721AUpgradeable
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @inheritdoc ERC721AUpgradeable
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @inheritdoc ERC721AUpgradeable
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override(ERC721AUpgradeable, SLERC721AUpgradeable) {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  /// @inheritdoc ERC721AUpgradeable
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721AUpgradeable, SLERC721AUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721AUpgradeable, SLERC721AUpgradeable) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override(ERC721AUpgradeable, SLERC721AUpgradeable) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721AUpgradeable, SLERC721AUpgradeable) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721AUpgradeable, SLERC721AUpgradeable) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721AUpgradeable, SLERC721AUpgradeable) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}