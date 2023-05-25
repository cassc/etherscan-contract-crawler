// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cryptorastas is ERC721, Ownable {
    using SafeMath for uint256;
    
    uint256 public constant MAX_RASTA = 10221;
    uint256 private constant OFFICIAL_COLABS = 200;

    uint256 public price;
    bool public hasSaleStarted = false;
    address ownerAccountAddress;
    string baseContractURI;
    
    event Minted(uint256 tokenId, address owner);
    
    constructor(string memory baseURI, string memory contractURI, address accountAddress) ERC721("Cryptorastas", "RASTA") {
        setBaseURI(baseURI);
        ownerAccountAddress = accountAddress;
        baseContractURI = contractURI;
        price = 0.05 ether; 
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
    
    function Mint420(uint256 quantity) public payable {
        mint420(quantity, msg.sender);
    }
    
    function mint420(uint256 quantity, address receiver) public payable {
        require(hasSaleStarted || msg.sender == owner(), "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(quantity <= 40, "exceeds 40");
        require(totalSupply().add(quantity) <= MAX_RASTA || msg.sender == owner(), "sold out");
        require(msg.value >= price.mul(quantity) || msg.sender == owner(), "ether value sent is below the price");
        
        payable(ownerAccountAddress).transfer(msg.value);
        
        for (uint i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(receiver, mintIndex);
            emit Minted(mintIndex, receiver);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function hasSoldOut() public view returns (bool) {
        if (totalSupply() >= MAX_RASTA) {
            return true;
        } else {
            return false;
        }
    }
}