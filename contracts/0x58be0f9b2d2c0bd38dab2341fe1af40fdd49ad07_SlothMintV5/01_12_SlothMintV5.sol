//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ISloth.sol";
import "./interfaces/ISlothItemV2.sol";
import "./interfaces/ISpecialSlothItem.sol";
import "./interfaces/ISlothMint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SlothMintV5 is Ownable, ISlothMint {
  address private _slothAddr;
  address private _slothItemAddr;
  address private _specialSlothItemAddr;
  address private _piementAddress;
  bool public publicSale;
  bool public forSalePoepelle;

  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable collectionSize;
  uint256 public immutable itemCollectionSize;
  uint256 public immutable clothesSize;
  uint256 public immutable itemSize;
  uint256 public immutable poupelleItemSize;
  uint256 public currentItemCount;
  uint256 public currentClothesCount;
  uint256 public currentPoupelleItemCount;

  uint256 private constant _MINT_WITH_CLOTHES_PRICE = 0.021 ether;
  uint256 private constant _MINT_WITH_POUPELLE_PRICE = 0.03 ether;
  address private _treasuryAddress = 0x452Ccc6d4a818D461e20837B417227aB70C72B56;

  constructor(uint256 newMaxPerAddressDuringMint, uint256 newCollectionSize, uint256 newItemCollectionSize, uint256 newClothesSize, uint256 newItemSize, uint256 newPoupelleItemSize,uint256 newCurrentClothesCount, uint256 newCurrentItemCount, uint256 newCurrentPoupelleItemCount) {
    maxPerAddressDuringMint = newMaxPerAddressDuringMint;
    collectionSize = newCollectionSize;
    itemCollectionSize = newItemCollectionSize;
    clothesSize = newClothesSize;
    itemSize = newItemSize;
    poupelleItemSize = newPoupelleItemSize;
    currentClothesCount = newCurrentClothesCount;
    currentItemCount = newCurrentItemCount;
    currentPoupelleItemCount = newCurrentPoupelleItemCount;
  }

  function setSlothAddr(address newSlothAddr) external onlyOwner {
    _slothAddr = newSlothAddr;
  }
  function setSlothItemAddr(address newSlothItemAddr) external onlyOwner {
    _slothItemAddr = newSlothItemAddr;
  }
  function setSpecialSlothItemAddr(address newSpecialSlothItemAddr) external onlyOwner {
    _specialSlothItemAddr = newSpecialSlothItemAddr;
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
    emit mintWithCloth(quantity);
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
    emit mintWithClothAndItem(quantity, itemQuantity, false);
  }

  function publicItemMint(uint8 quantity) payable external {
    require(publicSale, "inactive");
    require(msg.value == itemPrice(quantity), "wrong price");
    require(ISlothItemV2(_slothItemAddr).totalSupply() + quantity <= itemCollectionSize, "exceeds item collection size");
    require(ISlothItemV2(_slothItemAddr).getItemMintCount(msg.sender) + quantity <= 99, "wrong item num");

    _itemMint(quantity, msg.sender);
    emit mintItem(quantity);
  }

  function publicMintWithClothesAndPoupelle(uint8 quantity) payable external {
    require(forSalePoepelle, "inactive");
    require(ISlothItemV2(_slothItemAddr).totalSupply() + quantity <= itemCollectionSize, "exceeds item collection size");
    require(currentClothesCount + quantity <= clothesSize, "exceeds clothes size");
    require(currentPoupelleItemCount + quantity <= poupelleItemSize, "exceeds poupelle item size");
    require(msg.value ==  _MINT_WITH_POUPELLE_PRICE * quantity, "wrong price");
    _publicMint(quantity, msg.sender);
    ISpecialSlothItem(_specialSlothItemAddr).mintPoupelle(msg.sender, quantity);
    currentPoupelleItemCount += quantity;
    emit mintWithClothAndPoupelle(quantity, false);
  }

  function pulicMintOnlyPoupelle(uint8 quantity) payable external {
    require(forSalePoepelle, "inactive");
    require(currentPoupelleItemCount + quantity <= poupelleItemSize, "exceeds poupelle item size");
    require(msg.value ==  0.01 ether * quantity, "wrong price");
    require(ISloth(_slothAddr).balanceOf(msg.sender) > 0, "need sloth");
    ISpecialSlothItem(_specialSlothItemAddr).mintPoupelle(msg.sender, quantity);
    currentPoupelleItemCount += quantity;
    emit mintPoupelle(quantity);
  }

  function publicMintWithClothesAndPoupelleForPiement(address transferAddress) payable external {
    require(forSalePoepelle, "inactive");
    require(ISlothItemV2(_slothItemAddr).totalSupply() + 1 <= itemCollectionSize, "exceeds item collection size");
    require(currentClothesCount + 1 <= clothesSize, "exceeds clothes size");
    require(currentPoupelleItemCount + 1 <= poupelleItemSize, "exceeds poupelle item size");
    require(msg.value ==  0.03 ether, "wrong price");
    if (msg.sender == owner()) {
      _publicMint(1, transferAddress);
      ISpecialSlothItem(_specialSlothItemAddr).mintPoupelle(transferAddress, 1);
      currentPoupelleItemCount += 1;
      return;
    }
    require(msg.sender == _piementAddress, "worng address");
    _publicMint(1, transferAddress);
    ISpecialSlothItem(_specialSlothItemAddr).mintPoupelle(transferAddress, 1);
    currentPoupelleItemCount += 1;
    emit mintWithClothAndPoupelle(1, true);
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
    emit mintWithClothAndItem(1, 1, true);
  }
  function mintForPiementItem3(address transferAddress) payable public {
    mintForPiement(transferAddress, 3);
    emit mintWithClothAndItem(1, 3, true);
  }
  function mintForPiementItem6(address transferAddress) payable public {
    mintForPiement(transferAddress, 6);
    emit mintWithClothAndItem(1, 6, true);
  }
  function mintForPiementItem9(address transferAddress) payable public {
    mintForPiement(transferAddress, 9);
    emit mintWithClothAndItem(1, 9, true);
  }

  function setPublicSale(bool newPublicSale) external onlyOwner {
    publicSale = newPublicSale;
  }
  function setForSalePoepelle(bool newForSalePoepelle) external onlyOwner {
    forSalePoepelle = newForSalePoepelle;
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