// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MTBN is ERC721Enumerable, Pausable, Ownable {

    uint256 public allowedToExist;

    bool public auctionIsOn;
    uint256 public auctionStartTime;
    uint256 public auctionTimeStep;
    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;
    uint256 public auctionStepDecreaseAmount;

    bool public URILocked;
    bool public whitelistEnabled;

    mapping (address => bool) public whitelist;

    string private __baseURI;
    uint256 private _price = 260000000000000000;

    constructor(string memory baseURI_) ERC721("MetaBunny", "MTBN") {
        __baseURI = baseURI_;
    }

    function startAuction(uint256 _auctionStartPrice, uint256 _auctionEndPrice, uint256 _auctionStepDecreaseAmount, uint256 _auctionTimeStep) 
        external onlyOwner {
            auctionIsOn = true;
            auctionStartTime = block.timestamp;
            auctionStartPrice = _auctionStartPrice;
            auctionEndPrice = _auctionEndPrice;
            auctionStepDecreaseAmount = _auctionStepDecreaseAmount;
            auctionTimeStep = _auctionTimeStep;
    }

    function addToWhitelist(address[] calldata _accounts) external onlyOwner {
        for (uint256 i; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata _accounts) external onlyOwner {
        for (uint256 i; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = false;
        }
    }

    function enableWhitelist() external onlyOwner {
        whitelistEnabled = true;
    }

    function disableWhitelist() external onlyOwner {
        whitelistEnabled = false;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPrice(uint256 price_) external onlyOwner {
        auctionIsOn = false;
        _price = price_;
    }

    function setAllowedToExist(uint256 amount) external onlyOwner {
        allowedToExist = amount;
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
        require(!whitelistEnabled || whitelist[_msgSender()], "Not whitelisted");
        uint256 toExist = totalSupply() + amount;
        require((toExist <= allowedToExist) && (toExist <= 10000), "Cannot buy this much");
        require(msg.value >= price() * amount, "Invalid payment amount");
        uint256 toReturn = (msg.value - (price() * amount));
        for (amount; amount > 0; amount--) {
            _safeMint(_msgSender(), totalSupply());
        }
        if (toReturn > 0) {
            payable(_msgSender()).transfer(toReturn);
        }
    }

    function price() public view returns(uint256) {
        if (!auctionIsOn) {
            return _price;
        }
        else {
            uint256 priceDecrease = (((block.timestamp - auctionStartTime) / auctionTimeStep) * auctionStepDecreaseAmount);
            uint256 _auctionEndPrice = auctionEndPrice;
            uint256 _auctionStartPrice = auctionStartPrice;
            if ((_auctionEndPrice + priceDecrease) >= _auctionStartPrice) {
                return _auctionEndPrice;
            }
            else {
                return _auctionStartPrice - priceDecrease;
            }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }
}