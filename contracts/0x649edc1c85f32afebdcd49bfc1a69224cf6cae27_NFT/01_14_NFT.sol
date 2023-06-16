// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC721Enumerable.sol";
import "ERC721A.sol";

contract NFT is ERC721A, Ownable {
    bool public saleIsActive = false;
    string private _baseURIextended;

    uint256 public MAX_SUPPLY;
    uint256 public currentPrice;
    uint256 public walletLimit;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 limit,
        uint256 price,
        uint256 maxSupply
    ) ERC721A(_name, _symbol) {
        currentPrice = price;
        walletLimit = limit;
        MAX_SUPPLY = maxSupply;
    }

    function mint(uint256 amount) external payable {
        uint256 ts = totalSupply();
        uint256 minted = _numberMinted(msg.sender);

        require(saleIsActive, "Sale must be active to mint tokens");
        require(amount + minted <= walletLimit, "Exceed wallet limit");
        require(ts + amount <= MAX_SUPPLY, "Purchase would exceed max tokens");

        uint256 freeTokens = minted >= 2 ? 0 : 2 - minted;
        if (amount < freeTokens) {
            freeTokens = amount;
        }

        require(
            currentPrice * (amount - freeTokens) == msg.value,
            "Value sent is not correct"
        );

        _safeMint(msg.sender, amount);
    }

    function reserve(address to, uint256 amount) public onlyOwner {
        uint256 ts = totalSupply();
        require(ts + amount <= MAX_SUPPLY, "Purchase would exceed max tokens");
        _safeMint(to, amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setSaleIsActive(bool isActive) external onlyOwner {
        saleIsActive = isActive;
    }

    function setCurrentPrice(uint256 price) external onlyOwner {
        currentPrice = price;
    }

    function setWalletLimit(uint256 limit) external onlyOwner {
        walletLimit = limit;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}