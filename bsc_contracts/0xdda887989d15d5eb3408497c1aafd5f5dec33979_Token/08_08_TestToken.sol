//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract TestToken 
{    
    address private _owner;  
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    bool public initialized;

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    function constructor1() public
    {
        address adm;
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
        require(msg.sender == adm, "Only proxy admin can init contract");
        initialized = true;
    }

    function owner() view external returns (address)
    {
        return _owner;
    }
    function totalSupply() view external returns (uint256)
    {
        return _totalSupply;
    }
    function name() view external returns (string memory)
    {
        return _name;
    }
    function symbol() view external returns (string memory)
    {
        return _symbol;
    }
    function decimals() view external returns (uint8)
    {
        return _decimals;
    }
    function balanceOf(address tokenOwner) public view returns (uint256) 
    {
        return _balances[tokenOwner];
    }
}