//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ISloth.sol";
import "./interfaces/ISlothItemV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SlothMintV4 is Ownable {
  address private _slothAddr;
  address private _slothItemAddr;
  address private _piementAddress;
  bool public publicSale;

  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable collectionSize;
  uint256 public immutable itemCollectionSize;
  uint256 public immutable clothesSize;
  uint256 public immutable itemSize;
  uint256 public currentItemCount;
  uint256 public currentClothesCount;

  uint256 private constant _MINT_WITH_CLOTHES_PRICE = 0.021 ether;
  address private _treasuryAddress = 0x452Ccc6d4a818D461e20837B417227aB70C72B56;

  constructor(uint256 newMaxPerAddressDuringMint, uint256 newCollectionSize, uint256 newItemCollectionSize, uint256 newClothesSize, uint256 newItemSize, uint256 newCurrentClothesCount, uint256 newCurrentItemCount) {
    maxPerAddressDuringMint = newMaxPerAddressDuringMint;
    collectionSize = newCollectionSize;
    itemCollectionSize = newItemCollectionSize;
    clothesSize = newClothesSize;
    itemSize = newItemSize;
    currentClothesCount = newCurrentClothesCount;
    currentItemCount = newCurrentItemCount;
  }

  function setSlothAddr(address newSlothAddr) external onlyOwner {
    _slothAddr = newSlothAddr;
  }
  function setSlothItemAddr(address newSlothItemAddr) external onlyOwner {
    _slothItemAddr = newSlothItemAddr;
  }
  function setPiementAddress(address newPiementAddress) external onlyOwner {
    _piementAddress = newPiementAddress;
  }

  function _itemMint(uint256 quantity, address to) private {
    require(currentItemCount + quantity <= itemSize, "exceeds item size");

    ISlothItemV2(_slothItemAddr).itemMint(to, quantity);
    currentItemCount += quantity;
  }

  function publicMintWithClothes(uint8 quantity) payable external {
    require(msg.value == _MINT_WITH_CLOTHES_PRICE * quantity, "wrong price");
    require(ISloth(_slothAddr).numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "wrong num");

    _publicMint(quantity, msg.sender);
  }

  function _publicMint(uint8 quantity, address to) private {
    require(publicSale, "inactive");
    require(ISloth(_slothAddr).totalSupply() + quantity <= collectionSize, "exceeds collection size");
    require(currentClothesCount + quantity <= clothesSize, "exceeds clothes size");

    ISloth(_slothAddr).mint(to, quantity);
    ISlothItemV2(_slothItemAddr).clothesMint(to, quantity);
    currentClothesCount += quantity;
  }

  function publicMintWithClothesAndItem(uint8 quantity, uint8 itemQuantity) payable external {
    require(msg.value == itemPrice(itemQuantity) + _MINT_WITH_CLOTHES_PRICE * quantity, "wrong price");
    require(ISlothItemV2(_slothItemAddr).totalSupply() + (quantity + itemQuantity) <= itemCollectionSize, "exceeds item collection size");
    require(ISloth(_slothAddr).numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "wrong num");
    require(ISlothItemV2(_slothItemAddr).getItemMintCount(msg.sender) + itemQuantity <= 99, "wrong item num");

    _publicMint(quantity, msg.sender);
    _itemMint(itemQuantity, msg.sender);
  }

  function publicItemMint(uint8 quantity) payable external {
    require(publicSale, "inactive");
    require(msg.value == itemPrice(quantity), "wrong price");
    require(ISlothItemV2(_slothItemAddr).totalSupply() + quantity <= itemCollectionSize, "exceeds item collection size");
    require(ISlothItemV2(_slothItemAddr).getItemMintCount(msg.sender) + quantity <= 99, "wrong item num");

    _itemMint(quantity, msg.sender);
  }

  function mintForPiement(address transferAddress, uint256 itemQuantity) payable public {
    uint8 quantity = 1;
    require(msg.value == itemPrice(itemQuantity) + _MINT_WITH_CLOTHES_PRICE * quantity, "wrong price");
    require(ISlothItemV2(_slothItemAddr).totalSupply() + (quantity + itemQuantity) <= itemCollectionSize, "exceeds item collection size");
    if (msg.sender == owner()) {
      _publicMint(quantity, transferAddress);
      _itemMint(itemQuantity, transferAddress);
      return;
    }
    require(msg.sender == _piementAddress, "worng address");

    _publicMint(quantity, transferAddress);
    _itemMint(itemQuantity, transferAddress);
  }
  function mintForPiementItem1(address transferAddress) payable public {
    mintForPiement(transferAddress, 1);
  }
  function mintForPiementItem3(address transferAddress) payable public {
    mintForPiement(transferAddress, 3);
  }
  function mintForPiementItem6(address transferAddress) payable public {
    mintForPiement(transferAddress, 6);
  }
  function mintForPiementItem9(address transferAddress) payable public {
    mintForPiement(transferAddress, 9);
  }

  function setPublicSale(bool newPublicSale) external onlyOwner {
    publicSale = newPublicSale;
  }

  function itemPrice(uint256 quantity) internal pure returns(uint256) {
    uint256 price = 0;
    if (quantity == 1) {
      price = 20;
    } else if (quantity == 2) {
      price = 39;
    } else if (quantity == 3) {
      price = 56;
    } else if (quantity == 4) {
      price = 72;
    } else if (quantity == 5) {
      price = 88;
    } else if (quantity == 6) {
      price = 100;
    } else if (quantity == 7) {
      price = 115 ;
    } else if (quantity == 8) {
      price = 125 ;
    } else if (quantity == 9) {
      price = 135;
    } else {
      price = 15 * quantity;
    }
    return price * 1 ether / 1000;
  }

  function withdraw() external onlyOwner {
    (bool sent,) = _treasuryAddress.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function ownerMint(uint8 quantity, uint256 itemQuantity) external onlyOwner {
    require(ISlothItemV2(_slothItemAddr).totalSupply() + (quantity + itemQuantity) <= itemCollectionSize, "exceeds item collection size");

    if (quantity > 0) {
      _publicMint(quantity, msg.sender);
    }
    if (itemQuantity > 0) {
      _itemMint(itemQuantity, msg.sender);
    }
  }
}