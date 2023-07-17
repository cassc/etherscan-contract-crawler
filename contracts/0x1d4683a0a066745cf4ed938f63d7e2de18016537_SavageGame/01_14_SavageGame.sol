// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract SavageGame is Ownable, ERC721Enumerable {
    using Strings for uint256;    
    uint256 public MAXSUPPLY = 10000;
    uint256 public MINT_PRICE = 0.09 ether;
    uint256 private SALES_LIMIT = 25;    
    string private baseURI;
    string public baseExtension = ".json";    
    bool public isLaunched= false;



    constructor(string memory _initBaseURI) ERC721("Savages Game - The Immortals", "Savages") {
        setBaseURI(_initBaseURI);        
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        ); 

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function saleToggle() public onlyOwner {
        isLaunched = !isLaunched;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        MINT_PRICE = newPrice;
    } 

    function withdraw() public payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    function mint( uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();
        require(isLaunched, "General mint has not started");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");        
        require(supply + _mintAmount <= MAXSUPPLY, "Exceeds contract limit");
        require(_mintAmount <= SALES_LIMIT, "Mint limit exceeded.");        
        require(
            msg.value >= MINT_PRICE * _mintAmount,
            "Not enough eth sent: check price"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
}