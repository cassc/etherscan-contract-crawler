// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GumBoy is ERC20, Ownable {
    bool _claimIsActive = false;
    uint16 _claimCount = 0;
    uint16 _claimCountMax = 500;
    uint256 _claimAmount = 50_000_000_000 * 10 ** decimals();
    mapping (address => bool) _claimedWallets;

    bool _preSaleIsActive = true;
    uint256 _etherAmountMin = 0.04 ether;
    uint256 _etherAmountMax = 1 ether;
    uint256 _tokenPrice = 1_250_000_000_000;
    uint256 public _sellAmount = 0;
    uint256 _sellAmountMax = 100_000_000_000_000 * 10 ** decimals();

    constructor() ERC20("GumBoy", "GumBoy") {
        _mint(address(this), 500_000_000_000_000 * 10 ** decimals());
        _transfer(address(this), msg.sender, 350_000_000_000_000 * 10 ** decimals());
    }

    function claim() external {
        require(_claimIsActive, "Claim is not active");
        require(_claimCount + 1 <= _claimCountMax, "Max amount of claims reached");
        require(!_claimedWallets[msg.sender], "Tokens were already sent to this wallet");

        _transfer(address(this), msg.sender, _claimAmount);
        _claimCount += 1;
        _claimedWallets[msg.sender] = true;
    }

    function buy() external payable {
        require(_preSaleIsActive, "Pre-sale is not active");
        require(msg.value >= _etherAmountMin && msg.value <= _etherAmountMax, "Ether value sent is not correct (must be between 0.04 and 1)");

        uint256 amount = msg.value * _tokenPrice;
        require(_sellAmount + amount <= _sellAmountMax, "Purchase would exeed available amount of tokens for pre-sale");

        _transfer(address(this), msg.sender, amount);
        _sellAmount += amount;
    }

    function enableClaim() external onlyOwner {
        _claimIsActive = true;
    }

    function withdrowEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrowTokens() external onlyOwner {
        _claimIsActive = false;
        _preSaleIsActive = false;
        _transfer(address(this), owner(), balanceOf(address(this)));
    }
}