// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract TransferLockableUpgradable is
        ERC20Upgradeable,
        AccessControlUpgradeable
    {
    bytes32 public constant TRASFER_AGENT_ROLE = keccak256("TRASFER_AGENT_ROLE");

    bool private _transferLocked;

    /**
     * @dev Emitted when the transfer unlocked is triggered by `account`.
     */
    event TokenTransferUnlocked(address account);

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __TransferLockableUpgradable_init() internal onlyInitializing {
        __TransferLockableUpgradable_init_unchained();
    }

    function __TransferLockableUpgradable_init_unchained() internal onlyInitializing {
        _transferLocked = true;
    }

    /**
     * Limit token transfer until the crowdsale is over.
     *
     */
    modifier whenNotTransferLocked(address _sender) {
        _requireNotTransferLocked(_sender);
        _;
    }

    function _requireNotTransferLocked(address _sender) internal view virtual {
        if (_transferLocked) {
            require((hasRole(TRASFER_AGENT_ROLE, _sender) || hasRole(DEFAULT_ADMIN_ROLE, _sender)));
        }
    }

    /**
     * One way function to release the tokens to the wild.
     *
     * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
     */
    function unsetTransferLock() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _transferLocked = false;
        emit TokenTransferUnlocked(_msgSender());
    }

    function isTransferLocked() 
        external view 
        returns (bool) 
    {
        return _transferLocked;
    }
}