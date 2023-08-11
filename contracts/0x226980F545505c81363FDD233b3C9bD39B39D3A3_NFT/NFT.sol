/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

// SPDX-License-Identifier: MIT
// https://twitter.com/NFTT_COIN

pragma solidity ^0.8.0;

contract NFT {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public taxAddress;
    uint256 public taxRate;
    address private owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address to);

    constructor() {
        name = "BaycMaycCryptoPunksAzukiDoodlesClonexMoonBirdsDigiDaigakuBeanzLetsWalk3landersMeebitsVeeFriendsPudgysMfersCaptainsCoolcatsAndAllNFTs";
        symbol = "NFT";
        decimals = 18;
        totalSupply = 10000000000000 * 10**uint256(decimals);
        taxAddress = 0x3685cDd372f67C8D8eb513431c6fd9671dF8423B;
        taxRate = 5;
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        uint256 taxAmount = (value * taxRate) / 100;
        uint256 taxedValue = value - taxAmount;

        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[taxAddress] += taxAmount;
        balanceOf[to] += taxedValue;

        emit Transfer(msg.sender, to, taxedValue);
        emit Transfer(msg.sender, taxAddress, taxAmount);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function SetTaxRate(uint256 value) public onlyOwner {
        require(value != 0, "Invalid address");
        taxRate = value;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 taxAmount = (value * taxRate) / 100;
        uint256 taxedValue = value - taxAmount;

        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[taxAddress] += taxAmount;
        balanceOf[to] += taxedValue;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, taxedValue);
        emit Transfer(from, taxAddress, taxAmount);
        return true;
    }
    
    function isOwner(address account) private view returns (bool) {
        return account == owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }
}