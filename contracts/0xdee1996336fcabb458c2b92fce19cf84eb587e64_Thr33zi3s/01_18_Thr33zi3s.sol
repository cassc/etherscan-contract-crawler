// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Thr33zi3s is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string _baseTokenURI = "https://api.thr33zi3s.com/token/";

    uint256 public price;

    mapping (address => uint256) public thirtyThreeList;
    mapping (address => uint256) public swipeList;

    constructor() ERC721("Thr33zi3s", "333") {}

    function updateBaseURI(string memory newbaseURI) public onlyOwner {
        _baseTokenURI = newbaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mintThirtyThree(uint256 num) public payable whenNotPaused nonReentrant {
        require(price == 330000000000000000,           "33 Sale Not Active"); // 0.33 ETH
        require(msg.value == price * num,              "Ether sent is not correct");

        uint256 _supply = totalSupply();
        // Check available supply
        require(_supply + num < 101,                    "Exceeds maximum supply");

        uint256 thirtyThreeAllowed = thirtyThreeList[msg.sender];
        require(num <= thirtyThreeAllowed,             "Allowed mints exceeded.");
        // iterate and mint
        for(uint256 i; i < num; i++){
            thirtyThreeList[msg.sender]--;
            uint256 tokenId = _tokenIdCounter.current() + 1; //triple check and test counts
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintSwipe(uint256 num) public payable whenNotPaused nonReentrant {
        require(price == 500000000000000000,           "Swipe Sale Not Active"); //0.5 ETH
        require(msg.value == price * num,              "Ether sent is not correct");
        // check supply
        uint256 _supply = totalSupply();
        require(_supply + num < 101,                    "Exceeds maximum supply");

        uint256 swipeAllowed = swipeList[msg.sender];
        require(num <= swipeAllowed,                   "Allowed mints exceeded.");

        // iterate and mint
        for(uint256 i; i < num; i++){
            swipeList[msg.sender]--;
            uint256 tokenId = _tokenIdCounter.current() + 1; //triple check and test counts
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintThrees(address to, uint256 num) public onlyOwner {
        uint256 _supply = totalSupply();
        require(_supply + num < 101,                   "Exceeds maximum supply");
        for(uint256 i; i < num; i++){
            uint256 tokenId = _tokenIdCounter.current() + 1;
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function addToThirtyThreeList(address[] calldata users, uint256[] calldata quantity) external onlyOwner {
        require(users.length == quantity.length,       "Must submit equal counts of users and quantities");
        for(uint256 i = 0; i < users.length; i++){
            thirtyThreeList[users[i]] = quantity[i];
        }
    }

    function addToSwipeList(address[] calldata users, uint256[] calldata quantity) external onlyOwner {
        require(users.length == quantity.length,       "Must submit equal counts of users and quantities");
        for(uint256 i = 0; i < users.length; i++){
            swipeList[users[i]] = quantity[i];
        }
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
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