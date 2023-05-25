/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EcoCoin {
    string public name = "EcoCoin";
    string public symbol = "EC";
    uint256 public totalSupply = 1000000 * 10**18;
    uint8 public decimals = 18;
    
    address public owner;
    address public marketingWallet;
    
    uint256 public marketingFeePercentage = 15;
    uint256 public liquidityFeePercentage = 2;
    
    uint256 public liquidityBalance; // Variable zum Verfolgen des Liquiditätssaldos
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        owner = msg.sender;
        marketingWallet = 0xe9F342A80148fdA8b2E96474A46DD587f023c3E5; // Deine Marketing-Wallet-Adresse hier einfügen
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        // Aktualisiere den Liquiditätssaldo während des Transfers
        if (_from == address(this)) {
            liquidityBalance -= _value;
        } else if (_to == address(this)) {
            liquidityBalance += _value;
        }
        
        emit Transfer(_from, _to, _value);
    }
    
    function mint(address _to, uint256 _amount) internal {
        require(msg.sender == owner, "Only the owner can mint tokens");
        
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        
        emit Transfer(address(0), _to, _amount);
    }
    
    function changeName(string memory _newName) public {
        require(msg.sender == owner, "Only the owner can change the name");
        name = _newName;
    }
    
    function changeSymbol(string memory _newSymbol) public {
        require(msg.sender == owner, "Only the owner can change the symbol");
        symbol = _newSymbol;
    }
    
    function changeMarketingFee(uint256 _newMarketingFeePercentage) public {
        require(msg.sender == owner, "Only the owner can change the marketing fee");
        marketingFeePercentage = _newMarketingFeePercentage;
    }
    
    function changeLiquidityFee(uint256 _newLiquidityFeePercentage) public {
        require(msg.sender == owner, "Only the owner can change the liquidity fee");
        liquidityFeePercentage = _newLiquidityFeePercentage;
    }
    
    function changeMarketingWallet(address _newMarketingWallet) public {
        require(msg.sender == owner, "Only the owner can change the marketing wallet");
        marketingWallet = _newMarketingWallet;
    }
    
    function retrieveRemainingLiquidity() public {
        require(msg.sender == owner, "Only the owner can retrieve remaining liquidity");
        require(liquidityBalance > 0, "No remaining liquidity");
        
        _transfer(address(this), owner, liquidityBalance);
        liquidityBalance = 0;
    }
}