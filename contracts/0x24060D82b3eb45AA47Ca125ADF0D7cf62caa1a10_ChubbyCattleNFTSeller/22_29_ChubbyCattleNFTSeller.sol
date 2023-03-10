// SPDX-License-Identifier: Proprietary

pragma solidity ^0.8.13;

import "./Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ChubbyCattleNFT.sol";

contract ChubbyCattleNFTSeller is IERC721, AccessControl, Pausable, ReentrancyGuard, MathFunctions {

  using SafeMath for uint256;

  ChubbyCattleNFT internal chubbyCattle;
  AggregatorV3Interface internal priceFeed;
  address internal paymentAddress;

  constructor(
    address _chubbyCattleAddress,
    address _paymentAddress
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    chubbyCattle = ChubbyCattleNFT(_chubbyCattleAddress);
    paymentAddress = _paymentAddress;
  }
  
  function setChubbyCattleAddress(
    address _chubbyCattleAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    chubbyCattle = ChubbyCattleNFT(_chubbyCattleAddress);
  }

  function setPaymentAddress(
    address _paymentAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    paymentAddress = _paymentAddress;
  }

  function purchase(
    address _to,
    uint256 _tier,
    uint256 _quantity
  )
    external
    payable
    whenNotPaused
    nonReentrant
  {
    uint256 price = chubbyCattle.tierPriceInEth(_tier) * _quantity;

    if(msg.value < mulDiv(price, 100, 102)) {
      revert InsufficientFee();
    }

    (bool paid, ) = paymentAddress.call{ value: msg.value }("");

    if(!paid) {
      revert UnableCollectFee();
    }

    chubbyCattle.mintTo(_to, _tier, _quantity);
  }

  function balanceOf(address owner) external view returns (uint256 balance) {
    return chubbyCattle.balanceOf(owner);
  }

  function ownerOf(uint256 tokenId) external view returns (address owner) {
    return chubbyCattle.ownerOf(tokenId);
  }

  function tierPriceInEth(
    uint256 _tier
  )
    external
    view
    returns (uint256)
  {
    return chubbyCattle.tierPriceInEth(_tier);
  }

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes calldata data
  ) external {
    revert NotImplemented();
  }

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external {
    revert NotImplemented();
  }

  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external {
    revert NotImplemented();
  }

  function approve(address to, uint256 tokenId) external {
    revert NotImplemented();
  }

  function setApprovalForAll(address operator, bool _approved) external {
    revert NotImplemented();
  }

  function getApproved(uint256 tokenId) external view returns (address operator) {
    return chubbyCattle.getApproved(tokenId);
  }

  function isApprovedForAll(address owner, address operator) external view returns (bool) {
    return chubbyCattle.isApprovedForAll(owner, operator);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual 
    override(AccessControl, IERC165)
    returns (bool)
  {
    return AccessControl.supportsInterface(interfaceId)
        || interfaceId == type(IERC721).interfaceId 
        || interfaceId == type(IERC165).interfaceId;
  }

  error NotImplemented();
  error InsufficientFee();
  error UnableCollectFee();
}