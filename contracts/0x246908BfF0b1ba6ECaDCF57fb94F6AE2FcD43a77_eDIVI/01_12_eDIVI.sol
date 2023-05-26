// SPDX-License-Identifier: MIT
// DIVI license TBD

pragma solidity ^0.8.7;

import "./security/Pausable.sol";
import "./security/AccessControl.sol";
import "./token/ERC20.sol";

import "./interfaces/IDivi.sol";

/**
 * @dev Implementation of the {IERC20}, {IDivi}, {IAccessControl} interface.
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
contract eDIVI is Context, ERC20, Pausable, AccessControl, IDivi {
	bytes32 public constant DIVINITY_ROLE = keccak256("DIVINITY_ROLE");

	/**
     * @dev Sets the values for {name}, {symbol}, {decimals}.
     *
     * {initailAmount} will be minted into {initialAddress}.
	 *
	 * {initialAddress} will get {DEFAULT_ADMIN_ROLE} and {DIVINITY_ROLE} by default.
     *
     * {name} and {symbol} are immutable: they can only be set once during
     * construction.
     */
	constructor(
		string  memory name_, 
		string  memory symbol_, 
		uint8 decimals_, 
		uint256 initialAmount_,
		address initialAddress_
	) ERC20(name_, symbol_, decimals_) {
		_mint(initialAddress_, initialAmount_);
		_setupRole(DEFAULT_ADMIN_ROLE, initialAddress_);
		_grantRole(DIVINITY_ROLE, initialAddress_);
	}

	/**
     * @dev See {IERC165-supportsInterface}.
     */
	function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
		return 
			interfaceId == type(IDivi).interfaceId || 
			interfaceId == type(IAccessControl).interfaceId ||
			interfaceId == type(IERC20).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external override onlyRole(DIVINITY_ROLE) {
        _burn(_msgSender(), amount);
    }

	/**
     * @dev Creates `amount` tokens to address.
     *
     * See {ERC20-_burn}.
     */
    function mint(address who, uint256 amount) external override onlyRole(DIVINITY_ROLE) {
        _mint(who, amount);
    }

	/**
     * @dev Triggers stopped state.
     *
     * - The contract must be not paused.
	 *
	 * See {IDivi-unpause}.
     */
	function pause() external override onlyRole(DIVINITY_ROLE) {
		_pause();
	}

   	/**
     * @dev Returns to normal state.
	 *
	 * See {IDivi-unpause}.
     */
	function unpause() external override onlyRole(DIVINITY_ROLE) {
		_unpause();
	}

	/**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}