// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DOOM is ERC20, ERC20Burnable, ERC20Permit, Ownable, ReentrancyGuard {
    uint256 private constant TOTAL_SUPPLY = 2_221_201 * 10**18;
    uint256 private constant PRESALE_MAX = (TOTAL_SUPPLY * 20) / 100;
    uint256 private constant INITIAL_SUPPLY = TOTAL_SUPPLY - PRESALE_MAX;

    bool public presaleActive;
    uint256 public presalePrice;
    uint256 public presaleTotalMinted;
    uint256 public presaleMaxPerWallet = 10_000 * 10**18;
    address public MarketingAddress;

    mapping(address => uint256) private presaleMinted;

    constructor()
        ERC20("Doomer Dao Coin", "DOOM")
        ERC20Permit("Doomer Dao Coin")
    {
        _mint(msg.sender, INITIAL_SUPPLY);
        MarketingAddress = msg.sender;
    }

    function activatePresale(uint256 price) external onlyOwner {
        require(!presaleActive, "Presale is already active");
        presaleActive = true;
        presalePrice = price;
    }

    function deactivatePresale() external onlyOwner {
        require(presaleActive, "Presale is not active");
        presaleActive = false;
    }

    function buyPresaleTokens(uint256 amount) external payable {
        require(presaleActive, "Presale is not active");
        require(
            presaleTotalMinted + amount <= PRESALE_MAX,
            "Presale limit exceeded"
        );
        require(
            presaleMinted[msg.sender] + amount <= presaleMaxPerWallet,
            "Max token Per Wallet Limit Exceeded"
        );
        require(
            msg.value >= ((presalePrice * amount) / 1000000000000000000),
            "Incorrect payment amount"
        );

        _mint(msg.sender, amount);
        presaleTotalMinted += amount;
        presaleMinted[msg.sender] += amount;
    }

    function mintUnsoldTokens() external onlyOwner {
        uint256 unsoldTokens = PRESALE_MAX - presaleTotalMinted;
        _mint(msg.sender, unsoldTokens);
        presaleTotalMinted += unsoldTokens;
    }

    function presaleMintedTokens(address account)
        external
        view
        returns (uint256)
    {
        return presaleMinted[account];
    }

    function SetMarketingAddress(address newMarketingAddress)
        external
        onlyOwner
    {
        MarketingAddress = newMarketingAddress;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 taxAmount = amount / 100; // 1% tax
        uint256 transferAmount = amount - taxAmount;
        _transfer(msg.sender, recipient, transferAmount);
        _transfer(msg.sender, MarketingAddress, taxAmount); // Send the tax amount to the marketing address
        return true;
    }

    function withdraw() external payable onlyOwner nonReentrant {
        require(address(this).balance > 0, "Contract balance is zero");
        payable(owner()).transfer(address(this).balance);
    }
}