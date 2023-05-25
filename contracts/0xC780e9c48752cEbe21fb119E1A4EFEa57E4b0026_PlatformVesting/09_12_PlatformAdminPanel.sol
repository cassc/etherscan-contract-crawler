// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./Iplatform_admin_panel/IPlatformAdminPanel.sol";

/**
 * @title Platform admins holder contract
 * @notice Used to check accessibility of senders to admin functions in platform contracts
 */
contract PlatformAdminPanel is IPlatformAdminPanel {
    /**
     * @notice Emit during root admin set and reset
     */
    event SetRootAdmin(address indexed wallet);

    event InsertAdminList(address[] adminList);

    event RemoveAdminList(address[] adminList);

    mapping(address => bool) private _adminMap;
    address private _rootAdmin;

    modifier onlyRootAdmin() {
        require(_rootAdmin == msg.sender, "sender is not root admin");
        _;
    }

    /**
     * @notice Specify the root admin, only he has the rights to add and remove admins
     */
    constructor(address rootAdminWallet) {
        _setRootAdmin(rootAdminWallet);
    }

    /**
     * @notice Needed to determine if the user has admin rights for platform contracts
     */
    function isAdmin(address wallet)
        external
        view
        virtual
        override
        returns (bool)
    {
        return wallet == _rootAdmin || _adminMap[wallet];
    }

    function rootAdmin() external view returns (address) {
        return _rootAdmin;
    }

    /**
     * @notice Only root admin can call
     */
    function insertAdminList(address[] calldata adminList)
        external
        onlyRootAdmin
    {
        require(0 < adminList.length, "empty admin list");

        uint256 index = adminList.length;
        while (0 < index) {
            --index;

            _adminMap[adminList[index]] = true;
        }

        emit InsertAdminList(adminList);
    }

    /**
     * @notice Only root admin can call
     */
    function removeAdminList(address[] calldata adminList)
        external
        onlyRootAdmin
    {
        require(0 < adminList.length, "empty admin list");

        uint256 index = adminList.length;
        while (0 < index) {
            --index;

            _adminMap[adminList[index]] = false;
        }

        emit RemoveAdminList(adminList);
    }

    /**
     * @notice Only root admin can call
     */
    function setRootAdmin(address rootAdminWallet) external onlyRootAdmin {
        _setRootAdmin(rootAdminWallet);
    }

    function _setRootAdmin(address wallet) private {
        require(wallet != address(0), "wallet is zero address");

        _rootAdmin = wallet;

        emit SetRootAdmin(wallet);
    }
}