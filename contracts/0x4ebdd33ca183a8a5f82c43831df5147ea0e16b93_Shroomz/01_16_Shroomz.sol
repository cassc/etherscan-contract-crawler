// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Shroomz is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    constructor() ERC721("shroomz", "SHROOMZ")
    {
    }
    
    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public constant RESERVED_SUPPLY = 690; // Marketing/Team

    uint256 public constant MAX_PURCHASE = 10;

    uint256 public constant PRICE = 0.042 ether;

    bool public saleIsActive = false;

    mapping(address => uint256) public whitelist;

    uint256 public mintedReserved;

    uint256 private nextTokenId;

    uint256 private startingIndex;

    string private tokenBaseURI; 

    event WhitelistAdded(address indexed addr, uint256 indexed tokenAmount);

    function mint(uint256 numberOfNfts) external nonReentrant payable {
        require(saleIsActive, "Sale did not start");
        require(totalSupply().sub(mintedReserved).add(numberOfNfts) <= MAX_SUPPLY - RESERVED_SUPPLY, "Exceeds max supply");
        require(numberOfNfts > 0, "Cannot buy 0");
        require(numberOfNfts <= MAX_PURCHASE, "You may not buy that many NFTs at once");
        require(PRICE.mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, nextTokenId); 
            nextTokenId = nextTokenId.add(1).mod(MAX_SUPPLY);
        }
    }

    function mintReserve(uint256 numberOfNfts) external nonReentrant {
        require(saleIsActive, "Sale did not start");
        require(totalSupply().add(numberOfNfts) <= MAX_SUPPLY, "Exceeds max supply");
        require(numberOfNfts > 0, "Cannot buy 0");
        require(numberOfNfts <= MAX_PURCHASE, "You may not buy that many NFTs at once");
        require(whitelist[msg.sender] >= numberOfNfts, "Not enough reserve allowance");

        whitelist[msg.sender] = whitelist[msg.sender].sub(numberOfNfts);

        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, nextTokenId); 
            nextTokenId = nextTokenId.add(1).mod(MAX_SUPPLY);
        }

        mintedReserved += numberOfNfts;
    }

    function withdraw() onlyOwner public {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }    

    function addWhitelist(address addr, uint256 tokenAmount) onlyOwner external {
        whitelist[addr] = tokenAmount;
        emit  WhitelistAdded(addr, tokenAmount);
    }

    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }    

    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set.");
        
        startingIndex = uint256(blockhash(block.number - 1)) % MAX_SUPPLY;
   
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }

        nextTokenId = startingIndex;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setTokenBaseURI(string memory _tokenBaseURI) public onlyOwner {
        tokenBaseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}