//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Address.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract NGM_OTHER_SALE is ReentrancyGuard, Ownable {
  struct UserOrder {
    uint256[] orderIds;
  }
  mapping(address => UserOrder) private _userOrders;

  address nftContractAddress;

  // コントラクトの設定
  function setNftContractAddress(address _address) external onlyOwner {
    nftContractAddress = _address;
  }

  // オーダーの設定
  function setOrderIds(address _address, uint256[] memory _orderIds) external onlyOwner {
    _userOrders[_address].orderIds = _orderIds;
  }

  function getOrderIds(address _address) public view returns (uint256[] memory) {
    return _userOrders[_address].orderIds;
  }

  // NFTの購入
  function purchaseNFT() external payable {
    uint256[] memory orderIds = getOrderIds(msg.sender);
    require(orderIds.length > 0, "No reserved tokens");
    require(msg.value == (orderIds.length * 0.02 ether), "Invalid payment amount");
    for (uint256 i = 0; i < orderIds.length; ++i) {
        IERC721(nftContractAddress).safeTransferFrom(owner(), msg.sender, orderIds[i]);
    }

    uint256 balance = msg.value;
    Address.sendValue(payable(0xaC58E445594eC187eC8D82400d3457D9A67119cf), ((balance * 3600) / 10000)); // Founder
    Address.sendValue(payable(0x6cde76Ece170333e0b43C74325F178118af372f8), ((balance * 2800) / 10000)); // Musician
    Address.sendValue(payable(0x48A23fb6f56F9c14D29FA47A4f45b3a03167dDAe), ((balance * 2000) / 10000)); // Developer
    Address.sendValue(payable(0xf04a829373e3F3e4F755488e0deE511d1DD9bB98), ((balance * 1600) / 10000)); // Marketer

    _userOrders[msg.sender].orderIds = new uint256[](0);
  }
}