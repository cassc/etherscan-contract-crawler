// SPDX-License-Identifier: MIT
/// @author @m4ta2bi

pragma solidity ^0.8.18;

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GachaSalesExtension is Ownable {
  using Strings for uint256;

  IERC721CreatorCore public token;

  uint256 public price;

  uint256 public startTimestamp;

  uint256 public endTimestamp;

  uint256 public mintedCount;

  uint256 public kinds;

  mapping(uint256 => uint256) public subKinds;

  bool public salesIsActive;

  constructor(uint256 _price, uint256 _startTimestamp, uint256 _endTimestamp, uint256 _kinds) {
    price = _price;
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    kinds = _kinds;
  }

  modifier whenSaleIsActive() {
    require(salesIsActive, "Sale is closed");
    if (startTimestamp != 0) {
      require(startTimestamp <= block.timestamp, "Sale has not started yet");
    }
    if (endTimestamp != 0) {
      require(block.timestamp < endTimestamp, "Sale is over");
    }
    _;
  }

  function setTokenAndStartSale(IERC721CreatorCore _token, string calldata tokenURIPrefix) external onlyOwner {
    token = _token;
    token.setTokenURIPrefixExtension(tokenURIPrefix);
    salesIsActive = true;
  }

  function setTokenURIPrefix(string calldata tokenURIPrefix) external onlyOwner {
    token.setTokenURIPrefixExtension(tokenURIPrefix);
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
    startTimestamp = _startTimestamp;
  }

  function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
    endTimestamp = _endTimestamp;
  }

  function setKinds(uint256 _kinds) external onlyOwner {
    kinds = _kinds;
  }

  function setSubkind(uint256 kind, uint256 subKind) external onlyOwner {
    subKinds[kind] = subKind;
  }

  function setSalesIsActive(bool _salesIsActive) external onlyOwner {
    salesIsActive = _salesIsActive;
  }

  function mintRandom(address to, uint256 amount) external payable whenSaleIsActive {
    require(msg.value >= amount * price, "Insufficient amount of eth");

    uint256 salt = uint256(keccak256(abi.encodePacked(to, mintedCount)));
    for (uint256 i = 0; i < amount; i++) {
      salt = _mintRandom(to, salt);
    }
  }

  function mintFixed(address to, uint256 kind, uint256 subKind) external onlyOwner {
    _mintToken(to, kind, subKind);
  }

  function _mintRandom(address to, uint256 salt) internal returns (uint256) {
    uint256 r = _random(salt);
    uint256 kind = (r % kinds) + 1;
    if (subKinds[kind] == 0) {
      _mintToken(to, kind, 0);
    } else {
      uint256 r2 = _random(r);
      uint256 subKind = (r2 % subKinds[kind]) + 1;
      _mintToken(to, kind, subKind);
    }
    return r;
  }

  function _mintToken(address to, uint256 kind, uint256 subKind) internal {
    string memory suffix = _tokenURISuffix(kind, subKind);
    unchecked {
      mintedCount++;
    }
    token.mintExtension(to, suffix);
  }

  function _random(uint256 salt) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, salt)));
  }

  function _tokenURISuffix(uint256 kind, uint256 subKind) internal pure returns (string memory) {
    if (subKind == 0) {
      return kind.toString();
    } else {
      return string(abi.encodePacked(kind.toString(), "_", subKind.toString()));
    }
  }

  function withdraw(address recipient) external onlyOwner {
    require(recipient != address(0), "Recipient address is not set");

    (bool success, ) = recipient.call{value: address(this).balance}("");
    require(success, "Failed to send");
  }
}