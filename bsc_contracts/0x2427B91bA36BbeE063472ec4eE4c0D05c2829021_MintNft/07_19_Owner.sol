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
    enum Sale{
        retail,
        low,
        medium,
        much,
        tooMuch
    }
    bool public retailLock;
    address public owner;
    uint16 public tokenId;
    mapping(uint16 => EachNFT) public AllNfts;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint8=>uint256 [4])public tokenAmounts;
    mapping(uint8=>uint256 [4])public tokenPrices;

    modifier onlyOwner() {
        require(msg.sender == owner, "owner");
        _;
    }

    constructor() {
        tokenPrices[1]=[10e18,20e18,50e18,100e18];
        tokenPrices[2]=[10e18,20e18,50e18,100e18];
        tokenPrices[3]=[10e18,20e18,50e18,100e18];
        tokenPrices[4]=[10e18,20e18,50e18,100e18];
        tokenAmounts[1]=[5000,11000,30000,66000];
        tokenAmounts[2]=[180,380,1020,2250];
        tokenAmounts[3]=[50,120,350,775];
        tokenAmounts[4]=[5,12,32,68];
        owner = msg.sender;
        tokenId = 1;
        retailLock=true;
    }
    
    function lockRetail(bool _lock)external onlyOwner{
        retailLock=_lock;
    }

    function addNft(
        uint16 _level,
        uint256 _amount,
        string calldata _metaData

    ) external onlyOwner {

        AllNfts[tokenId] = EachNFT(_level, _amount, _metaData,tokenId);
        tokenId += 1;
    }


    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeSinglePriceResources(bool _increase,uint16 _level , uint8 _percent) external  onlyOwner {
    
        uint256 finalAmount = AllNfts[_level].amount * _percent;
        finalAmount = finalAmount / 100;
        finalAmount=(finalAmount*1e18)/1e18;
        if (_increase == true) {
            AllNfts[_level].amount = AllNfts[_level].amount + finalAmount;
            
        }else {
            AllNfts[_level].amount = AllNfts[_level].amount - finalAmount;
        }
    
            AllNfts[_level].amount = AllNfts[_level].amount/1e14*1e14;

    }
    function changeResourcesPrice(bool _increase,uint8 _level , uint8 _percent)external  onlyOwner {
        uint8 _tokenID=_level-1;
        for (uint i = 0; i < 4; i++) {
            uint256 finalAmount = tokenPrices[_tokenID][i] * _percent;
            finalAmount = finalAmount / 100+1e17;
            finalAmount=(finalAmount*1e18)/1e18;

            if (_increase == true) {
            tokenPrices[_level][i] = tokenPrices[_level][i] + finalAmount;
            
            }else {
                tokenPrices[_level][i] = tokenPrices[_level][i] - finalAmount;
            }
        
                tokenPrices[_level][i] = tokenPrices[_level][i]/1e17*1e17;

        }
        
    }
}