// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {
  ERC1155Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {
  ERC2981Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {
  AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {EIP712Whitelisting} from "./EIP712Whitelisting.sol";

contract MetaIluhaUpgradable is
  ERC1155Upgradeable,
  AccessControlUpgradeable,
  ERC2981Upgradeable,
  EIP712Whitelisting
{
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string private _name;
  string private _symbol;
  uint256 private _price;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  function initialize(
    string calldata name_,
    string calldata symbol_,
    string calldata domainVersion,
    uint256 price_,
    uint96 feeNumerator,
    address admin,
    address platform,
    address minter
  ) external initializer {
    __ERC1155_init("");
    __AccessControl_init();
    __ERC2981_init();
    __EIP712Whitelisting_init(platform, name_, domainVersion);

    _name = name_;
    _symbol = symbol_;
    _price = price_;

    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(MINTER_ROLE, minter);
    _setDefaultRoyalty(address(this), feeNumerator);
  }

  modifier payRequire(uint256 quantity) {
    if (!hasRole(MINTER_ROLE, _msgSender())) {
      require(msg.value >= _price * quantity, "Not enough money for mint!");
    }
    _;
  }

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function setMintPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _price = price;
  }

  function getMintPrice() external view returns (uint256) {
    return _price;
  }

  function mint(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _mint(msg.sender, _tokenIds.current(), amount, "");
    _tokenIds.increment();
  }

  function customMint(
    bytes calldata signature,
    uint256[] calldata amounts,
    string calldata newUri
  ) external payable requiresWhitelist(signature) payRequire(amounts.length) {
    for (uint256 i = 0; i < amounts.length; i++) {
      _mint(msg.sender, _tokenIds.current(), amounts[i], "");
      _tokenIds.increment();
    }
    _setURI(newUri);
  }

  function setURI(
    string calldata newUri
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setURI(newUri);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(os);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds.current();
  }

  function uri(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    return
      string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId)));
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    return
      ERC1155Upgradeable.supportsInterface(interfaceId) ||
      AccessControlUpgradeable.supportsInterface(interfaceId) ||
      ERC2981Upgradeable.supportsInterface(interfaceId);
  }
}