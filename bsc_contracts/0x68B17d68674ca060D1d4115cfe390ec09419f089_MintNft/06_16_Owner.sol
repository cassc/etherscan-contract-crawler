// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner {
    
    struct EachNFT {
        uint8 level;
        uint16 count;
        uint256 amount;
        uint8 tokenId;
        string metaData;
    }

    struct Transaction {
        string metaData;
        address nftOwner;
        bool didStake;
        uint8 level;
        uint256 stakedTime;
        uint16 tokenId;
        uint256 amount;
        uint256 nftTokenId;

    }

    address public owner;
    uint8 public tokenId;
    mapping(uint8 => EachNFT) public AllNfts;
    mapping(uint16 => Transaction) public transactions;
    mapping(uint8 => uint16) public currentNftIds;
    mapping(uint8 => uint16) public startNftId;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        tokenId = 1;
        startNftId[1]=12000;
        startNftId[2]=14000;
        startNftId[3]=15000;
        startNftId[4]=16000;
        startNftId[5]=17000;
        currentNftIds[1]=11999;
        currentNftIds[2]=13999;
        currentNftIds[3]=14999;
        currentNftIds[4]=15999;
        currentNftIds[5]=16999;
    }


    function setNftStartId(uint16 _startID)external onlyOwner{
        currentNftIds[uint8(tokenId)]=_startID;
    }
    function addNft(
        uint8 _level,
        uint16 _count,
        uint256 _amount,
        string calldata _metaData
    ) external onlyOwner {
        uint256 amount = _amount * 10**18;
        AllNfts[uint8(tokenId)] = EachNFT(_level, _count, amount, tokenId, _metaData);
        tokenId += 1;
    }


    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeSpaceShipPrice(bool _increase,uint8 _level , uint8 _percent) external  onlyOwner {

            EachNFT storage currentItem = AllNfts[_level];

                uint256 finalAmount = AllNfts[_level].amount * _percent;
                finalAmount = finalAmount / 100+1e17;
                finalAmount=(finalAmount*1e18)/1e18;
                if (_increase == true) {
                    currentItem.amount = currentItem.amount + finalAmount;
                    
                }else {
                    currentItem.amount = currentItem.amount - finalAmount;
                }
            
                AllNfts[_level].amount = currentItem.amount/1e17*1e17;
    }
    
}