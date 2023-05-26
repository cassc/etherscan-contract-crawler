// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CyanideToken is ERC20, Ownable {
    mapping (address => bool) private blacklist;
    mapping (address => bool) private whitelist;
    mapping (address => uint256) private buyTimestamp;
    uint256 private maxWalletAmount;
    uint256 private maxBuyAmount;
    uint256 private sellDelayDuration;
    uint256 private contractLaunchTime;
    bool private whitelistEnabled;

    constructor() ERC20("Cyanide", "CHX") {
        _mint(msg.sender, 21000000069420 * 10 ** decimals());
        maxWalletAmount = totalSupply() / 400;
        maxBuyAmount = maxWalletAmount;
        sellDelayDuration = 1 hours;
        contractLaunchTime = block.timestamp;
        whitelistEnabled = false;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!blacklist[msg.sender], "Your account has been blacklisted");
        require(!blacklist[recipient], "Recipient's account has been blacklisted");
        require(!whitelistEnabled || whitelist[msg.sender], "Your account is not whitelisted");
        require(balanceOf(msg.sender) - amount >= maxWalletAmount, "Exceeds maximum wallet amount");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(!blacklist[sender], "Sender's account has been blacklisted");
        require(!blacklist[recipient], "Recipient's account has been blacklisted");
        require(!whitelistEnabled || whitelist[sender], "Sender's account is not whitelisted");
        require(balanceOf(sender) - amount >= maxWalletAmount, "Exceeds maximum wallet amount");
        _approve(sender, msg.sender, allowance(sender, msg.sender) - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function addToBlacklist(address account) public onlyOwner {
        blacklist[account] = true;
    }

    function removeFromBlacklist(address account) public onlyOwner {
        blacklist[account] = false;
    }

    function addToWhitelist(address account) public onlyOwner {
        whitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyOwner {
        whitelist[account] = false;
    }

    function enableWhitelist() public onlyOwner {
        whitelistEnabled = true;
    }

    function disableWhitelist() public onlyOwner {
        whitelistEnabled = false;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnBlacklistedTokens() public {
        require(blacklist[msg.sender], "You are not blacklisted");
        uint256 amount = balanceOf(msg.sender);
        _burn(msg.sender, amount);
        _burn(address(this), amount);
    }

    function setMaxWalletAmount(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        maxWalletAmount = amount;
    }

    function setMaxBuyAmount(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        maxBuyAmount = amount;
    }

    function setSellDelayDuration(uint256 duration) public onlyOwner {
        require(duration > 0, "Duration must be greater than zero");
        sellDelayDuration = duration;
    }

    function buy() public payable {
        require(msg.value > 0, "Amount sent must be greater than zero");
        uint256 amount = msg.value * 10 ** decimals() / price();
        require(amount <= maxBuyAmount, "Exceeds maximum buy amount");
        require(balanceOf(address(this)) >= amount, "Insufficient liquidity");

        if (block.timestamp <= contractLaunchTime + 48 hours) {
            require(buyTimestamp[msg.sender] + sellDelayDuration <= block.timestamp, "You need to wait before selling");
        }

        _transfer(address(this), msg.sender, amount);
        buyTimestamp[msg.sender] = block.timestamp;
    }

    function price() public view returns (uint256) {
        return balanceOf(address(this)) / address(this).balance;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    modifier onlyOwner() override {
        require(msg.sender == owner(), "Only owner can perform this action");
        _;
    }
}