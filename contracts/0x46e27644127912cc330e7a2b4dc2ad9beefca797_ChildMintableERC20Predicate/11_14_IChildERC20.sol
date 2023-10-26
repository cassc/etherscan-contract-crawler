// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of IChildERC20
 */
interface IChildERC20 is IERC20MetadataUpgradeable {
    /**
     * @dev Sets the values for {rootToken}, {name}, {symbol} and {decimals}.
     *
     * All these values are immutable: they can only be set once during
     * initialization.
     */
    function initialize(address rootToken_, string calldata name_, string calldata symbol_, uint8 decimals_) external;

    /**
     * @notice Returns predicate address controlling the child token
     * @return address Returns the address of the predicate
     */
    function predicate() external view returns (address);

    /**
     * @notice Returns predicate address controlling the child token
     * @return address Returns the address of the predicate
     */
    function rootToken() external view returns (address);

    /**
     * @notice Mints an amount of tokens to a particular address
     * @dev Can only be called by the predicate address
     * @param account Account of the user to mint the tokens to
     * @param amount Amount of tokens to mint to the account
     * @return bool Returns true if function call is successful
     */
    function mint(address account, uint256 amount) external returns (bool);

    /**
     * @notice Burns an amount of tokens from a particular address
     * @dev Can only be called by the predicate address
     * @param account Account of the user to burn the tokens from
     * @param amount Amount of tokens to burn from the account
     * @return bool Returns true if function call is successful
     */
    function burn(address account, uint256 amount) external returns (bool);
}