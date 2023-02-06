// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner {
    
    struct EachNFT {
        uint16 level;
        uint256 amount;
        string metaData;
        uint16 tokenId;

    }

    struct Transaction {
        string metaData;
        address nftOwner;
        uint16 level;
        uint256 count;
        uint256 amount;
        uint16 tokenId;

    }

    address public owner;
    uint16 public tokenId;
    mapping(uint16 => EachNFT) public AllNfts;
    mapping(uint256 => Transaction) public transactions;


    modifier onlyOwner() {
        require(msg.sender == owner, "owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        tokenId = 1;
    }



    function addNft(
        uint16 _level,
        uint256 _amount,
        string calldata _metaData

    ) external onlyOwner {
        uint256 amount = _amount * 10**18;
        AllNfts[tokenId] = EachNFT(_level, amount, _metaData,tokenId);
        tokenId += 1;
    }


    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeNftBoxPrice(bool _increase,uint16 _level , uint8 _percent) external  onlyOwner {
        for (uint256 i = 1; i <= tokenId; i++) {
            EachNFT storage currentItem = AllNfts[uint16(i)];
            if (currentItem.level == _level) {
                uint256 finalAmount = AllNfts[uint16(i)].amount * _percent;
                finalAmount = finalAmount / 100+1e17;
                finalAmount=(finalAmount*1e18)/1e18;
                if (_increase == true) {
                    currentItem.amount = currentItem.amount + finalAmount;
                    
                }else {
                    currentItem.amount = currentItem.amount - finalAmount;
                }
            }
                    currentItem.amount = currentItem.amount/1e17*1e17;

        }
    }
    
}