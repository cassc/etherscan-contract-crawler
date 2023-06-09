// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./IERC20Partition.sol";

abstract contract ERC20Partition is ERC20, IERC20Partition {

    bytes32 public constant DEFAULT_PARTITION = 0x00;

    mapping(bytes32 => uint256) private _totalSupplies;
    mapping(address => mapping(bytes32 => uint256)) private _balances;
    mapping(address => mapping(address => mapping(bytes32 => uint256))) private _allowances;

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply(bytes32 id) public view returns (uint256) {
        return _totalSupplies[id];
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account, bytes32 id) public view returns (uint256) {
        return _balances[account][id];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, bytes32 id, uint256 amount, bytes memory data) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, id, amount, data);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender, bytes32 id) public view returns (uint256) {
        return _allowances[owner][spender][id];
    }

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
    function approve(address spender, bytes32 id, uint256 amount, bytes memory data) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, id, amount, data);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        bytes32 id,
        uint256 amount,
        bytes memory data
    ) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, id, amount, data);
        _transfer(from, to, id, amount, data);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        return increaseAllowance(spender, DEFAULT_PARTITION, addedValue, "");
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
    function increaseAllowance(address spender, bytes32 id, uint256 addedValue, bytes memory data) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, id, allowance(owner, spender, id) + addedValue, data);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        return decreaseAllowance(spender, DEFAULT_PARTITION, subtractedValue, "");
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
    function decreaseAllowance(address spender, bytes32 id, uint256 subtractedValue, bytes memory data) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender, id);
        require(currentAllowance >= subtractedValue, "ERC20Partition: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, id, currentAllowance - subtractedValue, data);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _transfer(from, to, DEFAULT_PARTITION, amount, "");
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
    function _transfer(
        address from,
        address to,
        bytes32 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(from != address(0), "ERC20Partition: transfer from the zero address");
        require(to != address(0), "ERC20Partition: transfer to the zero address");

        _beforeTokenTransfer(from, to, id, amount, data);

        uint256 fromBalance = _balances[from][id];
        require(fromBalance >= amount, "ERC20Partition: transfer amount exceeds balance");

        unchecked {
            _balances[from][id] = fromBalance - amount;
            _balances[to][id] += amount;
        }

        emit TransferPartition(from, to, id, amount, data);

        super._transfer(from, to, amount);

        _afterTokenTransfer(from, to, id, amount, data);
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
    function _mint(address account, uint256 amount) internal virtual override {
        _mint(account, DEFAULT_PARTITION, amount, "");
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
    function _mint(address account, bytes32 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC20Partition: mint to the zero address");

        _beforeTokenTransfer(address(0), account, id, amount, data);

        _totalSupplies[id] += amount;
        unchecked {
            _balances[account][id] += amount;
        }
        emit TransferPartition(address(0), account, id, amount, data);

        super._mint(account, amount);

        _afterTokenTransfer(address(0), account, id, amount, data);
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
    function _burn(address account, uint256 amount) internal virtual override {
        _burn(account, DEFAULT_PARTITION, amount, "");
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
    function _burn(address account, bytes32 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC20Partition: burn from the zero address");

        _beforeTokenTransfer(account, address(0), id, amount, data);

        uint256 accountBalance = _balances[account][id];
        require(accountBalance >= amount, "ERC20Partition: burn amount exceeds balance");
        unchecked {
            _balances[account][id] = accountBalance - amount;
        }
        _totalSupplies[id] -= amount;

        emit TransferPartition(account, address(0), id, amount, data);

        super._burn(account, amount);

        _afterTokenTransfer(account, address(0), id, amount, data);
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
    function _approve(
        address owner,
        address spender,
        bytes32 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(owner != address(0), "ERC20Partition: approve from the zero address");
        require(spender != address(0), "ERC20Partition: approve to the zero address");

        _allowances[owner][spender][id] = amount;
        emit ApprovalPartition(owner, spender, id, amount, data);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        bytes32 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender, id);
        if (currentAllowance == type(uint256).max) return;
        if (currentAllowance >= amount) {
            unchecked {
                _approve(owner, spender, id, currentAllowance - amount, data);
            }
        } else {
            if (currentAllowance > 0) {
                _approve(owner, spender, id, 0, data);
            }
            if (currentAllowance != amount) {
                unchecked {
                    _spendAllowance(owner, spender, amount - currentAllowance);
                }
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
    function _beforeTokenTransfer(
        address from,
        address to,
        bytes32 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        bytes32 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}
}