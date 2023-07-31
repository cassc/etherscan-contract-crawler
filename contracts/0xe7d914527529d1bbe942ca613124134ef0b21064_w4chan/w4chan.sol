/**
 *Submitted for verification at Etherscan.io on 2023-07-08
*/

// 4% marketing Wallet
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract w4chan {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private contractOwner;
    address private marketingWallet;

    uint256 private constant MARKETING_SUPPLY_PERCENTAGE = 4;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensBurned(address indexed burner, uint256 value);
    event ContractRenounced(address indexed previousOwner);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address _marketingWallet
    ) {
        require(_totalSupply > 0, "Total supply must be greater than zero");
        require(_marketingWallet != address(0), "Invalid marketing wallet address");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        marketingWallet = _marketingWallet;

        // Calcular el porcentaje de suministro para la cartera de marketing
        uint256 marketingSupply = (_totalSupply * MARKETING_SUPPLY_PERCENTAGE) / 100;
        require(marketingSupply > 0, "Marketing supply must be greater than zero");
        require(marketingSupply < _totalSupply, "Marketing supply must be less than total supply");

        balanceOf[_marketingWallet] = marketingSupply;
        balanceOf[msg.sender] = _totalSupply - marketingSupply;

        emit Transfer(address(0), _marketingWallet, marketingSupply);
        emit Transfer(address(0), msg.sender, _totalSupply - marketingSupply);

        contractOwner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient");
        require(_to != marketingWallet, "Invalid recipient"); 
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid spender");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        require(_to != address(0), "Invalid recipient");
        require(_to != marketingWallet, "Invalid recipient"); 
        allowance[_from][msg.sender] -= _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(msg.sender != marketingWallet, "Cannot burn tokens from marketing wallet");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit TokensBurned(msg.sender, _value);
        return true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");

        emit OwnershipTransferred(contractOwner, _newOwner);
        contractOwner = _newOwner;
    }

    function renounceContractOwnership() public onlyOwner {
        require(marketingWallet != address(0), "Marketing wallet not set");
        require(contractOwner != marketingWallet, "Cannot renounce contract ownership while using marketing wallet");

        emit ContractRenounced(contractOwner);
        contractOwner = address(0);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid recipient");
        require(_to != marketingWallet, "Invalid recipient");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(balanceOf[_to] + _value >= balanceOf[_to], "Integer overflow"); // Check for integer overflow

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
    }
}