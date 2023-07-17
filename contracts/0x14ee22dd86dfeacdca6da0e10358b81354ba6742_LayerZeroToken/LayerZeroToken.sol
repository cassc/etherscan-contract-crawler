/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

pragma solidity ^0.8.0;

contract LayerZeroToken {
    string public name = "LayerZero";
    string public symbol = "LayerZero";
    uint256 public totalSupply = 100000000000 * 10**18; // 100 billion tokens with 18 decimal places
    uint8 public decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private allowedSellers;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SellerAllowed(address indexed seller);
    event SellerNotAllowed(address indexed seller);

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyAllowedSeller() {
        require(
            allowedSellers[msg.sender] || msg.sender == owner,
            "You are not allowed to sell tokens"
        );
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowed[from][msg.sender], "Insufficient allowance");

        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function allowSeller(address seller) public onlyOwner {
        allowedSellers[seller] = true;
        emit SellerAllowed(seller);
    }

    function disallowSeller(address seller) public onlyOwner {
        allowedSellers[seller] = false;
        emit SellerNotAllowed(seller);
    }
}