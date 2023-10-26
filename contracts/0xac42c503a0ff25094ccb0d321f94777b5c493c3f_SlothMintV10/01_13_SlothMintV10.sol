// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ISloth.sol";
import "./interfaces/ISlothItemV2.sol";
import "./interfaces/ISpecialSlothItemV2.sol";
import "./interfaces/ISlothMintV2.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SlothMintV10 is Initializable, OwnableUpgradeable, ISlothMintV2 {
    address private _slothAddr;
    address private _slothItemAddr;
    address private _specialSlothItemAddr;
    address private _piementAddress;
    bool public publicSale;
    mapping(uint256 => bool) public forSaleCollabo;
    mapping(uint256 => uint256) public collaboSaleEndTimes;
    mapping(uint256 => uint256) public collaboSalePricePatterns;
    uint256 public collectionSize;
    uint256 public itemCollectionSize;
    uint256 public clothesSize;
    uint256 public itemSize;
    uint256 public currentItemCount;
    uint256 public currentClothesCount;
    mapping(uint256 => uint256) public collaboItemSizes;
    mapping(uint256 => uint256) public currentCollaboItemCounts;

    address private _treasuryAddress;
    uint256 private _MINT_WITH_CLOTHES_PRICE;
    uint256 private _MINT_WITH_COLLABO_PRICE;
    uint256 private _MINT_WITH_COLLABO_PRICE2;
    uint256 private _MINT_COLLABO_PRICE;
    uint256 private _MINT_COLLABO_PRICE2;
    address private _lightSlothAddr;
    uint256 private _MINT_SLOTH_COLLECTION_PRICE;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 newCollectionSize, uint256 newItemCollectionSize, uint256 newClothesSize, uint256 newItemSize, uint256 newCurrentClothesCount, uint256 newCurrentItemCount) initializer public {
        __Ownable_init();
        collectionSize = newCollectionSize;
        itemCollectionSize = newItemCollectionSize;
        clothesSize = newClothesSize;
        itemSize = newItemSize;
        currentClothesCount = newCurrentClothesCount;
        currentItemCount = newCurrentItemCount;

        _treasuryAddress = payable(0x452Ccc6d4a818D461e20837B417227aB70C72B56);
        _MINT_WITH_CLOTHES_PRICE = 0.021 ether;
        _MINT_WITH_COLLABO_PRICE = 0.03 ether;
        _MINT_WITH_COLLABO_PRICE2 = 0.04 ether;
        _MINT_COLLABO_PRICE = 0.01 ether;
        _MINT_COLLABO_PRICE2 = 0.02 ether;
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
    function setLightSlothAddr(address newLightSlothAddr) external onlyOwner {
        _lightSlothAddr = newLightSlothAddr;
    }
    function setSlothCollectionPrice(uint256 newPrice) external onlyOwner {
        _MINT_SLOTH_COLLECTION_PRICE = newPrice;
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

    function _itemMint(uint256 quantity, address to) private {
        require(currentItemCount + quantity <= itemSize, "exceeds item size");

        ISlothItemV2(_slothItemAddr).itemMint(to, quantity);
        currentItemCount += quantity;
    }

    function publicMintWithClothes(uint8 quantity) payable external {
        require(msg.value == _MINT_WITH_CLOTHES_PRICE * quantity, "wrong price");

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

        _publicMint(quantity, msg.sender);
        _itemMint(itemQuantity, msg.sender);
        emit mintWithClothAndItem(quantity, itemQuantity, false);
    }

    function publicItemMint(uint8 quantity) payable external {
        require(publicSale, "inactive");
        require(msg.value == itemPrice(quantity), "wrong price");
        require(ISlothItemV2(_slothItemAddr).totalSupply() + quantity <= itemCollectionSize, "exceeds item collection size");

        _itemMint(quantity, msg.sender);
        emit mintItem(quantity);
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

    function _isSaleEnded(uint256 specialType) internal view returns (bool) {
        if (collaboSaleEndTimes[specialType] == 0) {
          return false;
        }
        return block.timestamp >= collaboSaleEndTimes[specialType];
    }

    function checkAllowCollaboMint(uint8 quantity, uint256 specialType) internal view {
        require(forSaleCollabo[specialType], "inactive collabo");
        require(!_isSaleEnded(specialType), "ended");
        require(currentCollaboItemCounts[specialType] + quantity <= collaboItemSizes[specialType], "collabo sold out");
    }

    function checkHaveBody(address wallet) internal view returns (bool) {
        return ISloth(_slothAddr).balanceOf(wallet) > 0 || ISloth(_lightSlothAddr).balanceOf(wallet) > 0;
    }

    function collaboMintValue(uint8 quantity, uint256 specialType) internal view returns (uint256) {
        if (collaboSalePricePatterns[specialType] == 1) {
          return _MINT_COLLABO_PRICE2 * quantity;
        }
        return _MINT_COLLABO_PRICE * quantity;
    }

    function withCollaboMintValue(uint8 quantity, uint256 specialType) internal view returns (uint256) {
        if (collaboSalePricePatterns[specialType] == 1) {
          return _MINT_WITH_COLLABO_PRICE2 * quantity;
        }
        return _MINT_WITH_COLLABO_PRICE * quantity;
    }

    function mintCollaboWithBody(uint8 quantity, uint256 specialType) internal {
        checkAllowCollaboMint(quantity, specialType);
        require(ISlothItemV2(_slothItemAddr).totalSupply() + quantity <= itemCollectionSize, "exceeds item collection size");
        require(msg.value ==  withCollaboMintValue(quantity, specialType), "wrong price");

        _publicMint(quantity, msg.sender);
        ISpecialSlothItemV2(_specialSlothItemAddr).mintCollaboCloth(msg.sender, quantity, specialType);
        currentCollaboItemCounts[specialType] += quantity;
    }

    function mintCollaboCloth(uint8 quantity, uint256 specialType) internal {
        checkAllowCollaboMint(quantity, specialType);
        require(msg.value ==  collaboMintValue(quantity, specialType), "wrong price");
        require(checkHaveBody(msg.sender), "need sloth");
        ISpecialSlothItemV2(_specialSlothItemAddr).mintCollaboCloth(msg.sender, quantity, specialType);
        currentCollaboItemCounts[specialType] += quantity;
    }

    function publicMintWithClothesAndCollaboForPiement(address transferAddress, uint256 specialType) payable external {
        checkAllowCollaboMint(1, specialType);
        require(ISlothItemV2(_slothItemAddr).totalSupply() + 1 <= itemCollectionSize, "exceeds item collection size");
        require(currentClothesCount + 1 <= clothesSize, "exceeds clothes size");
        require(msg.value ==  withCollaboMintValue(1, specialType), "wrong price");
        if (msg.sender == owner()) {
          _publicMint(1, transferAddress);
          ISpecialSlothItemV2(_specialSlothItemAddr).mintCollaboCloth(transferAddress, 1, specialType);
          currentCollaboItemCounts[specialType] += 1;
          return;
        }
        require(msg.sender == _piementAddress, "worng address");
        _publicMint(1, transferAddress);
        ISpecialSlothItemV2(_specialSlothItemAddr).mintCollaboCloth(transferAddress, 1, specialType);
        currentCollaboItemCounts[specialType] += 1;
        emit mintWithClothAndCollabo(1, specialType, true);
    }

    function publicMintWithClothesAndCollabo(uint256 specialType, uint8 quantity) payable external {
        mintCollaboWithBody(quantity, specialType);
        emit mintWithClothAndCollabo(quantity, specialType, false);
    }
    function publicMintOnlyCollabo(uint256 specialType, uint8 quantity) payable external {
        mintCollaboCloth(quantity, specialType);
        emit mintCollabo(quantity, specialType);
    }
    function _mintHalloweenSlothCollection(address transferAddress, uint256 quantity, uint256 clothType) internal {
        if (clothType == 1) {
          ISpecialSlothItemV2(_specialSlothItemAddr).mintHalloweenJiangshiSet(transferAddress, quantity);
        }
        if (clothType == 2) {
          ISpecialSlothItemV2(_specialSlothItemAddr).mintHalloweenJacKOLanternSet(transferAddress, quantity);
        }
        if (clothType == 3) {
          ISpecialSlothItemV2(_specialSlothItemAddr).mintHalloweenGhostSet(transferAddress, quantity);
        }
    }
    function _checkAllowMintHalloween(uint256 quantity, uint256 clothType) internal view {
        require(quantity > 0, "quantity must be greater than 0");
        require(forSaleCollabo[39], "inactive collabo");
        require(clothType != 0 && clothType < 4, "invalid clothType");
    }
    function publicMintHalloweenSlothCollection(uint256 quantity, uint256 clothType) payable external {
        _checkAllowMintHalloween(quantity, clothType);
        require(msg.value == (_MINT_SLOTH_COLLECTION_PRICE * quantity), "wrong price");
        _mintHalloweenSlothCollection(msg.sender, quantity, clothType);
        emit mintSlothCollection(quantity, 39, clothType);
    }
    function publicMintHalloweenSlothCollectionForPiement(address transferAddress, uint256 quantity, uint256 clothType) payable external {
        _checkAllowMintHalloween(quantity, clothType);
        require(msg.value == (_MINT_SLOTH_COLLECTION_PRICE * quantity), "wrong price");
        if (msg.sender == owner()) {
          _mintHalloweenSlothCollection(transferAddress, quantity, clothType);
          return;
        }
        require(msg.sender == _piementAddress, "worng address");
        _mintHalloweenSlothCollection(transferAddress, quantity, clothType);
        emit mintSlothCollection(quantity, 39, clothType);
    }

    function publicMintAllHalloweenSlothCollection(uint256 quantity) payable external {
        require(quantity > 0, "quantity must be greater than 0");
        require(forSaleCollabo[39], "inactive collabo");
        uint256 numberOfCollectionKind = 3;

        require(msg.value == (numberOfCollectionKind * _MINT_SLOTH_COLLECTION_PRICE * quantity), "wrong price");
        for (uint256 i = 1; i <= numberOfCollectionKind; i++) {
          _mintHalloweenSlothCollection(msg.sender, quantity, i);
          emit mintSlothCollection(quantity, 39, i);
        }
    }
    function publicMintAllHalloweenSlothCollectionForPiement(address transferAddress, uint256 quantity) payable external {
        require(quantity > 0, "quantity must be greater than 0");
        require(forSaleCollabo[39], "inactive collabo");
        uint256 numberOfCollectionKind = 3;
        require(msg.value == (numberOfCollectionKind * _MINT_SLOTH_COLLECTION_PRICE * quantity), "wrong price");

        if (msg.sender == owner()) {
          for (uint256 i = 1; i <= 4; i++) {
            _mintHalloweenSlothCollection(transferAddress, quantity, i);
          }
          return;
        }

        require(msg.sender == _piementAddress, "worng address");
        for (uint256 i = 1; i <= 4; i++) {
          _mintHalloweenSlothCollection(transferAddress, quantity, i);
          emit mintSlothCollection(quantity, 39, i);
        }
    }

    function setPublicSale(bool newPublicSale) external onlyOwner {
        publicSale = newPublicSale;
    }
    function setSaleCollabo(uint256[] calldata specialTypeArray, bool[] calldata newSaleCollaboArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          forSaleCollabo[specialTypeArray[i]] = newSaleCollaboArray[i];
        }
    }
    function setCollaboItemSizes(uint256[] calldata specialTypeArray, uint256[] calldata itemSizeArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          collaboItemSizes[specialTypeArray[i]] = itemSizeArray[i];
        }
    }
    function setCollaboSaleEndTimes(uint256[] calldata specialTypeArray, uint256[] calldata endTimeArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          collaboSaleEndTimes[specialTypeArray[i]] = endTimeArray[i];
        }
    }
    function setCollaboSalePricePatterns(uint256[] calldata specialTypeArray, uint256[] calldata pricePatternArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          collaboSalePricePatterns[specialTypeArray[i]] = pricePatternArray[i];
        }
    }
    function setCurrentCollaboItemCount(uint256[] calldata specialTypeArray, uint256[] calldata itemCountArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          currentCollaboItemCounts[specialTypeArray[i]] = itemCountArray[i];
        }
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