/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GimpCoin is IERC20 {
    string public constant name = "GimpCoin";
    string public constant symbol = "GIMP";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply = 99000000000 * (10 ** uint256(decimals));
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner == msg.sender, "Not the contract owner");
        _;
    }

   constructor() {
    _totalSupply = 99000000000 * (10 ** uint256(decimals)); // 99,000,000,000 tokens with 18 decimals

    // Distributing the tokens to the provided addresses
    _balances[0x33c13A1ea27202566f5eCf078Db999d1Ce367e9c] = _totalSupply * 65 / 100;
    _balances[0x373FdC873fCC3a06b2750C3B233B21fB3c6c01E4] = _totalSupply * 5 / 100;
    _balances[0x04FC4d25DF56b9fee30cf990815D8E83Ff129989] = _totalSupply * 5 / 100;
    _balances[0xd7F5C30Eb3Ec7e0FA5ba1727Dc0a97bB7663D644] = _totalSupply * 5 / 100;
    _balances[0x7E65cB5F35bB17b56dd1824b3510aD76450a437A] = _totalSupply * 5 / 100;
    _balances[0x347049eCc2388843818467c1B5BccfCbc53CE339] = _totalSupply * 5 / 100;
    _balances[0xd06c0f3Ea81Be5c39058898223565acE188134bF] = _totalSupply * 5 / 100;
    _balances[0xE2bFD82E6d17589d08c519D978D3847b2e1F7879] = _totalSupply * 5 / 100;

    emit Transfer(address(0), 0x33c13A1ea27202566f5eCf078Db999d1Ce367e9c, _totalSupply * 65 / 100);
    // ... repeat for the other addresses
}

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
}