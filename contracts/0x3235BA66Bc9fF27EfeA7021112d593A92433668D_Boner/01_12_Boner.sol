// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

 contract Boner is ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;
    
    string public baseURI;

    uint256 public constant TOTAL_FREE = 496;
    uint256 public constant MAX_FREE = 5;
    uint256 public constant MAX_PUBLIC = 20;

    string public constant BASE_EXTENSION = ".json";

    uint256 public maxBoner = 6969;
    uint256 public price = 0.0055 ether;

    bool public saleActive = false;
    bool public adminClaimed = false;

    constructor() ERC721A("Boners", "TASM", MAX_PUBLIC) { 
    }

    function adminMint() public onlyOwner {
        require(!adminClaimed,                                                  "Admim has claimed");
        adminClaimed = true;
        _safeMint( msg.sender, 1); 
    }

    function freeMint(uint256 _numberOfMints) private {
        require(_numberOfMints > 0 && _numberOfMints <= MAX_FREE,              "Invalid mint amount");
        if(totalSupply() + _numberOfMints > TOTAL_FREE){
            _safeMint( msg.sender, TOTAL_FREE - totalSupply()); 
        } else {
            _safeMint( msg.sender, _numberOfMints); 
        }   
    }
    
    function publicMint(uint256 _numberOfMints) private {
        require(_numberOfMints > 0 && _numberOfMints <= MAX_PUBLIC,            "Invalid mint amount");
        require(totalSupply() + _numberOfMints <= maxBoner,                    "Purchase would exceed max supply of tokens");
        require(price * _numberOfMints == msg.value,                           "Ether value sent is not correct");
        
        _safeMint( msg.sender, _numberOfMints );
    }

    function mint(uint256 _numberOfMints) public payable {
        require(saleActive,                                                     "Not started");
        require(tx.origin == msg.sender,                                        "What ya doing?");
        if(totalSupply() < TOTAL_FREE){
            freeMint(_numberOfMints);
        } else {
            publicMint(_numberOfMints);
        }
    }


    function setSupply(uint256 _maxBoner) public onlyOwner {
        maxBoner = _maxBoner;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
         require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _id.toString(), BASE_EXTENSION))
            : "";
    }

    function withdraw(address _address) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_address).transfer(balance);
    }    
}