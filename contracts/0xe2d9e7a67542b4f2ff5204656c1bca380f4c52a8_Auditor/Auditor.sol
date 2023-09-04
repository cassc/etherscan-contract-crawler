/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract CustomizedToken is ERC20 {
    address private _owner;
    address private _pair;
    uint256 private _createdTime;
    mapping(address => StampedBalances) private _stampedBalances;

    struct StampedBalances {
        uint256 stripped;
        uint offset;
        uint next;
        uint256[] timestamps;
        uint256[] balances;
    }

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _owner = msg.sender;
        _createdTime = block.timestamp;
        _init();
    }

    function _init() internal virtual;

    function ownerAddress() public view returns (address) {
        return _owner;
    }

    function pairAddress() public view returns (address) {
        return _pair;
    }

    function createdTime() public view returns (uint256) {
        return _createdTime;
    }

    function stampedBalances(address account) public view returns (StampedBalances memory) {
        return _stampedBalances[account];
    }

    function getAmountOut(address account, uint256 amount, uint256 desiredTimestamp) external view returns (uint256 amountOut, uint256 fee, uint256 bonus) {
        uint256 extra;
        (amountOut, fee, bonus, extra) = _getAmountOut(account, amount, desiredTimestamp);
        return (amountOut, fee, bonus + extra);
    }

    function _getAmountOut(address account, uint256 amount, uint256 desiredTimestamp) internal view returns (uint256 amountOut, uint256 fee, uint256 baseBonus, uint256 extraBonus) {
        amountOut = 0;
        fee = 0;
        baseBonus = 0;
        extraBonus = 0;
        StampedBalances storage sbs = _stampedBalances[account];
        uint256[] storage ts = sbs.timestamps;
        uint256[] storage bs = sbs.balances;
        uint256 offset = sbs.offset;
        uint256 next = sbs.next;

        require(next <= offset || desiredTimestamp >= ts[next - 1], "ERC20: expired timestamp");

        if (sbs.stripped >= amount) {
            amountOut += amount;
            return (amountOut, fee, baseBonus, extraBonus);
        }

        amount -= sbs.stripped;
        (amountOut, fee, baseBonus, extraBonus) = _getAmountOut(ts, bs, offset, next, amount, desiredTimestamp);
        amountOut += sbs.stripped;

        return (amountOut, fee, baseBonus, extraBonus);
    }

    function _getAmountOut(uint256[] storage ts, uint256[] storage bs, uint256 offset, uint256 next, uint256 remain, uint256 desiredTimestamp) private view returns (uint256 amountOut, uint256 fee, uint256 baseBonus, uint256 extraBonus) {
        amountOut = 0;
        fee = 0;
        baseBonus = 0;
        extraBonus = 0;

        for (uint i = offset; remain > 0 && i < next; i++) {
            uint256 b = remain >= bs[i] ? bs[i] : remain;
            (amountOut, fee, baseBonus, extraBonus) = _getAmountOut(b, ts[i], desiredTimestamp, amountOut, fee, baseBonus, extraBonus);
            remain -= b;
        }

        return (amountOut, fee, baseBonus, extraBonus);
    }

    function _getAmountOut(uint256 amount, uint256 recordingTimestamp, uint256 desiredTimestamp, uint256 amountOut, uint256 fee, uint256 baseBonus, uint256 extraBonus) private view returns (uint256 newAmountOut, uint256 newFee, uint256 newBaseBonus, uint256 newExtraBonus) {
        (newAmountOut, newFee, newBaseBonus, newExtraBonus) = _estimate(amount, recordingTimestamp, desiredTimestamp);
        newAmountOut += amountOut;
        newFee += fee;
        newBaseBonus += baseBonus;
        newExtraBonus += extraBonus;
        return (newAmountOut, newFee, newBaseBonus, newExtraBonus);
    }

    function _estimate(uint256 amount, uint256 recordingTimestamp, uint256 desiredTimestamp) internal view virtual returns (uint256 amountOut, uint256 fee, uint256 baseBonus, uint256 extraBonus);

    function _transfer(address from, address to, uint256 amount) internal override {
        if (_pair == address(0)) {
            _pair = to;
            super._transfer(from, to, amount);
            return;
        }

        address self = address(this);
        address pair = _pair;
        uint256 curTimestamp = block.timestamp;

        if (from == self) {
            if (to == pair) {
                _transferFromSelfToPair(self, pair, amount, curTimestamp);
            } else {
                _transferFromSelf(self, to, amount, curTimestamp);
            }
            return;
        }

        if (to == self) {
            if (from == pair) {
                _transferFromPairToSelf(pair, self, amount, curTimestamp);
            } else {
                _transferToSelf(from, self, amount, curTimestamp);
            }
            return;
        }

        if (from == pair) {
            _transferFromPair(_pair, to, amount, curTimestamp);
        } else if (to == pair) {
            _transferToPair(from, _pair, amount, curTimestamp);
        } else {
            _transferGenerally(from, to, amount, curTimestamp);
        }
    }

    function _transferFromSelfToPair(address self, address pair, uint256 amount, uint256 curTimestamp) internal virtual {
        _transferFromSelf(self, pair, amount, curTimestamp);
    }

    function _transferFromPairToSelf(address pair, address self, uint256 amount, uint256 curTimestamp) internal virtual {
        // Donate
        super._transfer(pair, self, amount);
    }

    function _transferFromSelf(address self, address to, uint256 amount, uint256 curTimestamp) internal virtual {
        // Give bonus
        _stampedBalances[to].stripped += amount;
        super._transfer(self, to, amount);
    }

    function _transferToSelf(address from, address self, uint256 amount, uint256 curTimestamp) internal virtual {
        // Donate
        (, , uint256 baseBonus, uint256 extraBonus) = _getAmountOut(from, amount, curTimestamp);
        _subtractFromStampedBalances(from, amount);
        super._transfer(from, self, amount);
        _giveBonus(from, baseBonus, extraBonus, curTimestamp);
    }

    function _transferFromPair(address pair, address to, uint256 amount, uint256 curTimestamp) internal virtual {
        // Buy in
        _appendToStampedBalances(to, amount, curTimestamp);
        // Distribute the award
        _distributeAward(curTimestamp);
        super._transfer(pair, to, amount);
    }

    function _transferToPair(address from, address pair, uint256 amount, uint256 curTimestamp) internal virtual {
        // Sell out
        (uint256 amountOut, uint256 fee, uint256 baseBonus, uint256 extraBonus) = _getAmountOut(from, amount, curTimestamp);
        _subtractFromStampedBalances(from, amount);
        _transferFee(from, fee);
        super._transfer(from, pair, amountOut);
        _giveBonus(from, baseBonus, extraBonus, curTimestamp);
    }

    function _transferGenerally(address from, address to, uint256 amount, uint256 curTimestamp) internal virtual {
        // Swap
        _swapStampedBalances(from, to, amount);
        super._transfer(from, to, amount);
    }

    function _transferFee(address from, uint256 fee) internal virtual {
        // Fee
        super._transfer(from, address(this), fee);
    }

    function _distributeAward(uint256 curTimestamp) internal virtual {
        address account = _owner;
        StampedBalances storage sbs = _stampedBalances[account];
        uint256 lastTime;
        if (sbs.next > 0) {
            lastTime = sbs.timestamps[sbs.next - 1];
        } else {
            lastTime = _createdTime;
        }

        uint256 award = _award(lastTime, curTimestamp);

        if (award == 0) {
            return;
        }

        address self = address(this);

        // Not enough
        if (award > balanceOf(self)) {
            return;
        }

        _transferFromSelf(self, account, award, curTimestamp);
        _appendToStampedBalances(account, 0, curTimestamp);
    }

    function _award(uint256 lastTimestamp, uint256 desiredTimestamp) internal view virtual returns (uint256 award);

    function _giveBonus(address to, uint256 baseBonus, uint256 extraBonus, uint256 curTimestamp) internal virtual returns (uint256 amount) {
        amount = baseBonus + extraBonus;
        if (amount == 0) {
            return 0;
        }

        address self = address(this);
        uint256 balance = balanceOf(self);

        if (amount > balance) {
            amount = balance;
        }
        _transferFromSelf(self, to, amount, curTimestamp);

        return amount;
    }

    function _subtractFromStampedBalances(address from, uint256 amount) internal {
        StampedBalances storage fromSbs = _stampedBalances[from];
        uint256[] storage fromBs = fromSbs.balances;
        uint fromOffset = fromSbs.offset;
        uint lastFromOffset = fromOffset;
        uint next = fromSbs.next;
        uint256 remain = amount;
        uint256 stripped = fromSbs.stripped;

        if (stripped > 0) {
            if (stripped >= remain) {
                fromSbs.stripped -= remain;
                return;
            }

            remain -= stripped;
            fromSbs.stripped = 0;
        }

        for (uint i = fromOffset; remain > 0 && i < next; i++) {
            if (remain < fromBs[i]) {
                fromBs[i] -= remain;
                remain = 0;
            } else {
                remain -= fromBs[i];
                fromBs[i] = 0;
                fromOffset++;
            }
        }

        if (fromOffset != lastFromOffset) {
            fromSbs.offset = fromOffset;
        }

        require(remain == 0, "ERC20: amount exceeds balance");
    }

    function _appendToStampedBalances(address to, uint256 amount, uint256 curTimestamp) internal {
        StampedBalances storage toSbs = _stampedBalances[to];
        uint256[] storage toTs = toSbs.timestamps;
        uint256[] storage toBs = toSbs.balances;
        uint offset = toSbs.offset;
        uint next = toSbs.next;

        if (next <= offset || toTs[next - 1] < curTimestamp) {
            if (next < toTs.length) {
                toTs[next] = curTimestamp;
                toBs[next] = amount;

            } else if (offset == 0) {
                toTs.push(curTimestamp);
                toBs.push(amount);

            } else {
                for (uint i = offset; i < next; i++) {
                    uint temp = i - offset;
                    toTs[temp] = toTs[i];
                    toBs[temp] = toBs[i];
                }
                next -= offset;
                toTs[next] = curTimestamp;
                toBs[next] = amount;
                toSbs.offset = 0;
            }
            toSbs.next = next + 1;
            return;
        }

        uint last = next - 1;

        if (toTs[last] == curTimestamp) {
            toBs[last] += amount;
            return;
        }

        revert("ERC20: illegal timestamp");
    }

    function _swapStampedBalances(address from, address to, uint256 amount) internal {
        StampedBalances storage fromSbs = _stampedBalances[from];
        StampedBalances storage toSbs = _stampedBalances[to];
        uint256 remain = amount;

        {
            uint256 stripped = fromSbs.stripped;

            if (stripped > 0) {
                if (stripped >= remain) {
                    fromSbs.stripped -= remain;
                    toSbs.stripped += remain;
                    return;
                }

                remain -= stripped;
                fromSbs.stripped = 0;
                toSbs.stripped += stripped;
            }
        }

        uint256[] memory bufTs;
        uint256[] memory bufBs;
        uint count = 0;

        // Find all affected stamped balances.
        {
            uint256[] storage fromTs = fromSbs.timestamps;
            uint256[] storage fromBs = fromSbs.balances;
            uint fromOffset = fromSbs.offset;
            uint fromNext = fromSbs.next;
            uint lastFromOffset = fromOffset;

            bufTs = new uint256[](fromNext - fromOffset);
            bufBs = new uint256[](bufTs.length);

            for (uint i = fromOffset; remain > 0 && i < fromNext; i++) {
                uint256 val;
                if (remain < fromBs[i]) {
                    val = remain;
                    fromBs[i] -= val;
                    remain = 0;

                } else {
                    val = fromBs[i];
                    remain -= val;
                    fromBs[i] = 0;
                    fromOffset++;
                }

                bufTs[count] = fromTs[i];
                bufBs[count] = val;
                count++;
            }

            require(remain == 0, "ERC20: amount exceeds balance");

            if (fromOffset != lastFromOffset) {
                fromSbs.offset = fromOffset;
            }
        }

        if (count == 0) {
            return;
        }

        // Update to stamped balances.
        {
            uint256[] storage toTs = toSbs.timestamps;
            uint256[] storage toBs = toSbs.balances;
            uint toOffset = toSbs.offset;
            uint toNext = toSbs.next;

            if (toOffset != 0) {
                toSbs.offset = 0;
            }

            if (toOffset >= toNext) {
                uint len = toTs.length;
                if (count <= len) {
                    len = count;
                }
                for (uint ii = 0; ii < len; ii++) {
                    toTs[ii] = bufTs[ii];
                    toBs[ii] = bufBs[ii];
                }
                while (len < count) {
                    toTs.push(bufTs[len]);
                    toBs.push(bufBs[len]);
                    len++;
                }

                if (toNext != count) {
                    toSbs.next = count;
                }
                return;
            }

            uint toLenNew = toNext - toOffset + count;
            uint256[] memory toTsNew = new uint256[](toLenNew);
            uint256[] memory toBsNew = new uint256[](toLenNew);
            uint i = 0;

            {
                uint oi = toOffset;
                uint bi = 0;
                uint256 ot = toTs[oi];
                uint256 bt = bufTs[0];

                // Merge
                while (i < toLenNew) {
                    if (ot == bt) {
                        toTsNew[i] = ot;
                        toBsNew[i] = toBs[oi] + bufBs[bi];
                        oi++;
                        bi++;
                    } else if (ot < bt) {
                        toTsNew[i] = ot;
                        toBsNew[i] = toBs[oi];
                        oi++;
                    } else {
                        toTsNew[i] = bt;
                        toBsNew[i] = bufBs[bi];
                        bi++;
                    }

                    i++;

                    if (oi < toNext) {
                        ot = toTs[oi];

                    } else {
                        while (bi < count && i < toLenNew) {
                            toTsNew[i] = bufTs[bi];
                            toBsNew[i] = bufBs[bi];
                            bi++;
                            i++;
                        }

                        break;
                    }

                    if (bi < count) {
                        bt = bufTs[bi];

                    } else {
                        while (oi < toNext && i < toLenNew) {
                            toTsNew[i] = toTs[oi];
                            toBsNew[i] = toBs[oi];
                            oi++;
                            i++;
                        }

                        break;
                    }
                }
            }

            toSbs.timestamps = toTsNew;
            toSbs.balances = toBsNew;

            if (toNext != i) {
                toSbs.next = i;
            }
        }
    }
}


contract Auditor is CustomizedToken {
    uint256 constant private PERIOD = 1 days;
    uint256 private _givenBonusSum;
    uint256 private _occupiedSum;
    uint256 private _feeSum;

    constructor() CustomizedToken("Auditor", "AUD") {

    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function _init() internal override {
        uint256 total = 1_000_000_000 * 10 ** decimals();
        _mint(address(this), total);
        // 60% for pair, 20% for awards of owner, 20% for bonuses of all holder.
        _transferFromSelf(address(this), ownerAddress(), total * 6 / 10, block.timestamp);
    }

    function _transferFromPair(address pair, address to, uint256 amount, uint256 curTimestamp) internal override {
        super._transferFromPair(pair, to, amount, curTimestamp);
        _occupiedSum += amount;
    }

    function _transferToPair(address from, address pair, uint256 amount, uint256 curTimestamp) internal override {
        super._transferToPair(from, pair, amount, curTimestamp);
        if (_occupiedSum > amount) {
            _occupiedSum -= amount;
        } else {
            _occupiedSum = 0;
        }
    }

    function _transferFee(address from, uint256 fee) internal override {
        super._transferFee(from, fee);
        _feeSum += fee;
    }

    function _giveBonus(address to, uint256 baseBonus, uint256 extraBonus, uint256 curTimestamp) internal override returns (uint256 amount) {
        amount = super._giveBonus(to, baseBonus, extraBonus, curTimestamp);
        if (_feeSum > extraBonus) {
            _feeSum -= extraBonus;
        } else {
            _feeSum = 0;
        }
        if (amount > 0) {
            _givenBonusSum += amount;
        }
        return amount;
    }

    function _estimate(uint256 amount, uint256 recordingTimestamp, uint256 desiredTimestamp) internal view override returns (uint256 amountOut, uint256 fee, uint256 baseBonus, uint256 extraBonus) {
        if (recordingTimestamp > desiredTimestamp) {
            return (0, 0, 0, 0);
        }

        uint256 duration = desiredTimestamp - recordingTimestamp;
        uint256 feeRate;

        if (duration < 7 * PERIOD) {
            feeRate = 99;
        } else if (duration < 14 * PERIOD) {
            feeRate = 60;
        } else if (duration < 21 * PERIOD) {
            feeRate = 30;
        } else if (duration < 28 * PERIOD) {
            feeRate = 10;
        } else {
            feeRate = 1;
        }

        fee = amount * feeRate / 100;
        amountOut = amount - fee;

        uint256 bonusDeadline = createdTime() + 1095 * PERIOD; // 365 days * 3
        if (recordingTimestamp >= bonusDeadline) {
            baseBonus = 0;
        } else {
            uint256 bonusDuration;
            if (desiredTimestamp > bonusDeadline) {
                bonusDuration = bonusDeadline - recordingTimestamp;
            } else {
                bonusDuration = duration;
            }
            baseBonus = bonusDuration / PERIOD * amount / 3285; // total * 20% / (total * 60% * 365 days * 3)
        }

        if (_occupiedSum > 0) {
            extraBonus = _feeSum * amount / _occupiedSum;
        }

        return (amountOut, fee, baseBonus, extraBonus);
    }

    function _award(uint256 lastTimestamp, uint256 desiredTimestamp) internal view override returns (uint256 award) {
        if (desiredTimestamp <= lastTimestamp) {
            return 0;
        }

        uint256 createdT = createdTime();

        if (lastTimestamp >= createdT + 730 * PERIOD) {
            return 0;
        }

        uint256 total = totalSupply() / 5;
        award = (desiredTimestamp - lastTimestamp) / PERIOD * total / 730; // total * 20% / (365 days * 2)

        if (award > total) {
            return total;
        }

        return award;
    }
}