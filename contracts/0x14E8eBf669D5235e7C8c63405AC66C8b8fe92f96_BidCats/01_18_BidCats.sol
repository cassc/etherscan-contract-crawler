// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";


// Contract by technopriest#0760
contract BidCats is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenIds;

    string defaultBaseURI;
    uint256 public salePrice;
    uint256 public maxQuantity;
    uint256 public tokenCounter;
    uint256 public reservedTokens;
    address payable public wallet;
    bool public saleIsActive = true;

    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        string memory defaultBaseURI_,
        uint256 reservedTokens_,
        uint256 salePrice_,
        uint256 maxQuantity_,
        address payable _wallet
    ) payable ERC721(tokenName_, tokenSymbol_) {
        salePrice = salePrice_;
        defaultBaseURI = defaultBaseURI_;
        maxQuantity = maxQuantity_;
        reservedTokens = reservedTokens_;
        tokenCounter = reservedTokens_;
        wallet = _wallet;
    }

    function _baseURI() internal view override returns (string memory) {
        return defaultBaseURI;
    }

    function setBaseURI(string memory newBaseURI_) external onlyOwner {
        defaultBaseURI = newBaseURI_;
    }

    function setSalePrice(uint256 salePrice_) external onlyOwner {
        salePrice = salePrice_;
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }


    function _mintTicket(address recipient_) private returns (uint256) {
        tokenCounter += 1;
        _safeMint(recipient_, tokenCounter);
        return tokenCounter;
    }

    function purchase() external payable returns (uint256) {
        require(saleIsActive, "Sale must be active to acquire a token");
        require(salePrice <= msg.value, "Insufficient Ether value sent");
        require(tokenCounter + 1 <= maxQuantity, "exceeds max quantity");
        return _mintTicket(msg.sender);
    }

    function purchaseMany(uint256 quantity_) external payable {
        require(saleIsActive, "Sale must be active to acquire a token");
        require(salePrice.mul(quantity_) <= msg.value, "Insufficient Ether value sent");
        require(quantity_ <= maxQuantity, "exceeds max quantity");
        require(tokenCounter + quantity_ <= maxQuantity, "exceeds max quantity");

        for (uint256 i = 0; i < quantity_; i++) {
            _mintTicket(msg.sender);
        }
    }

    function batchMint(uint256[] memory assignTokenIds, address[] memory recipients) external onlyOwner {
        for (uint256 i = 0; i < assignTokenIds.length; i++) {
            require(assignTokenIds[i] <= reservedTokens, "invalid id");
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], assignTokenIds[i]);
        }
    }

    function withdrawFunds(uint256 amount) external {
        require(amount <= address(this).balance);
        Address.sendValue(wallet, amount);
    }


}