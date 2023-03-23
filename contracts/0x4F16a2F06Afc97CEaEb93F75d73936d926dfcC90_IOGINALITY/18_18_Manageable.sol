// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Manageable is Ownable {

    // the manager of contract from marketplace side
    address private _manager;

    event ManagershipTransfered(address newManager, address oldManager);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        _checkManager();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkManager() internal view virtual {
        require(manager() == _msgSender(), "Caller is not the manager of contract");
    }

    function manager() public view returns(address)
    {
        return _manager;
    }

    function transferMangership(address newManager) onlyOwner
        public
    {
        require(newManager != address(0), 'Manager can not be a null address');

        _transferMangership(newManager);
    }

    function _transferMangership(address newManager)
        internal virtual
    {
        address oldManager = _manager;
        _manager = newManager;

        emit ManagershipTransfered(_manager, oldManager);
    }
}