// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    /**
     * @notice This function is used to initialize the context of the contract.
     * @dev This function should only be called during the initialization of the contract.
     */
    function __Context_init() internal onlyInitializing {
    }

    /**
     * @notice This function is used to initialize the context for unchained.
     * @dev This function should only be called during the initialization process.
     */
    function __Context_init_unchained() internal onlyInitializing {
    }
    /**
     * @notice This function returns the address of the sender of the current message.
     * @dev This function is an internal view function and is used to get the address of the sender of the current message.
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @notice This function returns the data of the message sent to the contract.
     * @dev This function is internal and view, meaning it can only be called from within the contract and does not modify the state of the contract. It returns the data of the message sent to the contract as a bytes calldata.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}