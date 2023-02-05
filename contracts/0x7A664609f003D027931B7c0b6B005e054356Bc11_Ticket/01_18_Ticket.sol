// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Contract by technopriest#0760
contract Ticket is ERC721, PaymentSplitter, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenIds;

    string defaultBaseURI;
    uint256 public salePrice;
    uint256 public maxSupply;
    bool public saleIsActive = true;

    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        address[] memory payees_,
        uint256[] memory shares_,
        string memory defaultBaseURI_,
        uint256 salePrice_,
        uint256 maxSupply_
    ) payable ERC721(tokenName_, tokenSymbol_) PaymentSplitter(payees_, shares_) {
        salePrice = salePrice_;
        defaultBaseURI = defaultBaseURI_;
        maxSupply = maxSupply_;
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
        tokenIds.increment();
        _safeMint(recipient_, tokenIds.current());
        return tokenIds.current();
    }

    function purchase() external payable returns (uint256) {
        require(saleIsActive, "Sale must be active to acquire a token");
        require(salePrice <= msg.value, "Insufficient Ether value sent");
        require(tokenIds.current() + 1 <= maxSupply, "exceeds max supply");

        return _mintTicket(msg.sender);
    }

    function addBatch(uint256 batchQty_) external onlyOwner {
        maxSupply += batchQty_;
    }

}