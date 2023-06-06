// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

contract WutziBot is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public MAX_ELEMENTS = 5555;
    uint256 public PUBLIC_COUNT = 5300;
    uint256 public ADMIN_LIMIT = PUBLIC_COUNT;
    uint256 public PRICE = 8 * 10**16; // 0.1 ETH
    uint256 public MAX_BY_MINT = 25;

    
    string public baseTokenURI; // IPFS
    bool private risk_protect_mode = false;

    constructor(string memory baseURI) ERC721("WutziBot", "WutziBot") {

        baseTokenURI = baseURI;
        pause(true);
    }

    modifier saleIsOpen(uint256 _count) {
        require(_totalSupply() + _count <= PUBLIC_COUNT, "MINT: exceed limitation");

        require(!paused(), "Pausable: paused");
        _;
    }

    // The count only for public sale
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    // Mint one token
    function mint(address _to, uint256 _count) public payable saleIsOpen(_count) {
        require(_count <= MAX_BY_MINT, "Exceeds max mint amount");  
        require(msg.value == price(_count), "Value: not correct");

        batchMint(_to, _count);
    }

    function batchMint(address _to, uint256 _count) private {
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    // mint one Token to sender
    function _mintAnElement(address _to) private {
        // To avoid number 0
        uint id = _totalSupply() + 1;
        if (risk_protect_mode && _exists(id)) {
            for (uint256 i = id; i <= PUBLIC_COUNT; i++) {
                if (!_exists(i)) break;
                _tokenIdTracker.increment();
            }
            id = _totalSupply() + 1;
        }
        
        _tokenIdTracker.increment();
        _safeMint(_to, id);
    }

    // Admin mint
    function adminMint(uint256 _tId, address _to) private {
        require(_tId <= MAX_ELEMENTS, "Id should be smaller than MAX");
        require(_tId > ADMIN_LIMIT, "Id should be bigger than admin limit");

        _safeMint(_to, _tId);
    }

    
    // Admin batch mint
    function adminBatchMint(uint256 _tId, address _to, uint256 _count) external onlyOwner {
        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenIdToMint = _tId + i;
            adminMint(tokenIdToMint, _to);
        }
    }


    // the total price of token amounts which the sender will mint
    function setMaxByMint(uint256 _MAX_BY_MINT) external onlyOwner {
        require(MAX_BY_MINT != _MAX_BY_MINT, "Already set");

        MAX_BY_MINT = _MAX_BY_MINT;
    }
    
    // set MAX_ELEMENTS
    function setRiskMode(bool isRisk) public onlyOwner {
        require(risk_protect_mode != isRisk, "Already set");
        risk_protect_mode = isRisk;
    }

    // set MAX_ELEMENTS
    function setMaxElements(uint256 _count) public onlyOwner {
        MAX_ELEMENTS = _count;
    }
    // set the count of public list
    function setPublicCount(uint256 _count) public onlyOwner {
        PUBLIC_COUNT = _count;
    }

    // set admin limit
    function setAdminLimit(uint256 _limit) public onlyOwner {
        ADMIN_LIMIT = _limit;
    }

    // the total price of token amounts which the sender will mint
    function setPrice(uint256 _PRICE) external onlyOwner {
        require(PRICE != _PRICE, "Already set");
        PRICE = _PRICE;
    }

    // the total price of token amounts which the sender will mint
    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // set BaseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


    // get wallet infos
    function getOwnerTokenIds(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    // set the state of market
    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    // withdraw all BNB
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(msg.sender, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // override function
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}