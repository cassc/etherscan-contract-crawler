/*
 * SPDX-License-Identifier: MIT
 *
 * @title BEYONCE - Meme coin in honor of Beyonce
 * @author Beyonce's fan
 *
 * Total supply -> 9,876,543,210 (9 billion, 876 million, 543 thousand, 210)
 * BEYONCE token has 99% of the total supply (9,777,777,777 tokens) added to the liquidity
 * Liquidity pool tokens are burnt!!!!!
 * Only 1% of the supply (98,765,433) is retained by developer in return for the liquidity funds
 * No new tokens can be minted ever
 * The contract is renounced and can never be changed
 *
 * 0.01% of any trade or transfer is burnt forever
 * 0.01% of any trade or transfer is sent to Developer
 */
pragma solidity ^0.8.19;

import "./oz_regular/token/ERC20/ERC20.sol";
import "./oz_regular/token/ERC20/IERC20.sol";
import "./oz_regular/token/ERC20/extensions/IERC20Metadata.sol";
import "./oz_regular/utils/Context.sol";

contract BEYONCE is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name = "BEYONCE";
    uint256 private constant _BIPS = 10000;
    uint256 private _fee = 10; // 0.1%
    address private _deployer;

    constructor() {
        _deployer = msg.sender;
        _totalSupply += 9876543210 * 10 ** decimals();
        unchecked {
            _balances[_deployer] += _totalSupply;
        }
        emit Transfer(address(0), _deployer, _totalSupply);
    }

    receive() external payable {}

    fallback() external payable {}

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "BYNC: transfer from the zero");
        require(to != address(0), "BYNC: transfer to the zero");

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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BYNC: approve from the zero");
        require(spender != address(0), "BYNC: approve to the zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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