//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


contract GogglingGoblins is Ownable, ERC721A, ReentrancyGuard {
   
    uint256 public ALL_AMOUNT = 10000;

    uint256 public UPDATE_PRICE = 2500;

    uint16 public FREE_MINTED;

    uint16 public FREE_LIMIT=5;

    uint256 public FREE_START_TIME = 1654196400;

    uint256 public FREE_PRICE = 0 ether;

    uint256 public MAIN_PRICE = 0.003 ether;

    mapping(address => uint256) public FREE_WALLET_CAP;

    bool _isFreeActive = false;
    
    string public BASE_URI="https://data.gogglinggoblins.com/metadata/";
    string public CONTRACT_URI ="https://data.gogglinggoblins.com/api/contracturl.json";


    constructor() ERC721A("Gogglinggoblins", "Gogglinggoblins") {
        _safeMint(msg.sender, 1);
    }  
    
    function freeInfo(address user) public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
         if(totalSupply()>=UPDATE_PRICE){
             return  (ALL_AMOUNT,totalSupply(),MAIN_PRICE,FREE_START_TIME,0,FREE_WALLET_CAP[user]);
        }else{
             return  (ALL_AMOUNT,totalSupply(),FREE_PRICE,FREE_START_TIME,0,FREE_WALLET_CAP[user]);
        }
    }


    function freeMint(uint256 quantity) public payable
    {
        if(totalSupply()>=UPDATE_PRICE){
            require(msg.value >= quantity * MAIN_PRICE,"Did not send enough eth.");
        }else{
            require(msg.value >= quantity * FREE_PRICE,"Did not send enough eth.");
        }
       
        require(_isFreeActive, "Free must be active to mint tokens");
        require(FREE_WALLET_CAP[msg.sender] + quantity <= FREE_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        require(totalSupply() + quantity <= ALL_AMOUNT, "reached max supply");


        FREE_WALLET_CAP[msg.sender] +=quantity;
        _safeMint(msg.sender, quantity);
    }
 

   function withdraw() public onlyOwner nonReentrant {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}('');
        require(succ, "transfer failed");
   }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }


    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
    }

    function flipState(bool isFreeActive) external onlyOwner {
        _isFreeActive=isFreeActive;
    }

    function setPrice(uint256 price) public onlyOwner
    {
        FREE_PRICE = price;
    }

    function setAllStartTime(uint256 freeTime) external onlyOwner {
        FREE_START_TIME = freeTime;
    }


}