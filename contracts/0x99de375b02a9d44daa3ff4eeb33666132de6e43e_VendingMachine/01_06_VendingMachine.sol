// SPDX-License-Identifier: MIT

// m1nm1n & Co.
// https://m1nm1n.com/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IERC1155Minter.sol";

contract VendingMachine is Ownable, Pausable {
  using SafeMath for uint256;

  IERC1155Minter public token;
  address public manager;
  mapping(uint256 => bool) public mintables;
  mapping(uint256 => uint256) public prices;
  mapping(uint256 => uint256) public maxMintableAmounts;
  mapping(uint256 => uint256) public mintedAmounts;
  mapping(uint256 => address) public partners;
  mapping(uint256 => uint256) public shares;

  constructor(IERC1155Minter _token) {
    token = _token;
    manager = _msgSender();
  }

  modifier isMintable(uint256 _id) {
    require(mintables[_id], "not mintable");
    _;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setManager(address _manager) external onlyOwner {
    manager = _manager;
  }

  function setToken(IERC1155Minter _token) external onlyOwner {
    _setToken(_token);
  }

  function setMintable(uint256 _id, bool _mintable) external onlyOwner {
    _setMintable(_id, _mintable);
  }

  function setPrice(uint256 _id, uint256 _price) external onlyOwner {
    _setPrice(_id, _price);
  }

  function setMaxMintableAmount(uint256 _id, uint256 _maxMintableAmount) external onlyOwner {
    _setMaxMintableAmount(_id, _maxMintableAmount);
  }

  function setPartner(
    uint256 _id,
    address _partner,
    uint256 _share
  ) external onlyOwner {
    _setPartner(_id, _partner, _share);
  }

  function setConfig(
    uint256 _id,
    bool _mintable,
    uint256 _price,
    uint256 _maxMintableAmount,
    address _partner,
    uint256 _share
  ) external onlyOwner {
    _setMintable(_id, _mintable);
    _setPrice(_id, _price);
    _setMaxMintableAmount(_id, _maxMintableAmount);
    _setPartner(_id, _partner, _share);
  }

  function purchase(uint256 _id, uint256 _amount) external payable whenNotPaused isMintable(_id) {
    uint256 totalPrice = calculatePrice(_id, _amount);
    uint256 totalShare = calculateShare(_id, _amount);
    require(msg.value == totalPrice, "insufficient amount of eth");
    require(totalPrice > totalShare, "share must be less than price");

    uint256 managerShare = totalPrice.sub(totalShare);
    (bool successManager, ) = manager.call{value: managerShare}("");
    require(successManager, "failed to send to manager");

    if (totalShare > 0) {
      address partner = partners[_id];
      require(partner != address(0), "partner is not set");
      (bool successPartner, ) = partner.call{value: totalShare}("");
      require(successPartner, "failed to send to manager");
    }

    token.mint(_msgSender(), _id, _amount, new bytes(0));
    mintedAmounts[_id] = mintedAmounts[_id].add(_amount);

    if (maxMintableAmounts[_id] > 0) {
      require(maxMintableAmounts[_id] >= mintedAmounts[_id], "minted too much");
    }
  }

  function _setToken(IERC1155Minter _token) internal {
    token = _token;
  }

  function _setMintable(uint256 _id, bool _mintable) internal {
    mintables[_id] = _mintable;
  }

  function _setPrice(uint256 _id, uint256 _price) internal {
    require(_price > shares[_id], "share must be less than price");
    prices[_id] = _price;
  }

  function _setMaxMintableAmount(uint256 _id, uint256 _maxMintableAmount) internal {
    maxMintableAmounts[_id] = _maxMintableAmount;
  }

  function _setPartner(
    uint256 _id,
    address _partner,
    uint256 _share
  ) internal {
    require(prices[_id] > _share, "share must be less than price");
    partners[_id] = _partner;
    shares[_id] = _share;
  }

  function calculatePrice(uint256 _id, uint256 _amount) public view returns (uint256) {
    require(prices[_id] > 0, "price is not set");
    return prices[_id].mul(_amount);
  }

  function calculateShare(uint256 _id, uint256 _amount) public view returns (uint256) {
    return shares[_id].mul(_amount);
  }

  function getConfig(uint256 _id)
    public
    view
    returns (
      bool mintable,
      uint256 price,
      uint256 maxMintableAmount,
      uint256 mintedAmount,
      address partner,
      uint256 share
    )
  {
    mintable = mintables[_id];
    price = prices[_id];
    maxMintableAmount = maxMintableAmounts[_id];
    mintedAmount = mintedAmounts[_id];
    partner = partners[_id];
    share = shares[_id];
  }

  function emergencyWithdraw(address recipient) external onlyOwner {
    require(recipient != address(0), "recipient shouldn't be 0");

    (bool sent, ) = recipient.call{value: address(this).balance}("");
    require(sent, "failed to withdraw");
  }
}