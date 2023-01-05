// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/IERC721A.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";

import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/**
 * @title Mint Pass
 * @notice Mint pass contract. Mint passes can be redeemed by burning a certain
 * amount of KOOKS ERC721 tokens.
 */
contract MintPass is
  DefaultOperatorFiltererUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC1155Upgradeable,
  ERC1155SupplyUpgradeable,
  ERC1155BurnableUpgradeable
{
  address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  address public immutable KOOKS_CONTRACT;

  bool public redeemOpen;

  uint256 public priceInKOOKS;

  /**
   * @notice Sets the immutables variables
   * @dev Safe although contract is upgradeable, must be consistent through
   * upgrades
   * @param kooks The address of the KOOKS ERC721 contract
   * pass
   */
  constructor(address kooks) {
    KOOKS_CONTRACT = kooks;
  }

  /**
   * @notice Initializes the contract
   * @param uri_ The metadata URI of this ERC1155 contract
   */
  function initialize(string memory uri_, uint256 priceInKOOKS_) public initializer {
    __DefaultOperatorFilterer_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    __ERC1155_init(uri_);
    __ERC1155Supply_init();
    __ERC1155Burnable_init();
    redeemOpen = false;
    priceInKOOKS = priceInKOOKS_;
  }

  /**
   * @notice Opens/closes the redeem process. Does not affect airdrops.
   * @param open True to open, false to close. Caller must be owner.
   */
  function setRedeemState(bool open) external onlyOwner {
    redeemOpen = open;
  }

  /**
   * @notice Mints `amount` mint passes in exchange for the right amount of
   * KOOKS ERC721 tokens. This contract must be an approved operator for the
   * KOOKS tokens to exchange.
   * @dev KOOKS is not burnable, so this method transfers the 'burnt' KOOKS to
   * the 0x0000...dEaD address instead
   * @param amount The amount of mint passes to redeem
   * @param kooksIds The IDs of the KOOKS ERC721 tokens to exchange
   */
  function redeem(uint256 amount, uint256[] calldata kooksIds) external {
    require(redeemOpen, "redeem: closed");
    require(
      amount * priceInKOOKS == kooksIds.length && amount > 0,
      "redeem: too many/few KOOKS to burn"
    );

    for (uint256 i = 0; i < kooksIds.length; i++) {
      IERC721A(KOOKS_CONTRACT).transferFrom(
        _msgSender(),
        DEAD_ADDRESS,
        kooksIds[i]
      );
    }

    _mint(_msgSender(), 0, amount, "");
  }

  /**
   * @notice Airdrops `amount` mint passes with id `id` to `account`,
   * without burning any KOOKS ERC721 tokens. Not affected by pause.
   * Caller must be owner.
   * @param id The token ID to airdrop
   * @param amount The amount of mint passes to airdrop
   * @param account The account to airdrop the mint passes to
   */
  function airdrop(
    address account,
    uint256 id,
    uint256 amount
  ) external onlyOwner {
    _mint(account, id, amount, "");
  }

  /**
   * @notice Updates the metadata URI for this ERC1155 contract.
   * Caller must be owner.
   * @param uri_ The new metadata URI to store.
   */
  function setURI(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }

    /**
   * @notice Updates the price in KOOKS used during the redeem process.
   * Caller must be owner.
   * @param priceInKOOKS_ The new price in KOOKS.
   */
  function setPriceInKOOKS(uint256 priceInKOOKS_) external onlyOwner {
    priceInKOOKS = priceInKOOKS_;
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  /**
   * OPENSEA ROYALTIES ENFORCEMENT FILTERS
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}