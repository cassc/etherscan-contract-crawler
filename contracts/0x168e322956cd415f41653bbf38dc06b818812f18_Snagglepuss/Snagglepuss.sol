/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// This is the interface for an ERC20 token, a type of cryptocurrency.
interface IERC20 {
    // Returns the total number of tokens that exist.
    function totalSupply() external view returns (uint256);

    // Returns the number of tokens owned by a specific account.
    function balanceOf(address account) external view returns (uint256);

    // Transfers a specified amount of tokens from the sender's account to the recipient's account.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the amount of tokens that the spender is allowed to spend on behalf of the owner.
    function allowance(address owner, address spender) external view returns (uint256);

    // Approves the spender to transfer a specified amount of tokens on behalf of the owner.
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers a specified amount of tokens from the sender's account to the recipient's account on behalf of the owner.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Increases the amount of tokens that the spender is allowed to spend on behalf of the owner.
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    // Decreases the amount of tokens that the spender is allowed to spend on behalf of the owner.
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    // Burns a specified amount of tokens from the sender's account, reducing the total supply.
    function burn(uint256 amount) external returns (bool);

    // Burns a specified amount of tokens from a specific account, reducing the total supply.
    function burnFrom(address account, uint256 amount) external returns (bool);

    // Event emitted when tokens are transferred from one account to another.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Event emitted when the allowance for a spender on an owner's tokens is set.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Event emitted when tokens are burned, reducing the total supply.
    event Burn(address indexed from, uint256 value);
}

// This contract provides basic ownership functionality.
contract Ownable {
    // Address of the contract owner.
    address private owner;

    // Event emitted when ownership of the contract is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Sets the deployer of the contract as the initial owner.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    // Returns the address of the contract owner.
    function getOwner() public view returns (address) {
        return owner;
    }

    // Modifier that restricts access to only the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Hey, only the owner can call this function!");
        _;
    }

    // Transfers ownership of the contract to a new address.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Hey, you can't transfer ownership to the zero address!");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Renounces ownership of the contract.
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// Snagglepuss contract 
contract Snagglepuss is IERC20, Ownable {
    // Token name
    string public constant name = "Snagglepuss";

    // Token symbol
    string public constant symbol = "SNG";

    // Token decimals
    uint8 public constant decimals = 8;

    // Total & circulation supply
    uint256 public totalSupply = 100_000_000 * (10**uint256(decimals));
    uint256 public circulationSupply = totalSupply;

    // Burn address
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Mapping to track token balances of each account
    mapping(address => uint256) private balances;

    // Mapping to track token allowances for each account and spender
    mapping(address => mapping(address => uint256)) private allowances;

    // Sets the total supply of tokens and assigns them to the contract deployer
    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }


    // Returns the token balance of a specified account
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    // Transfers a specified amount of tokens to the recipient
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(amount <= balances[msg.sender], "Hey, you don't have enough tokens!");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

         if (recipient == burnAddress) {
         circulationSupply -= amount;
         }


        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    // Transfers a specified amount of tokens from the sender to the recipient
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(amount <= balances[sender], "Hey, the sender doesn't have enough tokens!");
        require(amount <= allowances[sender][msg.sender], "Hey, you are not allowed to spend that much!");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    // Approves a spender to transfer a specified amount of tokens on behalf of the owner
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Returns the allowance for a spender on a specific owner's tokens
    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    // Increases the allowance for a spender
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        allowances[msg.sender][spender] += addedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    // Decreases the allowance for a spender
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
             uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Hey, you can't decrease the allowance below zero!");

        allowances[msg.sender][spender] = currentAllowance - subtractedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

// Burns a specified amount of tokens from the sender's account
    function burn(uint256 amount) external returns (bool) {
    require(amount > 0, "Hey, the amount must be greater than zero!");
    require(amount <= balances[msg.sender], "Hey, you don't have enough tokens to burn!");

    balances[msg.sender] -= amount;
    totalSupply -= amount;
    circulationSupply -= amount;


    emit Transfer(msg.sender, burnAddress, amount);
    emit Burn(msg.sender, amount);

    return true;
}




    // Burns a specified amount of tokens from a specific account, reducing the total supply.
    function burnFrom(address account, uint256 amount) external override returns (bool) {
        require(amount > 0, "Hey, the amount must be greater than zero!");
        require(amount <= balances[account], "Hey, the account doesn't have enough tokens to burn!");
        require(amount <= allowances[account][msg.sender], "Hey, you are not allowed to burn that many tokens!");

        balances[account] -= amount;
        circulationSupply -= amount;
        allowances[account][msg.sender] -= amount;

        emit Transfer(account, burnAddress, amount);
        emit Burn(account, amount);

        return true;
    }

    // Returns the Twitter link for the Project
    function getTwitterLink() external pure returns (string memory) {
        return "https://www.twitter.com/snagglepusssng";
    }
}