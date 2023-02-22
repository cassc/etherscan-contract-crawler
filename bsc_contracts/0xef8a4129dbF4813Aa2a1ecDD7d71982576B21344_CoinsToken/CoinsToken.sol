/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinsToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    uint256 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 5000000 * (10**decimals);

    mapping(address => uint256) public balances;

    address payable public owner;
    mapping(address => bool) public admins;

    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public tokenPrice;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event TokenPurchased(address indexed purchaser, uint256 value);

    constructor() {
        name = "Coins";
        symbol = "XXX";
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply;
        owner = payable(msg.sender);
        admins[msg.sender] = true;
        tokenPrice = 0.025 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "CoinsToken: Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "CoinsToken: Only admins can call this function.");
        _;
    }

    modifier saleStarted() {
        require(preSaleStartTime != 0, "CoinsToken: Sale has not started yet.");
        require(block.timestamp >= preSaleStartTime, "CoinsToken: Sale has not started yet.");
        _;
    }

    modifier saleEnded() {
        require(preSaleEndTime != 0, "CoinsToken: Sale has not ended yet.");
        require(block.timestamp > preSaleEndTime, "CoinsToken: Sale is still ongoing.");
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "CoinsToken: New owner cannot be zero address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    function startSale(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(preSaleStartTime == 0, "CoinsToken: Sale has already started.");
        require(_startTime < _endTime, "CoinsToken: Invalid sale period.");

        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    function buyTokens() external payable saleStarted saleEnded {
        uint256 tokensToBuy = msg.value / tokenPrice;
        require(tokensToBuy > 0, "CoinsToken: Insufficient amount sent to purchase tokens.");
        require(balances[owner] >= tokensToBuy, "CoinsToken: Insufficient token balance.");

        balances[owner] -= tokensToBuy;
        balances[msg.sender] += tokensToBuy;

        emit TokenPurchased(msg.sender, tokensToBuy);
    }

    function withdrawFunds() external onlyAdmin {
        require(address(this).balance > 0, "CoinsToken: Insufficient contract balance.");

        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "CoinsToken: Failed to transfer funds.");
    }
}