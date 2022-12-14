// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenFinal is IERC20, AccessControlEnumerable, Ownable{
    using SafeMath for uint256;

    bytes32 public constant BLACKLIST_ROLE = keccak256("BLACKLIST_ROLE");
    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private UNISWAP_PAIR_ADDRESS;

    uint256 private constant _tTotal = 1000000000 * 10**18;

    string private _name = "Fuck Bots";
    string private _symbol = "FBOTS";
    uint8 private _decimals = 18;

    constructor(
    ) 
    Ownable() 
    {
        _balances[_msgSender()] = _tTotal;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit Transfer(address(0), _msgSender(),_tTotal);
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


    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function setPair(address pair) public onlyOwner {
        UNISWAP_PAIR_ADDRESS = pair;
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!hasRole(BLACKLIST_ROLE, from), "ERC20: transfer from a Blacklisted address");
        require(!hasRole(BLACKLIST_ROLE, to), "ERC20: transfer to a Blacklisted address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        if(_msgSender() == UNISWAP_PAIR_ADDRESS || to == UNISWAP_PAIR_ADDRESS) { // 5% fee if traded on uniswap
            uint256 fee = 5;
            uint256 feeAmount = amount.mul(fee).div(100);
            amount -= feeAmount;
            _balances[owner()] += feeAmount;
            emit Transfer(from, owner(), feeAmount);
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        require(!hasRole(BLACKLIST_ROLE, account), "AccessControl: cannot renounce Blacklist role from self");

        _revokeRole(role, account);
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}