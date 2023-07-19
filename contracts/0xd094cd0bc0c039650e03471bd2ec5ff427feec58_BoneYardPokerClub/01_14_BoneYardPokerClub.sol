// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

 contract BoneYardPokerClub is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    string public PROVENANCE;
    string private baseURI;

    address private _teamAddress = 0x978572f173D369fA626A662556eb634fe92f0D4c;
    
    uint256 public maxSupply;
    uint256 public publicPrice = 0.0888 ether;
    uint256 public presalePrice = 0.08 ether;

    bool public presaleActive = false;
    bool public saleActive = false;

    mapping (address => uint256) public presaleWhitelist;

    constructor(string memory name, string memory symbol, uint256 supply) ERC721(name, symbol) {
        maxSupply = supply;
    }
    
    function reserve() public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < 50; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintPresale(uint256 numberOfMints) public payable {
        uint256 supply = totalSupply();
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive,                              "Presale must be active to mint");
        require(reserved > 0,                               "No tokens reserved for this address");
        require(numberOfMints <= reserved,                  "Can't mint more than reserved");
        require(supply.add(numberOfMints) <= maxSupply,     "Purchase would exceed max supply of tokens");
        require(presalePrice.mul(numberOfMints) == msg.value,      "Ether value sent is not correct");
        presaleWhitelist[msg.sender] = reserved - numberOfMints;

        for(uint256 i; i < numberOfMints; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function mint(uint256 numberOfMints) public payable {
        uint256 supply = totalSupply();
        require(saleActive,                                 "Sale must be active to mint");
        require(numberOfMints > 0 && numberOfMints < 21,    "Invalid purchase amount");
        require(supply.add(numberOfMints) <= maxSupply,     "Purchase would exceed max supply of tokens");
        require(publicPrice.mul(numberOfMints) == msg.value,      "Ether value sent is not correct");
        
        for(uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function editPresale(address[] memory presaleAddresses, uint256[] memory amount) public onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount[i];
        }
    }
    
    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        payable(_teamAddress).transfer(address(this).balance * 4 / 5);
        payable(msg.sender).transfer(address(this).balance);
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

     function setPresalePrice(uint256 newPrice) public onlyOwner {
        presalePrice = newPrice;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}