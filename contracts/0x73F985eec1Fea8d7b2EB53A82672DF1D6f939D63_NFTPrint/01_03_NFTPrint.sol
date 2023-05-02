// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ICollection {
    function owner() external view returns (address);
}

contract NFTPrint is Ownable {
    uint256 public price;
    uint256 public E4 = 10 ** 18;
    uint256 public feeRatio = 5 * 10 ** 16;
    address public defaultReciveAddress;
    mapping(address => bool) public blackListWallet;
    mapping(address => address) public collectionToReciver;

    event Print(address indexed collection, uint256 tokenId);

    constructor(uint256 _price, address _defaultReciveAddress) {
        price = _price;
        defaultReciveAddress = _defaultReciveAddress;
    }

    //
    //MAIN
    //
    function print(address collection, uint256 tokenId) external payable {
        //check
        require(msg.value >= price, "Not Enough Value");

        //collection owner
        address _reciver = ICollection(collection).owner();
        uint256 _rolyalty = (price * feeRatio) / E4;
        uint256 _fee = price - _rolyalty;

        //opensea or original contract
        if (blackListWallet[collection] || _reciver == address(0)) {
            payable(defaultReciveAddress).transfer(price);
        } else if (collectionToReciver[collection] != address(0)) {
            payable(collectionToReciver[collection]).transfer(_rolyalty);
            payable(defaultReciveAddress).transfer(_fee);
        } else {
            payable(_reciver).transfer(_rolyalty);
            payable(defaultReciveAddress).transfer(_fee);
        }
        emit Print(collection, tokenId);
    }

    //
    //SET
    //
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setFeeRatio(uint256 _feeRatio) external onlyOwner {
        feeRatio = _feeRatio;
    }

    function setCollectionReciver(
        address _collection,
        address _reciveAddress
    ) external onlyOwner {
        collectionToReciver[_collection] = _reciveAddress;
    }

    function setDefaultReciveAddress(
        address _defaultReciveAddress
    ) external onlyOwner {
        defaultReciveAddress = _defaultReciveAddress;
    }

    function setBlackListWallet(
        address _collection,
        bool _status
    ) external onlyOwner {
        blackListWallet[_collection] = _status;
    }
}