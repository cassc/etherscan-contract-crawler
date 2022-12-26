//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

contract PhoenixFractionalERC1155 is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  ERC1155Upgradeable,
  DefaultOperatorFiltererUpgradeable,
  ERC2981Upgradeable,
  IERC721ReceiverUpgradeable
{
  string public constant VERSION = "1.1.0";
  uint256 public constant NUMBER_FRACTION = 10000;

  string public contractURI;
  address public tBotFCAddress;
  uint256 public phoenixTokenId;

  constructor() {
    initialize("", address(0), 1, "");
  }

  /// @dev initialize the contract
  function initialize(
    string memory contractURI_,
    address tBotFCAddress_,
    uint256 phoenixTokenId_,
    string memory uri_
  ) public initializer {
    __Ownable_init();
    __ERC1155_init(uri_);
    __DefaultOperatorFilterer_init();
    __ERC2981_init();

    contractURI = contractURI_;
    tBotFCAddress = tBotFCAddress_;
    phoenixTokenId = phoenixTokenId_;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /** @dev metadata */

  function setContractURI(string memory contractURI_) external onlyOwner {
    contractURI = contractURI_;
  }

  function setUri(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }

  /** @dev onERC721Received : 
    only receive phoenixTokenId from tBotFCAddress and fraction to 10000 ERC1155 token to old owner of phoenixTokenId
  */
  function onERC721Received(
    address,
    address from,
    uint256 tokenId,
    bytes memory
  ) public virtual override returns (bytes4) {
    require(msg.sender == tBotFCAddress && tokenId == phoenixTokenId, "only accept phoenix");

    // mint 10000 phoenixTokenId to old owner of phoenixTokenId
    _mint(from, tokenId, NUMBER_FRACTION, "");

    return this.onERC721Received.selector;
  }

  function redeem() external {
    // check if msg.sender own 10000 fraction of tokenId
    require(balanceOf(msg.sender, phoenixTokenId) == NUMBER_FRACTION, "you not own all fraction");

    // burn 10000 tokenId
    _burn(msg.sender, phoenixTokenId, NUMBER_FRACTION);

    // transfer tokenId to msg.sender
    IERC721(tBotFCAddress).safeTransferFrom(address(this), msg.sender, phoenixTokenId, "");
  }

  /** @dev for support interface */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev for operator filter registry
   */

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, id, amount, data);
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

  /**
    @dev setDefaultRoyalty
   */
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }
}