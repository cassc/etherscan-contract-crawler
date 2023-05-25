// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract GiftNFT is ERC1155, AccessControl, ERC2981 {
  event BaseURIChanged(string previousURI, string newURI);
  event RoyaltyFeeChanged(uint256 previousFee, uint256 newFee);
  event NftMinted(uint256 ID, string tokenURI, address owner);

  string private _name;
  string private _symbol;

  uint256 _quantity;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory uri_,
    uint256 quantity,
    address admin
  ) ERC1155(uri_) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);

    _name = name_;
    _symbol = symbol_;
    _quantity = quantity;

    _mint(admin, 0, quantity, "");
    emit NftMinted(0, uri_, admin);
  }

  function setBaseTokenURI(
    string calldata newUri
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    string memory oldUri = super.uri(0);

    _setURI(newUri);
    emit BaseURIChanged(oldUri, newUri);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return uri(tokenId);
  }

  function setRoyalties(
    address recipient,
    uint96 royaltyFee
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDefaultRoyalty(recipient, royaltyFee);

    emit RoyaltyFeeChanged(royaltyFee, royaltyFee);
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function totalSupply() external view returns (uint256) {
    return _quantity;
  }

  function uri(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    return
      string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId)));
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC1155, AccessControl, ERC2981) returns (bool) {
    return
      ERC1155.supportsInterface(interfaceId) ||
      AccessControl.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}