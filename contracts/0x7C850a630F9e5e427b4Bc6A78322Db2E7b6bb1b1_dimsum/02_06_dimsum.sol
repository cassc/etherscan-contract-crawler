/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/
/*
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠛⠛⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣤⣄⣀⠀⠀⠚⠿⣿⣿⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⣋⡙⠛⠳⢦⣄⠀⠉⠻⢿⣿⢿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⣿⡿⢻⡿⠀⠀⠈⠙⠳⢦⡀⠈⠉⠂⠀⠀⠉⠳⢿⡿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⠋⠀⣿⠁⠀⠀⠀⢢⡀⠀⠙⢶⡀⠀⠀⢠⡀⠀⠀⠙⣾⣿⣿⣿⣿
⣿⣿⣿⡿⠁⠀⠀⡏⠀⢠⡇⠀⠈⣷⡀⠀⠀⠹⣆⠀⠀⠻⣆⠀⠀⠈⣿⣿⣿⣿
⡿⣽⡿⠁⠀⠀⠘⡇⠀⠘⣧⠀⠀⠹⣷⡀⠀⠀⠸⡆⠀⠀⠙⢷⡀⠀⠘⣿⣟⣿
⣽⣿⠇⠀⠀⠀⠠⣇⠀⠀⣿⠀⠀⠀⢻⣧⠀⠀⠀⢻⡀⠀⠀⠈⠻⠀⠀⢹⣿⣟
⣿⣿⠀⠀⠀⠀⠀⢻⠀⠀⢹⡀⠀⠀⠈⢿⣆⠀⠀⠘⠃⠀⠀⠀⠀⠀⠀⢸⣿⣿
⣿⣿⡄⠀⠀⠀⠀⠀⠁⠀⠈⡇⠀⠀⠀⠈⢿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿
⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠱⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿
⣿⣿⣿⣿⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣰⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣶⣤⣄⣀⣀⣀⣀⣀⣤⣤⣤⣶⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣷⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿
*/
/**
Twitter: https://twitter.com/dimsumerc20
**/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = senderBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        uint256 currentBalance = _balances[account];
        require(currentBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = currentBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= amount, "ERC20: spend amount exceeds allowance");
        _approve(owner, spender, currentAllowance - amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _setOwner(address(0));
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract dimsum is ERC20, Ownable {
    constructor() ERC20("DIMSUM", "DIMSUM") {
        _mint(_msgSender(), 10000000000 * 10**18);
    }
}
