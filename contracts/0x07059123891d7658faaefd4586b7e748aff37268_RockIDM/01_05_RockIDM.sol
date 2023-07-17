/*
 * SPDX-License-Identifier: MIT
 *
 * @title RockIDM - Rock: It Doesn't Matter!
 *
 * Total supply -> 888,888,888,888,888 (The number 8 is believed to bring wealth and prosperity)
 * No new tokens can be minted ever.
 * 0.01% of any trade or transfer is burnt forever
 * 0.01% of any trade or transfer is for growth
 */
pragma solidity ^0.8.19;

import "./oz_regular/token/ERC20/ERC20.sol";
import "./oz_regular/token/ERC20/IERC20.sol";
import "./oz_regular/token/ERC20/extensions/IERC20Metadata.sol";
import "./oz_regular/utils/Context.sol";

contract RockIDM is Context, IERC20, IERC20Metadata {
    address private _deployer;
    address public uniswapV2Pair;
    bool public limited;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    string private _name = "Rock: It Doesnt Matter!";
    string private _symbol = "RockIDM";
    uint256 private _fee = 1; // 0.01%
    uint256 private _totalSupply;
    uint256 private constant _BIPS = 10000;
    uint256 public maxHoldingAmount = 8_888_888_888_888_000_000_000_000_000_000;

    constructor() {
        _deployer = msg.sender;
        _totalSupply += 888_888_888_888_888_000_000_000_000_000_000;
        unchecked {
            _balances[_deployer] += _totalSupply;
        }
        emit Transfer(address(0), _deployer, _totalSupply);
    }

    receive() external payable {}

    fallback() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "BYNC: allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setRule(bool _limited, address _uniswapV2Pair) external {
        require(msg.sender == _deployer, "Unauthorized");
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) private view {
        if (uniswapV2Pair == address(0)) {
            require(from == _deployer || to == _deployer, "Patience!");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BYNC: transfer from the zero");
        require(to != address(0), "BYNC: transfer to the zero");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "BYNC: transfer amount exceeds balance");
        uint256 fee = (amount * _fee) / _BIPS;
        uint256 tAmt = (amount - 2 * fee);
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += tAmt;
            _balances[_deployer] += fee;
        }

        emit Transfer(from, to, tAmt);
        emit Transfer(from, _deployer, fee);
        emit Transfer(from, address(0), fee);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BYNC: approve from the zero");
        require(spender != address(0), "BYNC: approve to the zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "BYNC: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function withdraw() external payable {
        uint256 amount = address(this).balance;
        require(amount > 0, "BYNC: Nothing to withdraw");

        (bool sent, ) = _deployer.call{value: amount}("");
        require(sent, "BYNC: Failed to send Ether");
    }
}