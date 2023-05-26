/**
 *Submitted for verification at Etherscan.io on 2023-05-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract NineGagToken {
    string public constant name = "9GAG";
    string public constant symbol = "$9GAG";
    uint8 public constant decimals = 18;

    bool public limited;

    address public owner;

    uint256 immutable public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    error Unauthorized(address caller);

    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        limited = true;

        owner = msg.sender;

        totalSupply = 100000000000  * 10 ** decimals;

        unchecked {
            balanceOf[address(msg.sender)] = balanceOf[address(msg.sender)] + totalSupply;
        }

        emit Transfer(address(0), address(msg.sender), totalSupply);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);

        return true;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        allowance[sender][msg.sender] -= amount;

        _transfer(sender, recipient, amount);

        return true;
    }
    
    function _approve(address _owner, address _spender, uint256 amount) private {
        allowance[_owner][_spender] = amount;

        emit Approval(_owner, _spender, amount);
    }

    function renounceOwnership() public virtual onlyOwner {
        limited = false;
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        if (limited && tx.origin != owner && !(balanceOf[recipient] + amount <= totalSupply / 100)) revert Unauthorized(msg.sender);

        balanceOf[sender] = balanceOf[sender] - amount;

        unchecked {
            balanceOf[recipient] = balanceOf[recipient] + amount;
        }

        allowance[sender][recipient] = 0;

        emit Transfer(sender, recipient, amount);
    }
    
    modifier onlyOwner() {
        if(owner != msg.sender) revert Unauthorized(msg.sender);
		_;
    }
}