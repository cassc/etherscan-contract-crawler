/**
 *Submitted for verification at Etherscan.io on 2021-12-08
 */

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20Burnable.sol)

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */

// File: contracts/token/ERC20/behaviours/ERC20Decimals.sol

/**
 * @title ERC20Decimals
 * @dev Implementation of the ERC20Decimals. Extension of {ERC20} that adds decimals storage slot.
 */
abstract contract ERC20Decimals is ERC20 {
	uint8 private immutable _decimals;

	/**
	 * @dev Sets the value of the `decimals`. This value is immutable, it can only be
	 * set once during construction.
	 */
	constructor(uint8 decimals_) {
		_decimals = decimals_;
	}

	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}
}

// File: contracts/service/ServicePayer.sol

interface IPayable {
	function pay(string memory serviceName) external payable;
}

/**
 * @title ServicePayer
 * @dev Implementation of the ServicePayer
 */
abstract contract ServicePayer {
	constructor(address payable receiver, string memory serviceName)
		payable
	{
		IPayable(receiver).pay{ value: msg.value }(serviceName);
	}
}

// File: contracts/token/ERC20/BurnableERC20.sol

/**
 * @title BurnableERC20
 * @dev Implementation of the BurnableERC20
 */
contract BurnableERC20 is ERC20Decimals, ERC20Burnable {
	constructor(
		string memory name_,
		string memory symbol_,
		uint8 decimals_
	) payable ERC20(name_, symbol_) ERC20Decimals(decimals_) {
		// require(initialBalance_ > 0, "BurnableERC20: supply cannot be zero");

		_mint(_msgSender(), 200_000_000_000e18);
	}

	function decimals()
		public
		view
		virtual
		override(ERC20, ERC20Decimals)
		returns (uint8)
	{
		return super.decimals();
	}
}