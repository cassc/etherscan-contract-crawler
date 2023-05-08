// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an manager) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the manager account will be the one that deploys the contract. This
 * can later be changed with {transferManagership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
contract ManagerLikeOwner is Context {
    address private _manager;

    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    function _initializeManager(address manager_)
        internal
    {
        _transferManagership(manager_);
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager()
        public view
        returns (address)
    {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(_manager == _msgSender(), "ManagerIsOwner: caller is not the manager");
        _;
    }

    /**
     * @dev Leaves the contract without manager. It will not be possible to call
     * `onlyManager` functions anymore. Can only be called by the current manager.
     *
     * NOTE: Renouncing managership will leave the contract without an manager,
     * thereby removing any functionality that is only available to the manager.
     */
    function renounceManagership()
        virtual
        public
        onlyManager
    {
        _beforeTransferManager(address(0));

        emit ManagershipTransferred(_manager, address(0));
        _manager = address(0);
    }

    /**
     * @dev Transfers managership of the contract to a new account (`newManager`).
     * Can only be called by the current manager.
     */
    function transferManagership(address newManager)
        virtual
        public
        onlyManager
    {
        _transferManagership(newManager);
    }

    function _transferManagership(address newManager)
        virtual
        internal
    {
        require(newManager != address(0), "ManagerIsOwner: new manager is the zero address");
        _beforeTransferManager(newManager);

        emit ManagershipTransferred(_manager, newManager);
        _manager = newManager;
    }

    /**
     * @dev Hook that is called before manger transfer. This includes initialize and renounce
     */
    function _beforeTransferManager(address newManager)
        virtual
        internal
    {}
}