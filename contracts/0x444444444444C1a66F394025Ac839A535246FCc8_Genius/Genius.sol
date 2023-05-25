/**
 *Submitted for verification at Etherscan.io on 2022-12-31
*/

// SPDX-License-Identifier: UNLICENSED
// Genius is NOT LICENSED FOR COPYING.
// Genius (C) 2022. All Rights Reserved.
//
// Telegram: https://t.me/genicrypto
// Twitter: https://twitter.com/genicrypto
// White Paper: https://geni.to/smartcontract
//
// First DAPP: https://start.geni.app
// Community Website: https://thegeniustoken.com
// Development Telegram: https://t.me/genicryptodev
//
// Buy $GENI here:
// * Ethereum: https://geni.to/ethereum
// * Binance: https://geni.to/binance
// * Polygon: https://geni.to/polygon
// * Avalanche: https://geni.to/avalanche
//
// Third-Party Security Reviews:
// * Gleipnir: https://www.gleipnirsecurity.com/_files/ugd/a4dd88_02edf4a4aeef4e6d950db85175488ebb.pdf
// * CertiK: https://www.certik.com/projects/genius

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File @openzeppelin/contracts/security/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
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
        uint256 amount
    ) internal virtual {}
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;





/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


// File contracts/Utilities.sol

// License: UNLICENSED
// Genius is NOT LICENSED FOR COPYING.
// Genius (C) 2022. All Rights Reserved.
pragma solidity 0.8.4;

interface IPenalty {
    function setMinersContract(address _minersAddress) external;
    function increasePenaltyCounter(uint256 principal) external;
    function redistribution(bool minerPolicy, uint256 principalPenalties, uint256 rewardPenalties) external
        returns (uint256 oaReceivingAmount, uint256 redistributedPenalties);
    function decMinerPopulation(uint256 genitos) external;
    function incMinerPopulation(uint256 genitos) external;
    function getMaxOrder() external view returns (uint256 maxOrder);
    function counter() external view returns (uint256);
    function calcLemClaimed(Utilities.MinerCache memory miner) external view returns(uint256);
    function endMinerPenalties(Utilities.MinerCache calldata miner, uint256 servedDays,
        uint256 currentGeniusDay, uint256 rewards) external
        returns (Utilities.PenaltyData memory ptData);
    function minerWeight(uint256 weight) external view returns (uint256);
}

interface IGeniusAuction {
    struct AuctionCache {
        uint256 totalBids;
        uint256 firstBid;
        address highestBidder;
        uint256 minerIndex;
        uint256 highestBid;
        address owner;
        bool active;
        uint256 end;
    }

    function getGeniusAuctionState(address owner, uint256 minerIndex)
        external
        returns (AuctionCache memory);

    function cancelAuction(address owner, uint256 minerIndex) external;

    function verifyAuctionNoBid(address owner, uint256 minerIndex)
        external
        returns (bool);

    function setPenaltyAddress(address panlty) external;

    function setMinersContract(address _minersAddress) external;

    function setCalendarContract(address _calendarAddress) external;

    function setGnftContract(address _gnftAddress) external;

}

interface IStabilityPool {

    struct CollateralMiner {
        address collateralToken;
    }

    function getMinerColAddress(address owner, uint256 minerIndex) external returns (address);

    function clearGeniusDebt(
        Utilities.MinerCache calldata miner,
        address minerOwner,
        uint256 minerIndex,
        address beneficiary,
        uint256 currentGeniusDay,
        bool benevolent
    ) external returns (uint256);

    function settleGeniusDebt(address beneficiary, address token,
        uint256 amount, uint256 settlementFeeDays, bool mintNft) external returns (uint256);

    function setOaGrantor(address grantor) external;

    function setOaBeneficiary(address beneficiary) external;

    function genitosRequiredToClear(address collateralAddress, uint256 principal) external returns (uint256);

    function setPenaltyContract(address penaltyContract) external;

    function setMinersContract(address minersContract) external;

    function setGnftContract(address _gnftAddress) external;

    function setAuctionContract(address auctionAddress) external;
}

interface IGeniusCalendar {
    struct GeniusDaySummaryStore {
        uint256 newInflation;
        uint256 redistribution;
        uint256 basicShares;
        uint256 advShares;
    }

    function getDaySummary(uint256 localGeniusDay)
        external
        view
        returns (GeniusDaySummaryStore memory summary);

    function makeGeniusDaySummary(uint256 _summarizeLimit) external;

    function decreaseBurnedSupply(uint256 _amount) external;

    function increaseBurnedSupply(uint256 _amount) external;

    function burnedSupply() external view returns (uint256);

    function calcDayBasicPayout(uint256 _geniusDay)
        external
        view
        returns (uint256);

    function calcDayAdvPayout(uint256 _geniusDay, uint256 _basicPayout)
        external
        view
        returns (uint256);

    function decAdvShares(uint256 _amount) external;

    function decBasicShares(uint256 _amount) external;

    function shareRate() external view returns (uint256);

    function localSummarizeGeniusDay(
        uint256 _summarizeLimit,
        address _summarizer,
        bool mintNft
    ) external returns(uint256 itCount);

    function local10daySummary(uint256 _summarizeLimit, address _summarizer, bool mintNft) external returns(uint256 itCount);

    function local100daySummary(uint256 _summarizeLimit, address _summarizer, bool mintNft) external returns(uint256 itCount);

    function local1000daySummary(uint256 _summarizeLimit, address _summarizer, bool mintNft) external returns(uint256 itCount);

    function incAdvSharesNext(uint256 _amount) external;

    function incBasicSharesNext(uint256 _amount) external;

    function geniusDay() external view returns (uint256);

    function setShareRate(uint256 _shareRate) external;

    function minerTotalPps(uint256 startDay, uint256 lastServedDay, bool minerPolicy) external view returns(uint256);

    function setPenaltyContract(address _penaltyAddress) external;

    function setMinersContract(address _minersAddress) external;

    function setHexodusContract(address _hexodus) external;

    function incDailyPenalties(uint256 _amount) external;

    function setGnftContract(address _gnftAddress) external;

    function summarizeServedDays(address beneficiary, uint256 startDay,
        uint256 promiseDays, bool mintNft) external;
}

interface IMiners {
    function minerStore(address owner, uint256 minerIndex) external view returns(Utilities.MinerCache memory miner);
    function minerStoreLength(address owner) external view returns (uint256 length);
    function getMiners(address owner) external view returns(Utilities.MinerCache[] memory miners);
    function setMinerEnded(address owner, uint256 minerIndex, uint256 ended) external;
    function setMinerStoreLemClaimDay(address owner, uint256 minerIndex, uint256 lemClaimDay) external;
    function setHexodusContract(address _hexodus) external;
    function setGnftContract(address _gnftAddress) external;
    function checkMinerForEnd(
        Utilities.MinerCache memory miner,
        address owner,
        uint256 minerIndex,
        uint256 currentDay,
        uint256 servedDays
    ) external;
}

interface IGnft {
    function mintNft(address to, uint256 nextSalt) external;
}


contract Utilities {

    // Revert Errors
    error NoClaimExists();
    error CannotShutdown();
    error UnauthorizedLostBonusClaiming();

    /** PHI Constants
     * @notice all of the above constants (PHI & GENIUS_RATIO) have 21 decimals of precision
     */
    /* ~ CONSTANTS ~ */
    // PHI = 1.618033988749894848205
    uint256 internal constant PHI = 1618033988749894848204586834;
    // PHI^-2 = 0.38196601125010515179541316563436188227969082019424
    uint256 internal constant PHI_NPOW_2 = 381966011250105151795413165;
    // PHI^-3 = 0.23606797749978969640917366873127623544061835961153
    uint256 internal constant PHI_NPOW_3 = 236067977499789696409173668;
    // PHI^-3.5 = 0.18558516575586807029616916594610619486184991016702
    uint256 internal constant PHI_NPOW_35 = 185585165755868070296169165;
    // PHI^2 = 2.6180339887498948482045868343656381177203091798058
    uint256 internal constant PHI_POW_2 = 2618033988749894848204586834;
    // PHI^PHI = 2.1784575679375991473725457028712458518070433016933
    uint256 internal constant PHI_POW_PHI = 2178457567937599147372545702;

    uint256 internal constant PHI_PRECISION = 1000000000000000000000000000;

    uint256 internal constant GENIUS_PRECISION = 1000000000;

    address internal constant LGENI_OA = 0x66eCa275200015DCD0C2Eaa6E48d4eED3092cDD6;

    uint8 internal constant GENIUS_DECIMALS = 9;

    // Tue Dec 13 2022 20:44:06 GMT+0000
    // Tue Dec 13 2022 13:44:06 GMT-0700 (Mountain Standard Time)
    // Tue Dec 13 2022 14:44:06 PM CST GMT-0600 (Central Standard)
    uint256 public constant LAUNCH_TIMESTAMP = 1670964246;

    // 10 ** 18
    uint256 internal constant SHARE_PRECISION = 1000000000000000000;

    // Penalty Counter Precision: 10 ** 12
    uint256 internal constant PENALTY_COUNTER_PRECISION = 1000000000000;

    // claims root for airdrop
    /** @notice MAKE CONSTANT FOR PRODUCTION */
    bytes32 internal constant MERKLE_ROOT =
        0xcad71776a60b1a4ca80bfa5452bfc50beeb645b7f64e97f5c464ef45a41d548d;

    /* ~ Variables ~ */

    uint256 public advLockedSupply;
    uint256 public basicLockedSupply;

    address public stabilityPoolAddress;
    IStabilityPool stabilityPoolContract;

    address public auctionAddress;
    IGeniusAuction auctionHouse;

    address public calendarAddress;
    IGeniusCalendar calendar;

    address public penaltyAddress;
    IPenalty penaltyContract;

    address public minersAddress;
    IMiners minersContract;

    address public hexodusAddress;
    address public gnftAddress;
    IGnft _gnftContract;

    // Origin Address Wallet
    address public oaGrantor;
    address public oaBeneficiary;

    /** Sacrifice merkle claims tracker */
    mapping(address => bool) public claimed;

    uint256 public oaMintableBalance;

    /* ~ DATA STRUCTS ~ */
    struct MinerCache {
        bool policy;
        bool auctioned;
        bool exodus;
        uint256 startDay;
        uint256 promiseDays;
        uint256 lemClaimDay;
        uint256 rewardShares;
        uint256 penaltyDelta;
        bool nonTransferable;
        uint256 ended;
        uint256 principal; // in genitos (10^9)
        uint256 debtIssueRate;
    }

    struct PenaltyData {
        uint256 eemRewardFee;
        uint256 eemPrincipalFee;
        uint256 eemPenalty;
        uint256 lemRewardFee;
        uint256 lemPrincipalFee;
        uint256 lemPenalty;
    }

    /* ~ EVENTS STRUCTS ~ */
    event Claim(
        address sender,
        address claimant,
        uint256 amount
    );

    event LemRewardsClaim(
        address indexed executorRewardAddress,
        address owner,
        uint256 minerIndex,
        uint256 executorReward
    );

    /**
     * @param  owner        the account that owned the miner at the time of end.
     * @param  minerIndex   the account's index for the miner struct.
     * @param  benevolence  whether this "end" action was for community
     *                      benevolence.
     *
     * @param  principalPayout    The amount of Principal that was returned to
     *                            the owner minus principal penalties.
     * @param  totalMinerRewards  The total amount of rewards--will always be
     *                            the Total PPS multiplied by the Shares.
     * @param  rewardsPayout      The actual amount of rewards paid to the owner
     *                            minus penalties on the rewards.
     * @param  penaltyToMiners    From ending, this amount of penalties was
     *                            redistributed to other Advanced Miners.
     */
    event EndMiner(address indexed owner, uint256 minerIndex, bool benevolence,
        uint256 principalPayout, uint256 totalMinerRewards,
        uint256 rewardsPayout, uint256 penaltyToMiners, Utilities.MinerCache miner);

    event ShutdownMiner(address indexed minerAddress, uint256 minerIndex,
        address indexed executorRewardAddress, uint256 executorReward,
        uint256 performanceRewards, uint256 redistributedPenalties,
        uint256 toOa, uint256 burnedForever, Utilities.MinerCache miner);

    event ChangeOaGrantor(address newOaGrantor, uint256 updated);

    event ChangeOaBeneficiary(address newOaBeneficiary, uint256 updated);
}


// File contracts/Genius.sol

// License: UNLICENSED
// Genius is NOT LICENSED FOR COPYING.
// Genius (C) 2022. All Rights Reserved.
pragma solidity 0.8.4;





contract Genius is ERC20, ERC20Permit, Utilities, ReentrancyGuard {

    error ErrorNullAddress();
    error ErrorUnauthorized();
    error ErrorCannotReleaseShares();
    error ErrorCannotReleaseAuctionedShares();
    error ErrorNotLaunchedYet();

    struct ShutdownDataCache {
        uint256 principalToRedistribute;
        uint256 rewardsToRedistribute;
        uint256 txPrincipalRewards;
        uint256 txPerformanceRewards;
    }

    constructor(
        address _oaGrantor,
        address _oaBeneficiary
    ) ERC20("Genius", "GENI") ERC20Permit("Genius") {
        if (_oaGrantor == address(0) || _oaBeneficiary == address(0)) {
            revert ErrorNullAddress();
        }
        oaGrantor = _oaGrantor;
        oaBeneficiary = _oaBeneficiary;
        _mint(address(this), 240000000000000000000);
    }

    /**
     * @notice public facing pure, returns decimal precision value of genius
     */
    function decimals() public pure override returns (uint8) {
        return GENIUS_DECIMALS;
    }

    /**
     * @dev only callable by oaGrantor, set oaBeneficiary address
     */
    function changeOaBeneficiary(address _oaBeneficiary) external {
        if (_oaBeneficiary == address(0)) revert ErrorNullAddress();
        if (msg.sender != oaGrantor) revert ErrorUnauthorized();
        oaBeneficiary = _oaBeneficiary;
        stabilityPoolContract.setOaBeneficiary(_oaBeneficiary);
        emit ChangeOaBeneficiary(_oaBeneficiary, block.timestamp);
    }

    /**
     * @dev only callable by oaGrantor, change oaGrantor
     */
    function changeOaGrantor(address _newOaGrantor) external {
        if (_newOaGrantor == address(0)) revert ErrorNullAddress();
        if (msg.sender != oaGrantor) revert ErrorUnauthorized();
        oaGrantor = _newOaGrantor;
        stabilityPoolContract.setOaGrantor(_newOaGrantor);
        emit ChangeOaGrantor(_newOaGrantor, block.timestamp);
    }

    /**
     * @notice public facing, shielded. Only OA can set the auction.
     * @notice auction house must be set before auction functions are operable
     */
    function setAuctionContract(address _auction) external {
// NOTE: OA Grantor check removed because deployment will include these "set"
// functions.  The actual gate that will prevent the Auction Contract being
// set again is the requirement that auctionAddress is not yet set.
//        require(msg.sender == oaGrantor && auctionAddress == address(0), "u");
        if (_auction == address(0)) revert ErrorNullAddress();
        if (auctionAddress != address(0)) revert ErrorUnauthorized();
        auctionAddress = _auction;
        auctionHouse = IGeniusAuction(_auction);
        stabilityPoolContract.setAuctionContract(_auction);
    }

    /**
     * @dev only callable by oaGrantor, set stability pool address (only callable once)
     */
    function setStabilityPoolAddress(address _stabilityPool) external {
// NOTE: this prevents Stability Pool from being set again AFTER deployment
// by ensuring that the contract address has not already been set.
//        require(msg.sender == oaGrantor && stabilityPoolAddress == address(0), "u");
        if (_stabilityPool == address(0)) revert ErrorNullAddress();
        if (stabilityPoolAddress != address(0)) revert ErrorUnauthorized();
        stabilityPoolAddress = _stabilityPool;
        stabilityPoolContract = IStabilityPool(_stabilityPool);
        // NOTE: to prevent a circular dependency, the OA Grantor will need to
        // call this separately.
        //auctionHouse.setStabilityContract(_stabilityPool);
    }

    /**
     * @dev only callable by oaGrantor, set calendar address and calls setters on calendar and auction (only callable once)
     */
    function setCalendarContract(address _calendar) external {
// NOTE: this prevents Calendar from being set again AFTER deployment by
// ensuring that the contract address has not already been set.
        if (_calendar == address(0)) revert ErrorNullAddress();
        if (calendarAddress != address(0)) revert ErrorUnauthorized();
        calendarAddress = _calendar;
        calendar = IGeniusCalendar(_calendar);
        auctionHouse.setCalendarContract(_calendar);
    }

    /**
     * @dev only callable by oaGrantor, set penalty address and calls setters on calendar, stability pool and auction (only callable once)
     */
    function setPenaltyContract(address _pcAddress) external {
// NOTE: this prevents Penalty from being set again AFTER deployment by
// ensuring that the contract address has not already been set.  The deploy
// scripts manage and ensure that this is set at launch.
        if (_pcAddress == address(0)) revert ErrorNullAddress();
        if (penaltyAddress != address(0)) revert ErrorUnauthorized();
//        require(
//            msg.sender == oaGrantor &&
//            penaltyAddress == address(0) &&
//            calendarAddress != address(0) &&
//            stabilityPoolAddress != address(0) &&
//            auctionAddress != address(0)
//        , "u");

// NOTE: combining these saves 0.111 KB.
//        require(msg.sender == oaGrantor && penaltyAddress == address(0), "u");
//        require(calendarAddress != address(0), "1");
//        require(stabilityPoolAddress != address(0), "2");
//        require(auctionAddress != address(0), "3");
        penaltyContract = IPenalty(_pcAddress);
        penaltyAddress = _pcAddress;
        calendar.setPenaltyContract(_pcAddress);
        stabilityPoolContract.setPenaltyContract(_pcAddress);
        auctionHouse.setPenaltyAddress(_pcAddress);
    }

    /**
     * @dev only callable by oaGrantor, sets miners address and calls setters on auction, calendar and stability pool (only callable once)
     */
    function setMinersContract(address _minersAddress) external {
// NOTE: this prevents Miners from being set again AFTER deployment by
// ensuring that the contract address has not already been set.  The deploy
// scripts manage and ensure that this is set at launch.
//        require(msg.sender == oaGrantor && minersAddress == address(0), "u");
        if (_minersAddress == address(0)) revert ErrorNullAddress();
        if (minersAddress != address(0)) revert ErrorUnauthorized();
        minersAddress = _minersAddress;
        minersContract = IMiners(_minersAddress);
        auctionHouse.setMinersContract(_minersAddress);
        calendar.setMinersContract(_minersAddress);
        stabilityPoolContract.setMinersContract(_minersAddress);
        penaltyContract.setMinersContract(_minersAddress);
    }

    function setHexodusContract(address _hexodus) external {
        if (_hexodus == address(0)) revert ErrorNullAddress();
        if (msg.sender != oaGrantor || hexodusAddress != address(0)) {
            revert ErrorUnauthorized();
        }
        hexodusAddress = _hexodus;
        minersContract.setHexodusContract(_hexodus);
        calendar.setHexodusContract(_hexodus);
    }

    /**
     * @notice set up Genius NFT controller
     * @dev allowed only by OA grantor or deployer
     * @param _gnftAddress address of genius NFT controller
     */
    function setGnftContract(address _gnftAddress) external {
// NOTE: GNFT will be launched after the core Genius contracts, and therefore,
// it is necessary to also gate the setting of GNFT's address by limiting this
// action to the OA Grantor.
        if (_gnftAddress == address(0)) revert ErrorNullAddress();
        if (msg.sender != oaGrantor || gnftAddress != address(0)) {
            revert ErrorUnauthorized();
        }
        gnftAddress = _gnftAddress;
        _gnftContract = IGnft(_gnftAddress);

        auctionHouse.setGnftContract(_gnftAddress);
        calendar.setGnftContract(_gnftAddress);
        minersContract.setGnftContract(_gnftAddress);
        stabilityPoolContract.setGnftContract(_gnftAddress);
    }

    function _currentGeniusDay() internal view returns (uint256) {
        if (block.timestamp < LAUNCH_TIMESTAMP) revert ErrorNotLaunchedYet();
        unchecked {
            return (block.timestamp - LAUNCH_TIMESTAMP) / 1 days;
        }
    }

    /**
     * @dev PUBLIC FACING VIEW, view function that returns the total reserved supply accounting
     */
    function reserveSupply() external view returns (uint256) {
        unchecked {
            return totalSupply() + calendar.burnedSupply() + advLockedSupply + basicLockedSupply;
        }
    }

    /**
     * @dev Claims for initial GENI distribution
     * @param destination is the claimant, based on off chain data
     * @param amount claimant's amount of GENI to distribute
     * @param merkleProof array of hashes up the merkleTree
     * @param mintNft  The EOA's preference of whether or not to spend gas for
     *                 the chance of minting an NFT.
     */
    function claimGenius(
        address destination,
        uint256 amount,
        bytes32[] calldata merkleProof,
        bool mintNft
    ) external nonReentrant {
//        require(canClaim(destination, amount, merkleProof), "I");
        if (!canClaim(destination, amount, merkleProof)) {
            revert NoClaimExists();
        }

        claimed[destination] = true;

        if (destination == msg.sender || _currentGeniusDay() < 181 ||
            (block.timestamp < LAUNCH_TIMESTAMP && destination == LGENI_OA))
        {
            ERC20(address(this)).transfer(destination, amount);
            if (mintNft) {
                _gnftContract.mintNft(destination, 0);
            }
            emit Claim(msg.sender, destination, amount);
            return;
        }

        // Sender may get an NFT if they opted-into minting :)
        if (mintNft && _probability(msg.sender, PHI_NPOW_2, PHI_PRECISION, 0, 0)) {
            _gnftContract.mintNft(msg.sender, 1);
        }

        unchecked {
            // the msg.sender will receive 100 GENI, and the remainder goes to the
            // lazy owner of the claim :)
            ERC20(address(this)).transfer(msg.sender, 100000000000);
            ERC20(address(this)).transfer(destination, amount - 100000000000);
        }
        emit Claim(msg.sender, destination, amount);
    }

    /**
     * @dev helper for validating if an address has GENI to claim
     * @return true if claimant has not already claimed and the data is valid, false otherwise
     */
    function canClaim(
        address destination,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(destination, amount));
        return
            !claimed[destination] &&
            MerkleProof.verify(merkleProof, MERKLE_ROOT, node);
    }

    /**
     * @dev only callable by auction contract.  Mints Genius token.
     */
    function mint(address owner, uint256 amount) external {
        if (msg.sender != auctionAddress) revert ErrorUnauthorized();
        _mint(owner, amount);
    }

    /**
     * @dev only callable by stability pool, auction, miners, or hexodus.
     *      Burns Genius token.
     */
    function burn(address owner, uint256 amount) external {
        if (
            msg.sender != stabilityPoolAddress &&
            msg.sender != auctionAddress &&
            msg.sender != minersAddress &&
            msg.sender != hexodusAddress
        ) {
            revert ErrorUnauthorized();
        }
        _burn(owner, amount);
    }


    /**
     * @dev INTERNAL, calculates new share rate based on eem payout
     */
    function _newShareRate(MinerCache memory miner, uint256 neemPayout) internal view returns(uint256 newShareRate) {
        unchecked {
            newShareRate = (neemPayout * PHI_PRECISION +
                _min(
                    neemPayout * PHI_POW_PHI,
                    (neemPayout *
                        _min(
                            4444 * PHI_PRECISION,
                            _ceiling(
                                miner.promiseDays *
                                    (PHI_PRECISION + PHI_NPOW_3),
                                PHI_PRECISION
                            ) - PHI_PRECISION
                        )) /
                        1456
                ) +
                neemPayout * _min(neemPayout * PHI_PRECISION, PHI * 10**17) / 10**18) /
                miner.rewardShares /
                PHI_PRECISION;
            return newShareRate;
        }
    }

    /**
     * @dev manage share rate calculations for end miner functionality
     */
    function _manageSystemShares(
        MinerCache memory miner,
        uint256 currentGeniusDay,
        uint256 eemPenalty,
        uint256 lemPenalty,
        uint256 rewards
    ) internal {
        if (miner.lemClaimDay == 0) {
            if (!miner.policy) {
                calendar.decBasicShares(miner.rewardShares);
            } else {
                calendar.decAdvShares(miner.rewardShares);
            }
        }
        unchecked {
            uint256 neemPayout = miner.principal + rewards -
                (currentGeniusDay < miner.startDay + miner.promiseDays ? eemPenalty : 0);
    //        uint256 neemPayout = _neemPayout(
    //            miner.principal,
    //            rewards,
    //            currentGeniusDay,
    //            miner.startDay + miner.promiseDays,
    //            eemPenalty
    //        ); // NEEMP - Non-Early End Mining Payout

            if (neemPayout >= miner.principal) {
                // calculate new Share Rate
                calendar.setShareRate(_newShareRate(miner, neemPayout));
            }
        }
    }

    /**
     * @dev send collateral miner payouts for ended miners
     */
    function _manageCollateralMinerPayouts(
        address owner,
        uint256 netPrincipalPayout,
        uint256 netRewardsPayout,
        bool benevolence
    ) internal {
        if (!benevolence) {
            // if net principal payout > 0:
            //      mint ( principal + rewards )
            if (netPrincipalPayout > 0) {
                unchecked {
                    _mint(owner, netPrincipalPayout + netRewardsPayout);
                }
            }

            // if net rewards payout > 0:
            //      decrease burned supply ( net rewards payout )
            if (netRewardsPayout > 0) {
                calendar.decreaseBurnedSupply(netRewardsPayout);
            }
        }
    }

    /**
     * @dev send miner payouts foe ended miners
     */
    function _manageMinerPayouts(
        MinerCache memory miner,
        address owner,
        uint256 eemPrincipalFee,
        uint256 lemPrincipalFee,
        uint256 eemRewardFee,
        uint256 lemRewardFee,
        uint256 rewards,
        bool benevolence
    ) internal returns (uint256 netPrincipalPayout, uint256 netRewardsPayout) {
        unchecked {
            uint256 principalPenalties = _max(eemPrincipalFee, lemPrincipalFee + penaltyContract.calcLemClaimed(miner));
            uint256 rewardPenalties = _max(eemRewardFee, lemRewardFee);
            netPrincipalPayout = miner.principal > principalPenalties ? miner.principal - principalPenalties : 0;
            netRewardsPayout = rewards > rewardPenalties ? rewards - rewardPenalties : 0;

            if (miner.lemClaimDay == 0) {
                // NOTE: the Release Shares function is responsible for moving the
                // entire principal out of the Locked Supply--because that principal
                // is no-longer "locked".  However, when LEM Claim Day is not set,
                // then the Release Shares function was not called, and the miner's
                // principal must be completely removed from the locked supply.

                if (miner.policy) {
                    // NOTE: the Principal Penalties will STILL be removed from
                    // the locked supply.  In other words, the entire principal
                    // must be removed.  The Lucid Chart specs were wrong;
                    // remove the entire supply.
                    advLockedSupply -= miner.principal;
                } else {
                    // NOTE: the entire principal should be removed from any of
                    // the Locked supplies because the principal is no-longer
                    // "locked".  Of course, any principal that does not get
                    // "minted" to the EOA or OA will need to be added to the
                    // Burned Supply.
                    basicLockedSupply -= miner.principal;
                }

                if (netRewardsPayout > 0 && !benevolence) {
                    calendar.decreaseBurnedSupply(netRewardsPayout);
                }

                // NOTE: if this is Benevolence, then is the entire principal must
                // be moved over to the Burned Supply.
                if (benevolence) {
                    calendar.increaseBurnedSupply(miner.principal);
                }
                else {
                    // But when the miner was not ended benevolently, then we will
                    // increase the burned supply by only the principal penalties,
                    // which *will not* include the LEM Claim Reward.  That reward
                    // will not be included in the 'principalPenalties' calculation
                    // because the lemClaimDay property is 0 :)
                    calendar.increaseBurnedSupply(principalPenalties);
                }
            } else {
                // WARNING: in this scope, the shares were released by the Release
                // Shares function, and therefore, all principal (minus the LEM
                // Claim Reward) was already moved over to the Burned Supply.

                // THEREFORE: we will not increase the Burned Supply here.  We will
                // only decrease the burned supply by the amount of principal and
                // rewards that get removed from the Burned Supply.

                // NOTE: When a non-collateral miner ends, if the shares were
                // released, like in this conditional scope, then the entire
                // principal was already unlocked and moved over to the burned
                // supply.  Therefore, we need to remove any principal (and rewards)
                // that will be minted out of the Burned Supply.
                calendar.decreaseBurnedSupply(netPrincipalPayout + netRewardsPayout);
            }

            // NOTE: all "penalized principal" must move over to the Burned Supply,
            // except for the LEM Claim Reward, because that was given to the EOA
            // that called the Release Shares function.  Furthermore, the payout
            // accounting is handled automatically by _mint -- Total Supply will be
            // increased, and the amount increased was already removed, or not added
            // to, the Burned Supply in the scope, above.

            if (!benevolence && netPrincipalPayout + netRewardsPayout > 0) {
                _mint(owner, netPrincipalPayout + netRewardsPayout);
            }
        }
    }

    /**
     * @dev extended logic for endMiner() function
     * @param  owner  the owner of the miner -- it is the responsibility of the
     *                external functions that call this function to provide end
     *                user security.  Only the msg sender can end a miner.
     * @param  minerIndex   miner index
     * @param  rewards      all performance rewards earned during this miner's
     *                      serving period.
     * @param  benevolence  is this miner ending for the sake of benevolence?
     *                      then anything minted will be burned.
     * @param  mintNft      end user opt-in to spend gas and possibly get an NFT
     */
    function _endMinerDeep(address owner, uint256 minerIndex, uint256 rewards, bool benevolence, bool mintNft) internal
        returns (
            uint256 netPrincipalPayout, uint256 netRewardsPayout, uint256 penaltyToMiners
        ) {
        MinerCache memory miner = minersContract.minerStore(owner, minerIndex);
        unchecked {
            uint256 currentGeniusDay = _currentGeniusDay();
            uint256 servedDays = (
                currentGeniusDay < (miner.startDay + miner.promiseDays)
                    ? currentGeniusDay
                    : (miner.startDay + miner.promiseDays)
                ) - miner.startDay;

            // EM_03
            PenaltyData memory ptData = penaltyContract.endMinerPenalties(miner, servedDays, currentGeniusDay, rewards);

            // EM_04
            if (servedDays < miner.promiseDays) {
                // @dev miner is ending early.
                penaltyToMiners = _redistribution(miner, rewards, ptData.eemPrincipalFee, ptData.eemRewardFee);

                if (mintNft) {
                    if (_probability(owner, PHI / (miner.policy ? 10 : 100),
                        PHI_PRECISION, miner.principal, 0))
                    {
                        _gnftContract.mintNft(owner, 1);
                    }
                    else if (benevolence &&
                        _probability(owner, PHI_PRECISION, PHI_PRECISION, miner.principal, 2))
                    {
                        _gnftContract.mintNft(owner, 1);
                    }
                }
            } else {
                if (currentGeniusDay > miner.startDay + miner.promiseDays + 7) {
                    // @dev miner ended late and will serve late penalties.
                    penaltyToMiners = _redistribution(miner, rewards, ptData.lemPrincipalFee, ptData.lemRewardFee);

                    if (mintNft) {
                        bool minted = false;
                        if (benevolence) {
                            if (_probability(owner, PHI / 10, PHI_PRECISION, miner.principal, 10)) {
                                _gnftContract.mintNft(owner, 11);
                                minted = true;
                            }
                        }

                        if (!minted) {
                            if (_probability(owner, PHI / (miner.policy ? 10 : 100),
                                PHI_PRECISION, miner.principal, 0))
                            {
                                _gnftContract.mintNft(owner, 1);
                            }
                        }
                    }
                } else {
                    // @dev miner ended on time, as promised by the EOA.

                    // if the EOA opted-in to mint an NFT...
                    if (mintNft) {
                        // if this miner had 90 or more promise days...
                        if (miner.promiseDays > 89) {
                            // NOTE: if someone created a BASIC miner w/ 89 Promise
                            // Days on Day 0, then they get a free day and free NFT
                            // ...lucky!! :D
                            if (_probability(owner, PHI_PRECISION, PHI_PRECISION,
                                miner.principal, 0))
                            {
                                _gnftContract.mintNft(owner, 1);
                            }

                            // ALSO NOTE: if this end is a result of benevolence,
                            // then there will be another round of chance.
                            if (benevolence) {
                                if (_probability(owner, PHI_PRECISION, PHI_PRECISION,
                                    miner.principal, 3))
                                {
                                    _gnftContract.mintNft(owner, 4);
                                }
                            }
                        }
                        else if (_probability(owner, PHI / 100, PHI_PRECISION,
                            miner.principal, 0))
                        {
                            // Promise days will be < 90, and therefore this must be a
                            // Basic Miner.
                            _gnftContract.mintNft(owner, 1);
                        }
                        else if (benevolence && _probability(
                            owner, PHI_PRECISION, PHI_PRECISION, miner.principal, 20))
                        {
                            // if this condition is met, then this is a basic miner
                            // that was Proof Of Benevolence'd.
                            _gnftContract.mintNft(owner, 1);
                        }
                    }
                }
            }

            // EM_05 Manage System Shares
            _manageSystemShares(
                miner,
                currentGeniusDay,
                ptData.eemPenalty,
                ptData.lemPenalty,
                rewards
            );

            if (miner.debtIssueRate > 0) {
                // EM_06B Manage Collateral Payouts
                (netPrincipalPayout, netRewardsPayout) = _manageCollateralPayouts(
                    miner, owner, minerIndex, rewards,
                    ptData.lemPrincipalFee, ptData.lemRewardFee, benevolence);
            } else {
                // EM_06A Manage Payouts
                // uint256 principalPenalties = _max(eemPrincipalFee, lemPrincipalFee + lemClaimed);
                // address localOwner = owner;
                uint256 rewards = rewards;
                bool benevolence = benevolence;
                (netPrincipalPayout, netRewardsPayout) = _manageMinerPayouts(
                    miner,
                    owner,
                    ptData.eemPrincipalFee,
                    ptData.lemPrincipalFee,
                    ptData.eemRewardFee,
                    ptData.lemRewardFee,
                    rewards,
                    benevolence
                );
            }
        }
    }

    function _manageCollateralPayouts(
        MinerCache memory _miner,
        address _owner,
        uint256 _minerIndex,
        uint256 _rewards,
        uint256 _principalPenalties,
        uint256 _rewardPenalties,
        bool _benevolence
    ) internal returns (uint256 netPrincipalPayout, uint256 netRewardsPayout) {

        unchecked {
            uint256 rewardPenalties = _min(_rewards, _principalPenalties + _rewardPenalties);
            uint256 currentGeniusDay = _currentGeniusDay();

            // EM_06B
            if (_miner.lemClaimDay == 0) {
                advLockedSupply -= _miner.principal;
            }

            /*
                Utilities.MinerCache calldata miner,
                address minerOwner,
                uint256 minerIndex,
                address beneficiary,
                uint256 currentGeniusDay,
                bool benevolent
            */
            address owner = _owner;
            uint256 minerSettlementAmount = stabilityPoolContract.clearGeniusDebt(
                _miner, owner, _minerIndex, owner,
                currentGeniusDay, _benevolence);
    //        netPrincipalPayout = availablePrincipal > minerSettlementAmount ? availablePrincipal - minerSettlementAmount : 0;
            netPrincipalPayout = _miner.principal > minerSettlementAmount ?
                _miner.principal - minerSettlementAmount : 0;

            // NOTE: _rewardPenalties is what was passed as a parameter, it is NOT
            // the recalculated local variable.  Use the local variable that was a
            // recalculation of the Reward Penalties.
            netRewardsPayout = _rewards - rewardPenalties;
            _manageCollateralMinerPayouts(owner, netPrincipalPayout, netRewardsPayout, _benevolence);
        }
    }

    /**
     * @dev handle miner end functionalities
     * @param  minerIndex   index of the miner
     * @param  benevolence  is the miner benevolenced?
     * @param  mintNft      end user opt-in to spend gas and possibly get an NFT
     */
    function endMiner(
        uint256 minerIndex,
        bool benevolence,
        bool mintNft
    ) external nonReentrant {
        MinerCache memory miner = minersContract.minerStore(msg.sender, minerIndex);
        unchecked {
            uint256 currentGeniusDay = _currentGeniusDay();

            // Promise End Day = miner.startDay + miner.promiseDays
            // Served Days = MIN(Current Genius Day, Promise End Day) - miner.startDay
            // NOTE: if the miner index is invalid, then the "servedDays" value will
            // result in 0.
            uint256 servedDays = (
                currentGeniusDay < (miner.startDay + miner.promiseDays)
                    ? currentGeniusDay
                    : (miner.startDay + miner.promiseDays)
            ) - miner.startDay;

            // Start EM_01
            minersContract.checkMinerForEnd(
                miner,
                msg.sender,
                minerIndex,
                currentGeniusDay,
                servedDays
            );

            // Start Phase EM_02 Summarize Served Days
            //uint256 lastServedDay = miner.startDay + servedDays - 1;
            uint256 lastSummarizedDay = calendar.geniusDay() - 1;

            // if the miner is ending early OR the miner is ending beyond the grace period...
            if (servedDays < miner.promiseDays || miner.startDay + miner.promiseDays + 7 <= currentGeniusDay) {
                //calendar.localSummarizeGeniusDay(_currentGeniusDay() - lastServedDay, msg.sender);
                //calendar.localSummarizeGeniusDay(_currentGeniusDay() - (miner.startDay + servedDays - 1), msg.sender);

                calendar.localSummarizeGeniusDay(0, msg.sender, mintNft);
                calendar.local10daySummary(0, msg.sender, mintNft);
                calendar.local100daySummary(0, msg.sender, mintNft);
                calendar.local1000daySummary(0, msg.sender, mintNft);
            }
            else {
                // NOTE: when the miner ends "on-time", we won't catch-up and
                // summarize every single day, 10-day, 100-day, and 1,000-day
                // period summary.  Instead, since the owner of the miner was a
                // "good end user" and did the "good thing" by ending on-time, we
                // will only summarize the days and periods that enclose the days
                // served.
                //
                // Therefore, we must do this before we calculate the Total PPS and
                // rewards:
                //
                // 1) summarize all single-day summaries: only summarize the served
                //    days that have not yet been summarized.
                //if (lastServedDay > lastSummarizedDay) {
                uint256 lastServedDay = miner.startDay + servedDays - 1;
                if (lastServedDay > lastSummarizedDay) {
                    //calendar.localSummarizeGeniusDay(lastServedDay - lastSummarizedDay, msg.sender);
                    calendar.localSummarizeGeniusDay(
                        lastServedDay - lastSummarizedDay,
                        msg.sender,
                        mintNft
                    );
                }

                // 2) Summarize all full 10-day periods within the SERVED DAYS.
                //    Therefore, if the miner served all days (including) 100-415
                //    and we realize that the only 10-day summaries that exist are
                //    for all days prior to 390, then we must create the 10-day
                //    summary for 390-399 (index 39) and 400-409 (index 40).
                //    Summary 410-419 (index 41) WILL NOT BE CREATED because the
                //    miner did not serve the entire period of days 410-419; that
                //    miner only served days 410-415.  We also won't summarize the
                //    index 41 to save the end user gas :)  And because the end user
                //    does not need index 41 to calculate their Total PPS.
                    // Dai Proving the calculation of index and full period
                    // Summaring example and index and period change
                    // startDay = 0, servedDays = 10, lastServedDay = 9 =>
                    //      10summary index 0, period 1
                    //      100summary index 0, period 1
                    //      1000summary index 0, period 1
                    // startDay = 0, servedDays = 100, lastServedDay = 99 =>
                    //      10summary index 9, period 10
                    //      100summary index 9, period 0
                    //      1000summary index 9, period 0
                    // ... ...
                    // start day = 100, servedDays = 316 lastServedDay = startDay + servedDays - 1 = 415 =>
                    //      10summary index 41, period 42
                    //      100summary index 4, period 5
                    //      1000summary index 0, period 0
                    // Generalizing....
                    // maxXIndex = (miner.startDay +servedDays - 1) / X-days;
                    // maxXPeriod = max10Index + 1 = (miner.startDay +servedDays - 1) / X-days + 1;
                    // actualXPeriod = maxXPeriod - 1 = (miner.startDay +servedDays - 1) / X-days + 1 - 1 = (miner.startDay +servedDays - 1) / X-days
                    calendar.local10daySummary(lastServedDay / 10, msg.sender, mintNft);

                // 3) Just like with the 10-day periods, we must summarize all
                //    100-day periods that the miner needs to calculate the Total
                //    PPS / rewards, properly.
                    calendar.local100daySummary(lastServedDay / 100, msg.sender, mintNft);

                // 4) And then, finally, we must make sure that all 1,000-day
                //    periods within the SERVED DAYS are summarized.
                    calendar.local1000daySummary(lastServedDay / 1000, msg.sender, mintNft);
            }

            //calendar.minerTotalPps(miner.startDay, lastServedDay, miner.policy)
            uint256 totalMinerPps = calendar.minerTotalPps(miner.startDay, (miner.startDay + servedDays - 1), miner.policy);
            uint256 rewards = miner.rewardShares * totalMinerPps / SHARE_PRECISION;

            // End Phase EM_02
            (
                uint256 netPrincipalPayout,
                uint256 netRewardsPayout,
                uint256 penaltyToMiners
            )
            = _endMinerDeep(msg.sender, minerIndex, rewards, benevolence, mintNft);
            MinerCache memory miner2 = miner;
            emit EndMiner(msg.sender, minerIndex, benevolence,
                netPrincipalPayout, rewards,
                netRewardsPayout, penaltyToMiners, miner2);
        }
    }

    /**
     * @dev calculates late end mining penalties
     */
    function _penaltiesLem(
        uint256 geniusDay,
        uint256 promiseEndDay,
        uint256 principal,
        uint256 penalties,
        bool policy
    ) internal pure returns (uint256) {
        unchecked {
            uint256 lateDays = geniusDay - promiseEndDay - 7;
            uint256 min;

            if (!policy) {
                uint256 ceil = (principal * PHI * 100) / (7 * PHI_PRECISION);
                ceil =
                    ((ceil + GENIUS_PRECISION) - GENIUS_PRECISION) *
                    GENIUS_PRECISION;
                min = ceil > principal ? principal : ceil;
            } else {
                uint256 ceil = (principal * PHI_POW_2 * 100) / (7 * PHI_PRECISION);
                ceil =
                    ((ceil + GENIUS_PRECISION) - GENIUS_PRECISION) *
                    GENIUS_PRECISION;
                min = ceil > principal ? principal : ceil;
            }
            return (penalties / 1000) - (lateDays * min);
        }
    }

    /**
     * @dev mint amount stored in oaMintableBalance to the oaBeneficiary
     */
    function claimLostMintBonus() external nonReentrant {
// NOTE: converting this to a revert saves ... only 2 bytes :(
//        require(
//            msg.sender == oaGrantor &&
//            _currentGeniusDay() > 31 &&
//            oaMintableBalance > 0
//        , "u");
        if (msg.sender != oaGrantor ||
            _currentGeniusDay() < 32 ||
            oaMintableBalance == 0)
        {
            revert UnauthorizedLostBonusClaiming();
        }

// NOTE: combining these saves 0.039 KB
//        require(msg.sender == oaGrantor, "u");
//        require(_currentGeniusDay() > 31 && oaMintableBalance > 0, "o");
        _mint(oaBeneficiary, oaMintableBalance);
        oaMintableBalance = 0;
    }

    /**
     * @dev only callable by miners, increase oaMintableBalance
     */
    function incOaMintableBalance(uint256 bonusLostForever) external {
        if (msg.sender != minersAddress) revert ErrorUnauthorized();
        oaMintableBalance += bonusLostForever;
    }

    /**
     * @dev PUBLIC FACING, executes releaseShares core functionality (releases shares from pool)
     * @param  owner    owner of the miner that has the shares to be released.
     * @param  minerId  the INDEX of the owner's miner
     * @param  mintNft  end user opt-in to spend gas and possibly get an NFT
     */
    function releaseShares(address owner, uint256 minerId, bool mintNft) external nonReentrant {
        /*
            Inspect the lucid chart spec carefully, and be sure to update the flow and implementation of the RED TEXT AREAS.
            https://lucid.app/lucidchart/f1a1439e-e956-4a2c-be2f-e5dba66cc6a5/edit?view_items=0ccNMa7ilC91&invitationId=inv_5b23c2b2-e19b-434c-b6a4-9fcc5f90496c#

            For accounting references, check out the "Release Shares Burning Principal" sub-sheet.
            https://docs.google.com/spreadsheets/d/16JXDzM2PwEOQD-324uwTPVYQbhWbUWnavtKcusaWjzs/edit?usp=sharing
         */
        // Require: Miner Ended is False
        MinerCache memory miner = minersContract.minerStore(owner, minerId);
        unchecked {
    // NOTE: combining the 3 requires below saves 0.078 KB.
    //        require(miner.ended == 0, "f");

            // Require: Miner LEM Claim Day == 0
    //        require(miner.lemClaimDay == 0, "L");

            uint256 promiseEndDay = miner.startDay + miner.promiseDays;
            uint256 cgd = _currentGeniusDay();

            // Require: CGD >= Promise End Day
    //        require(cgd >= promiseEndDay, "E");
            if (miner.auctioned && miner.nonTransferable) {
                revert ErrorCannotReleaseAuctionedShares();
            }
            if (
                miner.ended > 0 ||
                miner.lemClaimDay > 0 ||
                cgd < promiseEndDay ||
                miner.promiseDays == 0
            ) {
                revert ErrorCannotReleaseShares();
            }

            // Set the Miner LEM Claim Day to CGD
            minersContract.setMinerStoreLemClaimDay(owner, minerId, cgd);

            // Calculate Daily Late Fee
            uint256 ceil;
            if (miner.policy) {
                // Need to consider PHI precision
                ceil = _ceiling(miner.principal * PHI_POW_2 / 7 / 100, PHI_PRECISION) / PHI_PRECISION;
            } else {
                // Need to consider PHI precision
                ceil = _ceiling(miner.principal * PHI / 7 / 100, PHI_PRECISION) / PHI_PRECISION;
            }

            // Calculate the LEM Release Reward

            // lemReleaseReward = MIN(principal, lateDayCount * dailyLateFee)
            // NOTE: dailyLateFee = MIN(principal, CEILING(calculation here))
            uint256 lemReleaseReward = _min(miner.principal, (cgd > promiseEndDay + 7 ? cgd - promiseEndDay - 7 : 0)
                * _min(miner.principal, ceil));

            // Check if the miner is under auction and the auction has zero bids.
            if (miner.auctioned) {
                if (auctionHouse.verifyAuctionNoBid(owner, minerId)) {
                    auctionHouse.cancelAuction(owner, minerId);
                }
            }

            // Enforce that at least the first day of the miner was summarized.
            // This prevents a possible underflow when removing the shares from the
            // calendar's share pool.
            uint256 gDay = calendar.geniusDay();
            if (gDay < miner.startDay + 1) {
                calendar.localSummarizeGeniusDay(miner.startDay + 1 - gDay, msg.sender, mintNft);
            }

            if (miner.policy) {
                advLockedSupply -= miner.principal;
                calendar.decAdvShares(miner.rewardShares);
            } else {
                basicLockedSupply -= miner.principal;
                calendar.decBasicShares(miner.rewardShares);
            }

            uint256 minerSettlementAmount;
            if (miner.debtIssueRate > 0) {
                if (lemReleaseReward > 0) {
                    address colToken = stabilityPoolContract.getMinerColAddress(owner, minerId);
                    minerSettlementAmount =
                        stabilityPoolContract.settleGeniusDebt(msg.sender, colToken, lemReleaseReward, cgd - miner.startDay, false);
                    lemReleaseReward = _min(minerSettlementAmount, lemReleaseReward);
                }
            } else {
                calendar.increaseBurnedSupply(miner.principal > lemReleaseReward ? miner.principal - lemReleaseReward : 0);
                if (lemReleaseReward > 0) {
                    _mint(msg.sender, lemReleaseReward);
                }
            }

            if (mintNft && _probability(msg.sender, PHI_NPOW_3, PHI_PRECISION, 0, 0)) {
                _gnftContract.mintNft(msg.sender, 1);
            }

            // By checking the event param, we can have people know that if there is no debt to settle, they actually get no reward.
            emit LemRewardsClaim(msg.sender, owner, minerId, lemReleaseReward);
        }
    }

    /**
     * @dev round up or ceil a number with the precision specified.
     * @param a number to be rounded up or ceiled
     * @param m precision (10^x, where x >= 0) of ceiling the number
     * @return ceiled value
     */
    function _ceiling(uint256 a, uint256 m) internal pure returns (uint256) {
        //return ((a + m - 1) / m) * m;
        unchecked {
            return (a / m + (a % m == 0 ? 0 : 1)) * m;
        }
    }

    /**
     * @dev compare two numbers and return smaller one.
     * @param a number a
     * @param b number b
     * @return smaller value
     */
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev compare two numbers and return greater one.
     * @param a number a
     * @param b number b
     * @return greater value
     */
    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev PUBLIC FACING, executes shutdownMiner core functionality
     * @param owner owner of the miner
     * @param minerId ID(index) of the miner
     */
    function shutdownMiner(address owner, uint256 minerId, bool mintNft)
        external nonReentrant
    {
        MinerCache memory miner = minersContract.minerStore(owner, minerId);
        unchecked {
            // First Late Day = Start Day + Promise Days + 7
            uint256 forcedShutdownDay = miner.policy ?
                miner.startDay + miner.promiseDays + 275 :
                miner.startDay + miner.promiseDays + 440;

            if (
                _currentGeniusDay() < forcedShutdownDay ||
                miner.ended > 0 ||
                miner.auctioned ||
                miner.promiseDays == 0
            ) {
                revert CannotShutdown();
            }

            ShutdownDataCache memory shutdownData =
                _shutdownMiner(miner, owner, minerId, forcedShutdownDay, mintNft);

            if (mintNft && _probability(msg.sender, PHI_NPOW_3, PHI_PRECISION, 0, 0)) {
                _gnftContract.mintNft(msg.sender, 1);
            }

            _mintTokenToOa(owner, minerId, shutdownData.principalToRedistribute,
                shutdownData.rewardsToRedistribute, shutdownData.txPrincipalRewards,
                shutdownData.txPerformanceRewards, miner);
        }
    }

    function _shutdownMiner(
        MinerCache memory miner,
        address owner,
        uint256 minerId,
        uint256 forcedShutdownDay,
        bool mintNft
    ) private returns (ShutdownDataCache memory shutdownData) {
        // Set Miner "ended" to the current time
        minersContract.setMinerEnded(owner, minerId, block.timestamp);
        miner.ended = block.timestamp;
        penaltyContract.decMinerPopulation(miner.principal);
        uint256 lemClaimed = penaltyContract.calcLemClaimed(miner);

        // Before we calculate the rewards, we need to be sure that all
        // SERVED DAYS are Summarized.
        //
        // Then we must make sure all 10-day periods within the SERVED DAYS
        // are also summarized.
        //
        // Then we must make sure all 100-day periods within the SERVED DAYS
        // are summarized.
        //
        // And then, finally, we must make sure that all 1,000-day periods
        // within the SERVED DAYS are summarized.
        calendar.summarizeServedDays(msg.sender, miner.startDay,
            miner.promiseDays, mintNft);
        unchecked {
            uint256 netPrincipal = miner.principal > lemClaimed ? miner.principal - lemClaimed : 0;
            uint256 rewards = miner.rewardShares *
                calendar.minerTotalPps(miner.startDay, miner.startDay + miner.promiseDays - 1, miner.policy)
                / SHARE_PRECISION;
            uint256 netPayout = netPrincipal + rewards;

            // Start Phase EM_04
            _manageShutdownMinerShares(miner, forcedShutdownDay, rewards);
            // End Phase EM_04

            uint256 maxTxRewards = netPayout * PHI_NPOW_3 / PHI_PRECISION;
            shutdownData.txPrincipalRewards = _min(netPrincipal, maxTxRewards);

            if (miner.debtIssueRate > 0) {
                /*
                    Utilities.MinerCache calldata miner,
                    address minerOwner,
                    uint256 minerIndex,
                    address beneficiary,
                    uint256 currentGeniusDay,
                    bool benevolent
                */

                MinerCache memory miner2  = miner;
                bool mintNft2 = mintNft;
                address owner2 = owner;
                uint256 minerId2 = minerId;

                uint256 txSettledRewards = stabilityPoolContract.settleGeniusDebt(
                    msg.sender,
                    stabilityPoolContract.getMinerColAddress(owner2, minerId2),
                    shutdownData.txPrincipalRewards,
                    _currentGeniusDay() - miner2.startDay,
                    mintNft2
                );

                uint256 minerDebtCleared = stabilityPoolContract.clearGeniusDebt(
                    miner2, owner2, minerId2, address(0),
                    _currentGeniusDay(), true);

                shutdownData.txPerformanceRewards = maxTxRewards > txSettledRewards ? maxTxRewards - txSettledRewards : 0;
                shutdownData.txPrincipalRewards -= txSettledRewards;
                // shutdownData.principalToRedistribute = netPrincipal - txSettledRewards - minerDebtCleared -
                // (shutdownData.txPrincipalRewards - txSettledRewards)
                // = netPrincipal - minerDebtCleared - shutdownData.txPrincipalRewards
                // it might be underflow
                uint256 totalSub = txSettledRewards + minerDebtCleared + shutdownData.txPrincipalRewards;
                if (netPrincipal > totalSub) {
                    shutdownData.principalToRedistribute = netPrincipal - totalSub;
                    calendar.increaseBurnedSupply(shutdownData.principalToRedistribute);
                } else {
                    shutdownData.principalToRedistribute = 0;
                }
                shutdownData.rewardsToRedistribute = rewards > shutdownData.txPerformanceRewards ? rewards - shutdownData.txPerformanceRewards : 0;

                if (miner2.lemClaimDay == 0) {
                    if (miner2.policy) {
                        advLockedSupply -= miner2.principal;
                    } else {
                        basicLockedSupply -= miner2.principal;
                    }
                }
            } else { // Debt Issue Rate == 0
                shutdownData.txPerformanceRewards = maxTxRewards > netPrincipal ? maxTxRewards - netPrincipal : 0;
                shutdownData.principalToRedistribute = netPrincipal > shutdownData.txPrincipalRewards ? netPrincipal - shutdownData.txPrincipalRewards : 0;
                shutdownData.rewardsToRedistribute = rewards > shutdownData.txPerformanceRewards ? rewards - shutdownData.txPerformanceRewards : 0;

                if (miner.lemClaimDay == 0)  {
                    calendar.increaseBurnedSupply(miner.principal);
                    if (miner.policy) {
                        advLockedSupply -= miner.principal;
                    } else {
                        basicLockedSupply -= miner.principal;
                    }
                }
            }
        }

    }

    function _mintTokenToOa(
        address owner,
        uint256 minerId,
        uint256 principalToRedistribute,
        uint256 rewardsToRedistribute,
        uint256 txPrincipalRewards,
        uint256 txPerformanceRewards,
        MinerCache memory miner
    ) private {
        unchecked {
            uint256 totalPenalties = principalToRedistribute + rewardsToRedistribute;
            uint256 redistributedPenalties = totalPenalties * PHI_PRECISION / PHI;
            calendar.incDailyPenalties(redistributedPenalties);
            uint256 toOa = totalPenalties - redistributedPenalties - (totalPenalties * PHI_NPOW_3 / PHI_PRECISION);
            uint256 resurrection = toOa + txPrincipalRewards + txPerformanceRewards;

            if (resurrection > 0) {
                calendar.decreaseBurnedSupply(resurrection);
            }

            if (toOa > 0) {
                _mint(oaBeneficiary, toOa);
            }

            // we will not check if txPerf + txPrinc is > 0 because if this is the
            // case, then the miner was likely a stale, "dust" miner with not much
            // principal and likely zero earnings.
            _mint(msg.sender, txPerformanceRewards + txPrincipalRewards);

            emit ShutdownMiner(owner, minerId, msg.sender,
                txPrincipalRewards, txPerformanceRewards,
                redistributedPenalties, toOa, (totalPenalties * PHI_NPOW_3 / PHI_PRECISION),
                miner
            );
        }
    }

    /**
     * @dev INTERNAL, helper function used in shutdownMiner()
     */
    function _manageShutdownMinerShares(
        MinerCache memory miner, uint256 forcedShutdownDay, uint256 rewards
    ) internal {
        if (miner.lemClaimDay == 0) {
            if (!miner.policy) {
                calendar.decBasicShares(miner.rewardShares);
            } else {
                calendar.decAdvShares(miner.rewardShares);
            }
        }
        unchecked {
            calendar.setShareRate(_newShareRate(miner, miner.principal + rewards));
        }
    }

    /**
     * @dev only callable by calendar, mint summary rewards calculated by
     * summarize functions in calendar.
     */
    function mintSummaryReward(address _to, uint256 _amount) external {
        if (msg.sender != calendarAddress) {
            revert ErrorUnauthorized();
        }
        _mint(_to, _amount);
    }

    /**
     * @dev only callable by Penalty contract, advLockedSupply accounting.
     */
    function decAdvLockedSupply(uint256 _amount) external {
        if (msg.sender != penaltyAddress) revert ErrorUnauthorized();
        unchecked { advLockedSupply -= _amount; }
    }

    /**
     * @dev only callable by Penalty contract, basicLockedSupply accounting.
     */
    function decBasicLockedSupply(uint256 _amount) external {
        if (msg.sender != penaltyAddress) revert ErrorUnauthorized();
        unchecked { basicLockedSupply -= _amount; }
    }

    /**
     * @dev only callable by Miners contract, advLockedSupply accounting.
     */
    function incAdvLockedSupply(uint256 _amount) external {
        if (msg.sender != minersAddress) revert ErrorUnauthorized();
        unchecked { advLockedSupply += _amount; }
    }

    /**
     * @dev only callable by Miners contract, basicLockedSupply accounting.
     */
    function incBasicLockedSupply(uint256 _amount) external {
        if (msg.sender != minersAddress) revert ErrorUnauthorized();
        unchecked { basicLockedSupply += _amount; }
    }

    /**
     * @dev only called by the End Miner functionality; this redistributes
     * fees incurrred for ending the miner.
     * @param rewards the performance earnings of the miner.
     * @param principalPenalties penalties applied to the principal.
     * @param rewardPenalties penalties applied to the rewards.
     * @return redistributedPenalties the amount of penalties that will be
     * redistributed to Advanced Miners that are currently active.
     */
    function _redistribution(
        MinerCache memory miner,
        uint256 rewards,
        uint256 principalPenalties,
        uint256 rewardPenalties
    ) internal returns (uint256 redistributedPenalties) {
        unchecked {
            uint256 totalPenalties;
            if (miner.debtIssueRate > 0) {
                totalPenalties = _min(rewards, principalPenalties + rewardPenalties);
                rewardPenalties = totalPenalties;
                principalPenalties = 0;
            } else {
                if (miner.lemClaimDay == 0) {
                    if (miner.policy) {
                        advLockedSupply -= principalPenalties;
                    } else {
                        basicLockedSupply -= principalPenalties;
                    }
                    calendar.increaseBurnedSupply(principalPenalties);
                }
                totalPenalties = principalPenalties + rewardPenalties;
            }

            redistributedPenalties = totalPenalties * PHI_PRECISION / PHI;
            calendar.incDailyPenalties(redistributedPenalties);
            uint256 oaReceivingAmount = totalPenalties - redistributedPenalties
                - totalPenalties * PHI_NPOW_3 / PHI_PRECISION;

            _mint(oaBeneficiary, oaReceivingAmount);
            calendar.decreaseBurnedSupply(oaReceivingAmount);
        }
    }

    /**
     * @dev   Calculates a secure-ish random 256-bit number for GENFTs.
     *        These are the motivations and purposes behind each parameter to
     *        calculate the random number:
     *
     *        1. salt: each function that initially invokes the first
     *           _probability / _random functions will originate with its own
     *           unique 'salt'.  This is to ensure that when multiple functions
     *           are called by the EOA within the same transaction, the EOA will
     *           have equally-random chances to yield a completely different
     *           GENFT.  The block timestamp is added to salt to make it more
     *           difficult for an end user to predict which GENFT they'll mint.
     *
     *        2. blockhash: the only EOAs that can reasonably use this to their
     *           advantage without adding significant costs for the transaction,
     *           such as the capital required to create a miner with a weight of
     *           1 or greater, are EOAs that run the function to "claim" their
     *           sacrifie tokens and EOAs that run the function to summarize
     *           a Genius Calendar period.  That is because these functions have
     *           a 100% chance to mint a GENFT.
     *
     *           However, the "claim" function can only be run once per EOA that
     *           participated in the Genius Sacrifice Event.  Therefore, this
     *           will not be useful for the EOA, even if they have the ability
     *           to influence the block hash.  See: https://sacrifice.to
     *
     *           In regards to the Calendar summarize functions, the EOA cannot
     *           waste time figuring out their best chances because if they are
     *           not the first EOA to run the function, then they lose the
     *           ability to run the function for the day/period.
     *
     *           For every other function, the EOA is prevented from spamming
     *           these functions not only from the blockchain's gas fee, but
     *           spam is additional prevented because every other function
     *           has one of the following qualities:
     *              a. It is a "first-come, first-to-benefit" function, e.g. the
     *                 functions to claimAuction, releaseShares, etc.
     *              b. The function is necessary for "cleaning up" or updating
     *                 Genius' environment, active shares, etc., and therefore,
     *                 the EOA should be rewarded as they wish.
     *              c. The EOA had to have input something of value to the
     *                 network, i.e. they had to put up a significant, non-dust
     *                 amount of GENI capital, which ultimately benefitted the
     *                 Genius end users.
     *
     *           Therefore, if it is worth it for the EOA to exert the position-
     *           ing and effort to influence random numbers for their purpose,
     *           then this action is also not guaranteed, and its repeated
     *           action is designed to benefit the Genius end user.  Since the
     *           purpose of GENFTs is purely as collectibles and *not* for
     *           significant financial value, it is perfectly acceptable for
     *           EOAs to "game" the possibilities of yielding the GENFT that
     *           they desire.
     *
     *        3. account: used so that different EOAs running the same GENFT
     *           minting functions within the same block will not generate the
     *           same GENFTs.  Likewise, if different accounts are unpacking
     *           booster/ultimate packs within the same transaction, this will
     *           ensure that the end users do not unpack the same GENFTs.
     *
     *        Finally, it should be noted that the GENFT controller prevents
     *        EOAs from minting GENFTs with the same randomization salt or
     *        unpacking to mint multiple GENFTs within the same block.  This is
     *        done to prevent the end user from duplicating multiple copies of
     *        the same GENFTs.
     *
     * @param account address used to generate a random number
     * @param salt  when multiple random numbers are necessary, this is used
     *                to add some randomness.  This is important because within
     *                a single transaction, the random number will be exactly
     *                the same without this _salt.
     */
    function _random(address account, uint256 salt) internal view returns (uint256) {
        unchecked {
            return uint256(
                keccak256(
                    abi.encodePacked(
                        salt + block.timestamp,
                        blockhash(block.number),
                        account
                    )
                )
            );
        }
    }

    /**
     * @dev     You tell the function the "probability" that something will
     *          happen, and this function tells you if it happened :)
     * @param   account address used for the calculation
     * @param   chances How many chances of successes will there be out of the entire...
     * @param   totals ...range of precision totals?
     * @param   weight will the weight be based on?  Use "0" for no weight.
     * @param   nonce "nonce" so that if this function is called multiple times
     *          within a transaction, the random number will be different each
     *          time this function is invoked.
     * @return  Whether the probability test was succcessful :)
     */
    function _probability(address account, uint256 chances, uint256 totals, uint256 weight, uint256 nonce)
        internal view returns (bool)
    {
        unchecked {
            // STEP 1: increase the weight of the chances if necessary.
            if (weight > 0) {
                chances = chances * penaltyContract.minerWeight(weight)
                    / PENALTY_COUNTER_PRECISION;
            }

            if (chances >= totals) {
                return true;
            }

            // NOTE: beyond this point, chances < totals, and therefore, it is not
            // possible for chances to be equal to or greater than totals, resulting
            // in an overflow.

            // STEP 2: Find a random number between 0 and the totals.
            uint256 random = _random(account, nonce) % totals;

            // STEP 3: Is the random number within the probability range of chance?
            // The minimum that (totals - chances) will be is 1, so therefore, if
            // the random number is 0, then the return value will be false.  In the
            // situation where this is a "1 in X" chance, "random" must be 0 in
            // order for the logical expression (below) to be true.
            return random >= totals - chances;
        }
    }

}