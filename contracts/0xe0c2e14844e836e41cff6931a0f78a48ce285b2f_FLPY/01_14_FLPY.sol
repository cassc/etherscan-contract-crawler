// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FLPY is ERC721Enumerable, Pausable, Ownable {

    uint256 public allowedToExist;
    uint256 public price = 100000000000000000;

    bool public isRevealed;
    bool public URILocked;

    string private __baseURI;

    constructor(string memory baseURI_) ERC721("Flappy Sack", "FLPY") {
        __baseURI = baseURI_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setAllowedToExist(uint256 amount) external onlyOwner {
        allowedToExist = amount;
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        require(!URILocked, "URI already locked");
        __baseURI = baseURI_;
    }

    function lockBaseURI() external onlyOwner {
        URILocked = true;
    }

    function getETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function mintAsOwner(address[] calldata accounts) external onlyOwner {
        require(totalSupply() + accounts.length <= 10000, "Cannot mint this much");
        for (uint256 i; i < accounts.length; i++) {
            _safeMint(accounts[i], totalSupply());
        }
    }

    function buy(uint256 amount) external payable whenNotPaused {
        uint256 toExist = totalSupply() + amount;
        require((toExist <= allowedToExist) && (toExist <= 10000), "Cannot buy this much");
        require(msg.value == price * amount, "Invalid payment amount");
        for (amount; amount > 0; amount--) {
            _safeMint(_msgSender(), totalSupply());
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }
}