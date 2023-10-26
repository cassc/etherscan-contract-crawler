/**
 *Submitted for verification at Etherscan.io on 2023-10-23
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-11
*/
/**


██████╗░███████╗██████╗░███████╗  ░██████╗░██╗░░██╗░█████╗░░██████╗████████╗
██╔══██╗██╔════╝██╔══██╗██╔════╝  ██╔════╝░██║░░██║██╔══██╗██╔════╝╚══██╔══╝
██████╔╝█████╗░░██████╔╝█████╗░░  ██║░░██╗░███████║██║░░██║╚█████╗░░░░██║░░░
██╔═══╝░██╔══╝░░██╔═══╝░██╔══╝░░  ██║░░╚██╗██╔══██║██║░░██║░╚═══██╗░░░██║░░░
██║░░░░░███████╗██║░░░░░███████╗  ╚██████╔╝██║░░██║╚█████╔╝██████╔╝░░░██║░░░
╚═╝░░░░░╚══════╝╚═╝░░░░░╚══════╝  ░╚═════╝░╚═╝░░╚═╝░╚════╝░╚═════╝░░░░╚═╝░░░

Website: https://pepeghost.club/
Telegram: https://t.me/pepeghost_eth
Twitter: https://twitter.com/pepeghost_eth
**/
// SPDX-License-Identifier: NONE

pragma solidity ^0.8.19;

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract GHOST is IERC20 {
    using SafeMath for uint256;

    string private _name = "PEPE GHOST";
    string private _symbol = "GHOST";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1000000000000000000 * (1**uint256(_decimals));

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _owner;
    mapping(address => bool) private _excludedFees;
    mapping(address => bool) private _excludedRewards;

    uint256 private constant _taxRate = 0; // 1% tax rate
    address private constant _marketingWallet = 0x0242Ec8f22E0C2998B2A9b7b880877d84FCcB116;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedAmount) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedAmount));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedAmount) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedAmount));
        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        _owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0x0000000000000000000000000000000000000000);
    }

    function Owner() public view returns (address) {
        return _owner;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        uint256 taxAmount = amount.mul(_taxRate).div(100);
        uint256 transferAmount = amount.sub(taxAmount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);
        _balances[_marketingWallet] = _balances[_marketingWallet].add(taxAmount);

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _marketingWallet, taxAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}