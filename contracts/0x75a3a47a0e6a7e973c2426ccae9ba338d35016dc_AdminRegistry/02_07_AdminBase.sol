// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "../admin/interfaces/IAdminRegistry.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AdminBase is OwnableUpgradeable, IAdminRegistry {
    //admin role keys
    uint8 public PENDING_ADD_ADMIN_KEY;
    uint8 public PENDING_EDIT_ADMIN_KEY;
    uint8 public PENDING_REMOVE_ADMIN_KEY;
    //ADD,EDIT,REMOVE
    uint8[] public PENDING_KEYS;

    /// @dev approve admin roles for each address
    /// @dev Stores the key address for roles
    mapping(address => AdminAccess) public approvedAdminRoles;

    //list of all approved admin addresses 
    address[] public allApprovedAdmins;

    /// mapping of admin role keys to admin addresses to admin access roles
    mapping(uint8 => mapping(address => AdminAccess)) public pendingAdminRoles;
    //keys of admin role keys to admin addresses
    address[][] public pendingAdminKeys;

    /// @dev list of admins approved by other admins, for the specific key
    mapping(uint8 => mapping(address => address[])) public areByAdmins;
    event NewAdminApproved(
        address indexed _newAdmin,
        address indexed _addByAdmin,
        uint8 indexed _key
    );
    event NewAdminApprovedByAll(
        address indexed _newAdmin,
        AdminAccess _adminAccess
    );
    event AdminRemovedByAll(
        address indexed _admin,
        address indexed _removedByAdmin
    );
    event AdminEditedApprovedByAll(
        address indexed _admin,
        AdminAccess _adminAccess
    );
    event AddAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event EditAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event RemoveAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event SuperAdminOwnershipTransfer(
        address indexed _superAdmin,
        AdminAccess _adminAccess
    );

    // access-modifier for adding gov admin
    modifier onlyAddGovAdminRole(address _admin) {
        require(
            approvedAdminRoles[_admin].addGovAdmin,
            "GAR: not add or edit admin role"
        );
        _;
    }

    // access-modifier for editing gov admin
    modifier onlyEditGovAdminRole(address _admin) {
        require(
            approvedAdminRoles[_admin].editGovAdmin,
            "GAR: not edit admin role"
        );
        _;
    }

    /// @dev Checks if a given _newAdmin is not approved by the _approvedBy admin.
    /// @param _newAdmin Address of the new admin
    /// @param _by Address of the existing admin that may have approved/edited/removed _newAdmin already.
    /// @param _key Address of the existing admin that may have approved/edited/removed _newAdmin already.
    /// @return bool returns true or false value

    function _notAvailable(
        address _newAdmin,
        address _by,
        uint8 _key
    ) internal view returns (bool) {
        uint256 pendingKeyslength = PENDING_KEYS.length;
        for (uint256 k = 0; k < pendingKeyslength; k++) {
            if (_key == PENDING_KEYS[k]) {
                uint256 approveByAdminsLength = areByAdmins[_key][_newAdmin]
                    .length;
                for (uint256 i = 0; i < approveByAdminsLength; i++) {
                    if (areByAdmins[_key][_newAdmin][i] == _by) {
                        return false; //approved/edited/removed
                    }
                }
            }
        }
        return true; //not approved/edited/removed
    }

    /// @dev makes _newAdmin an approved admin and emits the event
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makeDefaultApproved(
        address _newAdmin,
        AdminAccess memory _adminAccess
    ) internal {
        //no need for approved by admin for the new  admin anymore.
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        emit NewAdminApprovedByAll(_newAdmin, _adminAccess);
    }

    /// @dev makes _newAdmin an approved admin and emits the event
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makeApproved(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {
        //no need for approved by admin for the new  admin anymore.
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        _removePendingIndex(
            _getIndex(_newAdmin, pendingAdminKeys[PENDING_ADD_ADMIN_KEY]),
            PENDING_ADD_ADMIN_KEY
        );
    }

    /// @dev makes _newAdmin a pending admin for approval to be given by all current admins
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makePendingForAddEdit(
        address _newAdmin,
        AdminAccess memory _adminAccess,
        uint8 _key
    ) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        areByAdmins[_key][_newAdmin].push(msg.sender);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingAdminRoles[_key][_newAdmin] = _adminAccess;
        pendingAdminKeys[_key].push(_newAdmin);
        emit NewAdminApproved(_newAdmin, msg.sender, _key);
    }

    /// @dev remove _admin by the approved admins
    /// @param _admin Address of the approved admin

    function _removeAdmin(address _admin) internal {
        // _admin is now a removed admin.
        delete approvedAdminRoles[_admin];
        delete areByAdmins[PENDING_REMOVE_ADMIN_KEY][_admin];
        delete areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin];
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_REMOVE_ADMIN_KEY][_admin];

        //remove key for mapping approvedAdminRoles
        _removeIndex(_getIndex(_admin, allApprovedAdmins));
        _removePendingIndex(
            _getIndex(_admin, pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]),
            PENDING_REMOVE_ADMIN_KEY
        );

        emit AdminRemovedByAll(_admin, msg.sender);
    }

    /// @dev edit admin roles of the approved admin
    /// @param _admin address which is going to be edited

    function _editAdmin(address _admin) internal {
        approvedAdminRoles[_admin] = pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][
            _admin
        ];

        delete areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_admin];
        _removePendingIndex(
            _getIndex(_admin, pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]),
            PENDING_EDIT_ADMIN_KEY
        );

        emit AdminEditedApprovedByAll(_admin, approvedAdminRoles[_admin]);
    }

    /// @dev remove the index of the approved admin address
    function _removeIndex(uint256 index) internal {
        uint256 length = allApprovedAdmins.length;
        for (uint256 i = index; i < length - 1; i++) {
            allApprovedAdmins[i] = allApprovedAdmins[i + 1];
        }
        allApprovedAdmins.pop();
    }

    /// @dev remove the pending admin index for that specific key
    function _removePendingIndex(uint256 index, uint8 key) internal {
        uint256 length = pendingAdminKeys[key].length;
        for (uint256 i = index; i < length - 1; i++) {
            pendingAdminKeys[key][i] = pendingAdminKeys[key][i + 1];
        }
        pendingAdminKeys[key].pop();
    }

    /// @dev makes _admin a pending admin for approval to be given by
    /// @dev all current admins for removing this admnin.
    /// @param _admin address of the new admin which is going pending for remove

    function _makePendingForRemove(address _admin, uint8 _key) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        areByAdmins[_key][_admin].push(msg.sender);
        pendingAdminKeys[_key].push(_admin);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingAdminRoles[_key][_admin] = approvedAdminRoles[_admin];
        emit NewAdminApproved(_admin, msg.sender, _key);
    }

    function _getIndex(address _valueToFindAndRemove, address[] memory from)
        internal
        pure
        returns (uint256 index)
    {
        uint256 length = from.length;
        for (uint256 i = 0; i < length; i++) {
            if (from[i] == _valueToFindAndRemove) {
                return i;
            }
        }
    }

    /// @dev check if the address exist in the pending admins array
    function _addressExists(address _valueToFind, address[] memory from)
        internal
        pure
        returns (bool)
    {
        uint256 length = from.length;
        for (uint256 i = 0; i < length; i++) {
            if (from[i] == _valueToFind) {
                return true;
            }
        }
        return false;
    }

    function isAddGovAdminRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addGovAdmin;
    }

    /// @dev using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editGovAdmin;
    }

    /// @dev using this function externally in other Smart Contracts
    function isAddTokenRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addToken;
    }

    /// @dev using this function externally in other Smart Contracts
    function isEditTokenRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editToken;
    }

    /// @dev using this function externally in other Smart Contracts
    function isAddSpAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addSp;
    }

    /// @dev using this function externally in other Smart Contracts
    function isEditSpAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editSp;
    }


    /// @dev using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].superAdmin;
    }
}