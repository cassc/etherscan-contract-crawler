/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

//           web: Https://pauly0xpepe.nicepage.io

//       twitter: https://twitter.com/pauly0xpepe

//.     telegram:  https://t.me/Px0Pepe

//.       @[email protected]
//.      (----)
//.     ( >__< )
//.     ^^ ~~ ^^






// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Px0Pepe {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address private contractOwner;
    address public cexWallet;

    uint256 public buyTax = 2;  // Buy tax set to 2%
    uint256 public sellTax = 2; // Sell tax set to 2%

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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
        address _cexWallet
    ) {
        require(_totalSupply > 0, "Total supply must be greater than zero");
        require(_cexWallet != address(0), "CEX wallet address can't be the zero address");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        cexWallet = _cexWallet;

        uint256 cexTokens = _totalSupply * 4 / 100;

        balanceOf[msg.sender] = _totalSupply - cexTokens;
        balanceOf[cexWallet] = cexTokens;

        emit Transfer(address(0), msg.sender, balanceOf[msg.sender]);
        emit Transfer(address(0), cexWallet, cexTokens);

        contractOwner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient");

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

        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        return true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");

        emit OwnershipTransferred(contractOwner, _newOwner);
        contractOwner = _newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit ContractRenounced(contractOwner);
        contractOwner = address(0);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid recipient");
        require(balanceOf[_from] >= _value, "Insufficient balance");

        uint256 tax = (_to == cexWallet ? sellTax : buyTax) * _value / 100;
        uint256 taxedValue = _value - tax;

        balanceOf[_from] -= _value;
        balanceOf[_to] += taxedValue;
        balanceOf[contractOwner] += tax;

        emit Transfer(_from, _to, taxedValue);
        emit Transfer(_from, contractOwner, tax);
    }
}