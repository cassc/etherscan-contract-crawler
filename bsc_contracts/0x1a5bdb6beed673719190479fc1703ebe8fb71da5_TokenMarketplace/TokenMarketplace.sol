/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

contract TokenMarketplace {
    address public tokenAddress;
    uint256 public tokenPrice;
    address payable public admin;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public balanceOf;
    mapping(address => bool) public sellerAccounts;

    event TokensPurchased(address indexed buyer, address indexed seller, uint256 amount);
    event TokenPriceSet(uint256 newPrice);
    event NewSeller(address indexed seller, bool isSeller);
    event TokensApproved(address indexed seller, uint256 numberOfTokens);

    constructor(address _tokenAddress, uint256 _tokenPrice, uint256 _totalSupply) {
        admin = payable(msg.sender);
        tokenAddress = _tokenAddress;
        tokenPrice = _tokenPrice;
        totalSupply = _totalSupply;
        balanceOf[msg.sender][msg.sender] = _totalSupply;
        sellerAccounts[msg.sender] = true;
    }

    function buyTokens(address _seller, uint256 _numberOfTokens) public payable {
        require(msg.value == _numberOfTokens * tokenPrice, "Incorrect amount of ETH sent");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(_seller) >= _numberOfTokens, "Insufficient tokens available for sale");
        require(token.transferFrom(_seller, msg.sender, _numberOfTokens), "Token transfer failed");
        balanceOf[msg.sender][_seller] += _numberOfTokens;
        emit TokensPurchased(msg.sender, _seller, _numberOfTokens);
    }

    function approveTokens(address _seller, uint256 _numberOfTokens) public {
        IERC20 token = IERC20(tokenAddress);
        require(token.approve(address(this), _numberOfTokens), "Token approval failed");
        emit TokensApproved(_seller, _numberOfTokens);
    }

    function withdraw() public {
        require(msg.sender == admin, "Only admin can withdraw funds");
        admin.transfer(address(this).balance);
    }

    function setPrice(uint256 _newPrice) public {
        require(msg.sender == admin, "Only admin can set price");
        require(_newPrice > 0, "Price cannot be zero");
        tokenPrice = _newPrice;
        emit TokenPriceSet(_newPrice);
    }

    function supply() public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.totalSupply();
    }

    function addSeller(address _seller) public {
        require(msg.sender == admin, "Only admin can add sellers");
        sellerAccounts[_seller] = true;
        balanceOf[_seller][_seller] = totalSupply / 10;
        emit NewSeller(_seller, true);
    }

    function removeSeller(address _seller) public {
        require(msg.sender == admin, "Only admin can remove sellers");
        sellerAccounts[_seller] = false;
        emit NewSeller(_seller, false);
    }

    function isSeller(address _seller) public view returns (bool) {
        return sellerAccounts[_seller];
    }
}