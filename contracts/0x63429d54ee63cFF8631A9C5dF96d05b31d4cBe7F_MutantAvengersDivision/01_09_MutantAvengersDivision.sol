//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract MutantAvengersDivision is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
   
    uint256 public ALL_AMOUNT = 2222;

    uint256 public PRICE = 0.0049 ether;

    uint256 public LIMIT = 5;

    bool _isActive = false;
    
    string public BASE_URI="https://data.themadnft.net/metadata/";
    string public CONTRACT_URI ="https://data.themadnft.net/api/contracturl.json";

    struct Info {
        uint256 all_amount;
        uint256 minted;
        uint256 price;
        uint256 start_time;
        uint256 numberMinted;
        bool isActive;
    }


    constructor() ERC721A("MutantAvengersDivision", "mutantavengersdivision") {
        _safeMint(msg.sender, 2);
    }  
    
    function freeInfo(address user) public view returns (Info memory) {
        return  Info(ALL_AMOUNT,totalSupply(),PRICE,0,_numberMinted(user),_isActive);
    }


    function mint(uint256 amount) external payable {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_isActive, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");
        require(totalSupply() + amount <= ALL_AMOUNT, "max supply would be exceeded");

        uint minted = _numberMinted(msg.sender);
        require(minted + amount <= LIMIT, "max mint per wallet would be exceeded");
        
        require(msg.value >= PRICE * amount, "value not met");
        _safeMint(msg.sender, amount);
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

    function flipState(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setPrice(uint256 price) public onlyOwner
    {
        PRICE = price;
    }


}