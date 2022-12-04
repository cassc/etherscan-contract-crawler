// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {IERC20Errors} from "./errors/IERC20Errors.sol";

library LibERC20 {
    struct Storage {
        uint256 totalSupply;
        string name;
        string symbol;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarlabs.modules.ERC20.LibERC20");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            s.slot := slot
        }
        // solhint-enable
    }

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == address(0)) {
            revert IERC20Errors.ERC20TransferFromZeroAddress();
        }
        if (to == address(0)) revert IERC20Errors.ERC20TransferToZeroAddress();

        Storage storage s = _storage();

        uint256 fromBalance = _storage().balances[from];
        if (amount > fromBalance) {
            revert IERC20Errors.ERC20TransferAmountExceedsBalance(
                amount,
                fromBalance
            );
        }

        unchecked {
            s.balances[from] = fromBalance - amount;
        }
        s.balances[to] += amount;

        emit Transfer(from, to, amount);
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
    function mint(address account, uint256 amount) internal {
        if (account == address(0)) revert IERC20Errors.ERC20MintToZeroAddress();

        Storage storage s = _storage();

        s.totalSupply += amount;
        s.balances[account] += amount;

        emit Transfer(address(0), account, amount);
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
    function burn(address account, uint256 amount) internal {
        if (account == address(0))
            revert IERC20Errors.ERC20BurnFromZeroAddress();

        Storage storage s = _storage();

        uint256 accountBalance = s.balances[account];
        if (amount > accountBalance)
            revert IERC20Errors.ERC20BurnAmountExceedsBalance(
                amount,
                accountBalance
            );

        unchecked {
            s.balances[account] = accountBalance - amount;
        }
        s.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) internal view returns (uint256) {
        return _storage().balances[account];
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        internal
        view
        returns (uint256)
    {
        return _storage().allowances[owner][spender];
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
    function approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        if (owner == address(0))
            revert IERC20Errors.ERC20ApproveFromZeroAddress();
        if (spender == address(0))
            revert IERC20Errors.ERC20ApproveToZeroAddress();

        _storage().allowances[owner][spender] = amount;

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
    function spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (amount > currentAllowance)
                revert IERC20Errors.ERC20InsufficientAllowance(
                    amount,
                    currentAllowance
                );

            unchecked {
                approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Returns the name of the token.
     */
    function getName() internal view returns (string memory) {
        return _storage().name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function getSymbol() internal view returns (string memory) {
        return _storage().symbol;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() internal view returns (uint256) {
        return _storage().totalSupply;
    }

    function setName(string memory name) internal {
        _storage().name = name;
    }

    function setSymbol(string memory symbol) internal {
        _storage().symbol = symbol;
    }
}