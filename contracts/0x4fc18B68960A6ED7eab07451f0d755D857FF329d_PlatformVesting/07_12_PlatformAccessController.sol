// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../admin_panel/PlatformAdminPanel.sol";

/**
 * @title Abstract contract from which platform contracts with admin function are inherited
 * @dev Contains the platform admin panel
 * Contains modifier that checks whether sender is platform admin, use platform admin panel
 */
abstract contract PlatformAccessController {
    address public _panel;

    error CallerNotAdmin();
    error AlreadyInitialized();

    function _initiatePlatformAccessController(address adminPanel) internal {
        if(address(_panel) != address(0))
            revert AlreadyInitialized();

        _panel = adminPanel;
    }

    /**
     * @dev Modifier that makes function available for platform admins only
     */
    modifier onlyPlatformAdmin() {
        if(!PlatformAdminPanel(_panel).isAdmin(msgSender()))
            revert CallerNotAdmin();
        _;
    }

    function _isAdmin() internal view returns (bool) {
        return PlatformAdminPanel(_panel).isAdmin(msgSender());
    }

    function msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}