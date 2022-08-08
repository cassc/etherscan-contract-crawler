// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract BittyBirds is ERC721A, Ownable {
    using Address for address;

    //#USUAL FARE
    string public baseURI = "https://contagion.mypinata.cloud/ipfs/QmQgpNQ3nYDQpkAyEmPwXeLbEQsEYVyfNvbdty8RLoY45E/";

    bool public saleActive = false;
    uint256 public MAX_MINT_IS_TWO = 2;
    
    uint256 public price = 0.0 ether;
    uint256 public constant MAX_BITTYS = 10000;
    mapping(address => uint256) private mintCount;


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    constructor() ERC721A("BittyBirds", "BB") {
    }


    function letsGetBitty(uint256 numberOfMints) public payable {
        address _to = msg.sender;
        uint256 minted = mintCount[_to];

        require(saleActive,                                         "Sale must be active to mint");
        require(numberOfMints > 0 && numberOfMints < 3,             "Invalid purchase amount");
        require(minted + numberOfMints < MAX_MINT_IS_TWO + 1, "mint over max");
        require(totalSupply() + numberOfMints < MAX_BITTYS + 1,         "Purchase would exceed max supply of tokens");
        require(msg.sender == tx.origin,"message being sent doesn't not match origin");
        mintCount[_to] = minted + numberOfMints;

        
        _safeMint(msg.sender, numberOfMints);
    }

    // Only Owner executable functions
    function mintByOwner(address _to, uint256 _mintAmount) external onlyOwner {
        _safeMint(_to, _mintAmount);
    }



    
    //#SETTERS
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }  

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }    

}