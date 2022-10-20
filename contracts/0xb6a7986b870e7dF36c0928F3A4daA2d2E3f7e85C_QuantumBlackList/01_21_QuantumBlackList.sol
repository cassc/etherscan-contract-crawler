// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IQuantumBlackList.sol";
import "./QuantumBlackListStorage.sol";
import "./ManageableUpgradeable.sol";

error AlreadyBlackListed();
error NotBlackListed(address _address);

contract QuantumBlackList is
    IQuantumBlackList,
    OwnableUpgradeable,
    ManageableUpgradeable,
    UUPSUpgradeable
{
    using QuantumBlackListStorage for QuantumBlackListStorage.Layout;

    event BlackListAddress(address indexed user, bool isBlackListed);

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    function initialize(address admin) public initializer {
        __QuantumBlackList_init(admin);
    }

    function __QuantumBlackList_init(address admin) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __QuantumBlackList_init_unchained(admin);
    }

    function __QuantumBlackList_init_unchained(address admin)
        internal
        onlyInitializing
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  PERMISSIONS  <<<<<<<<<<<<<<<<<<<<<< ///

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice set address of the minter
    /// @param owner The address of the new owner
    function setOwner(address owner) public onlyOwner {
        transferOwnership(owner);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function setManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function unsetManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  CORE FUNCTIONALITY  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice bulk add addresses to blackList
    /// @param users The list of address to add to the blackList
    function addToBlackList(address[] calldata users)
        public
        onlyRole(MANAGER_ROLE)
    {
        QuantumBlackListStorage.Layout storage qbl = QuantumBlackListStorage
            .layout();

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];

            if (user != address(0) && !qbl.blackList[user]) {
                qbl.blackList[user] = true;
                emit BlackListAddress(user, true);
            }
        }
    }

    /// @notice remove single address from blackList
    /// @param user The address to remove from the blackList
    function removeFromBlackList(address user) public onlyRole(MANAGER_ROLE) {
        QuantumBlackListStorage.Layout storage qbl = QuantumBlackListStorage
            .layout();

        if (qbl.blackList[user]) {
            qbl.blackList[user] = false;
            emit BlackListAddress(user, false);
        } else {
            revert NotBlackListed(user);
        }
    }

    function isBlackListed(address user) public view returns (bool) {
        return QuantumBlackListStorage.layout().blackList[user];
    }
}