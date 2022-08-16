// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./AdminBase.sol";

/// @title GovWorld Admin Registry Contract
/// @dev using this contract for all the access controls in Gov Loan Builder

contract AdminRegistry is AdminBase {
    address public superAdmin;

    /// @dev using upgradeable contract inherited in the AdminBase Contract
    /// @param _superAdmin the superAdmin control all the setter functions like Platform Fee, AutoSell Fee
    /// @param _admin1 default admin 1
    /// @param _admin2 default admin 2
    /// @param _admin3 default admin 3
    function initialize(
        address _superAdmin,
        address _admin1,
        address _admin2,
        address _admin3
    ) external initializer {
        __Ownable_init();
        pendingAdminKeys = new address[][](3);

        //owner becomes the default admin.
        _makeDefaultApproved(
            _superAdmin,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );

        _makeDefaultApproved(
            _admin1,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        _makeDefaultApproved(
            _admin2,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        _makeDefaultApproved(
            _admin3,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        superAdmin = _superAdmin;

        PENDING_ADD_ADMIN_KEY = 0;
        PENDING_EDIT_ADMIN_KEY = 1;
        PENDING_REMOVE_ADMIN_KEY = 2;
        //  ADD,EDIT,REMOVE
        PENDING_KEYS = [0, 1, 2];
    }

    /// @dev function to transfer super admin roles to the other new admin
    /// @param _newSuperAdmin address from the existing approved admins
    function transferSuperAdmin(address _newSuperAdmin) external returns(bool){
        require(_newSuperAdmin != address(0), "invalid address");
        require(_newSuperAdmin != superAdmin, "already designated");
        require(msg.sender == superAdmin, "not super admin");

        uint256 lengthofApprovedAdmins = allApprovedAdmins.length;
        for (uint256 i = 0; i < lengthofApprovedAdmins; i++) {
            if (allApprovedAdmins[i] == _newSuperAdmin) {
                approvedAdminRoles[_newSuperAdmin].superAdmin = true;
                approvedAdminRoles[superAdmin].superAdmin = false;
                superAdmin = _newSuperAdmin;

                emit SuperAdminOwnershipTransfer(
                    _newSuperAdmin,
                    approvedAdminRoles[_newSuperAdmin]
                );
                return true;
            }
        }
        revert("Only admin can become super admin");
    }

    /// @dev Checks if a given _newAdmin is approved by all other already approved amins
    /// @param _newAdmin Address of the new admin
    /// @param _key specify the add, edit or remove key

    function isDoneByAll(address _newAdmin, uint8 _key)
        external
        view
        returns (bool)
    {
        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _areByAdmins = areByAdmins[_key][_newAdmin];

        uint256 presentCount = 0;
        uint256 allCount = 0;
        //get All admins with add govAdmin rights
        uint256 lengthAllApprovedAdmins = allApprovedAdmins.length;
        for (uint256 i = 0; i < lengthAllApprovedAdmins; i++) {
            if (
                _key == PENDING_ADD_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].addGovAdmin &&
                allApprovedAdmins[i] != _newAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == PENDING_REMOVE_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin &&
                allApprovedAdmins[i] != _newAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == PENDING_EDIT_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin &&
                allApprovedAdmins[i] != _newAdmin //all but yourself.
            ) {
                allCount = allCount + 1;
                //needs to check availability for all allowed admins to approve in editByAdmins.
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
        }
        // standard multi-sig 51 % approvals needed to perform
        if (presentCount >= (allCount / 2) + 1) return true;
        else return false;
    }

    /// @dev makes _newAdmin an approved admin if there is only one curernt admin _newAdmin becomes
    /// @dev becomes approved as it is and if currently more then 1 admins then approveAddedAdmin needs to be
    /// @dev called  by all current admins
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function addAdmin(address _newAdmin, AdminAccess memory _adminAccess)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(
            _adminAccess.addGovIntel ||
                _adminAccess.editGovIntel ||
                _adminAccess.addToken ||
                _adminAccess.editToken ||
                _adminAccess.addSp ||
                _adminAccess.editSp ||
                _adminAccess.addGovAdmin ||
                _adminAccess.editGovAdmin ||
                _adminAccess.addBridge ||
                _adminAccess.editBridge ||
                _adminAccess.addPool ||
                _adminAccess.editPool,
            "GAR: admin roles error"
        );
        require(pendingAdminKeys[PENDING_ADD_ADMIN_KEY].length == 0 && pendingAdminKeys[PENDING_EDIT_ADMIN_KEY].length == 0 && pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY].length == 0, "GAR: only one admin can be add, edit, remove at once");
        require(_newAdmin != address(0), "invalid address");
        require(_newAdmin != msg.sender, "GAR: call for self"); //the GovAdmin cannot add himself as admin again
       
        require(
            !_addressExists(_newAdmin, allApprovedAdmins),
            "GAR: cannot add again"
        );
        require(!_adminAccess.superAdmin, "GAR: superadmin assign error");

        if (allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
            _makeDefaultApproved(_newAdmin, _adminAccess);
        } else {
            //this admin is now in the pending list.
            _makePendingForAddEdit(
                _newAdmin,
                _adminAccess,
                PENDING_ADD_ADMIN_KEY
            );
        }
        performPendingActions();
    }

    /// @dev call approved the admin which is already added to pending by other admin
    /// @dev if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
    /// @param _newAdmin Address of the new admin

    function approveAddedAdmin(address _newAdmin)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_newAdmin != msg.sender, "GAR: cannot self approve");
        //the admin that is adding _newAdmin must not already have approved.
        require(
            _notAvailable(_newAdmin, msg.sender, PENDING_ADD_ADMIN_KEY),
            "GAR: already approved"
        );
        require(
            _addressExists(_newAdmin, pendingAdminKeys[PENDING_ADD_ADMIN_KEY]),
            "GAR: nonpending error"
        );

        areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin].push(msg.sender);
        emit NewAdminApproved(_newAdmin, msg.sender, PENDING_ADD_ADMIN_KEY);

        //if the _newAdmin is approved by all other admins
        if (this.isDoneByAll(_newAdmin, PENDING_ADD_ADMIN_KEY)) {
            //making this admin approved.
            _makeApproved(
                _newAdmin,
                pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_newAdmin]
            );
            //no  need  for pending  role now
            delete pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_newAdmin];

            emit NewAdminApprovedByAll(
                _newAdmin,
                approvedAdminRoles[_newAdmin]
            );
        }
    }

    /// @dev function to check if the address is already in pending or not
    /// @param _sender is the caller of the approve, edit or remove functions
    function isPending(address _sender) internal view returns (bool) {
        return (!_addressExists(
            _sender,
            pendingAdminKeys[PENDING_ADD_ADMIN_KEY]
        ) &&
            !_addressExists(
                _sender,
                pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]
            ) &&
            !_addressExists(
                _sender,
                pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]
            ));
    }

    /// @dev any admin can reject the pending admin during the approval process and one rejection means
    //  not pending anymore.
    /// @param _admin Address of the new admin

    function rejectAdmin(address _admin, uint8 _key)
        external
        onlyEditGovAdminRole(msg.sender)
    {       
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: call for self");
        require(
            _key == PENDING_ADD_ADMIN_KEY ||
                _key == PENDING_EDIT_ADMIN_KEY ||
                _key == PENDING_REMOVE_ADMIN_KEY,
            "GAR: wrong key inserted"
        );
        require(
            _addressExists(_admin, pendingAdminKeys[_key]),
            "GAR: nonpending error"
        );

        //the admin that is adding _newAdmin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, _key),
            "GAR: already approved"
        );
        //only with the reject of one admin call delete roles from mapping
        delete pendingAdminRoles[_key][_admin];
        uint256 length = areByAdmins[_key][_admin].length;
        for (uint256 i = 0; i < length; i++) {
            areByAdmins[_key][_admin].pop();
        }
        _removePendingIndex(_getIndex(_admin, pendingAdminKeys[_key]), _key);
        //delete admin roles from approved mapping
        delete areByAdmins[_key][_admin];
        emit AddAdminRejected(_admin, msg.sender);
    }

    /// @dev Get all Approved Admins
    /// @return address[] returns the all approved admins
    function getAllApproved() external view returns (address[] memory) {
        return allApprovedAdmins;
    }

    /// @dev Get all Pending Added Admin Keys
    /// @return address[] returns the addresses of the pending added adins

    function getAllPendingAddedAdminKeys()
        external
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_ADD_ADMIN_KEY];
    }

    /// @dev Get all Pending Edit Admin Keys
    /// @return address[] returns the addresses of the pending edit adins

    function getAllPendingEditAdminKeys()
        external
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_EDIT_ADMIN_KEY];
    }

    /// @dev Get all Pending Removed Admin Keys
    /// @return address[] returns the addresses of the pending removed adins
    function getAllPendingRemoveAdminKeys()
        external
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY];
    }

    /// @dev Get all admin addresses which approved the address in the parameter
    /// @param _addedAdmin address of the approved/proposed added admin.
    /// @return address[] address array of the admin which approved the added admin
    function getApprovedByAdmins(address _addedAdmin)
        external
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_ADD_ADMIN_KEY][_addedAdmin];
    }

    /// @dev Get all edit by admins addresses
    /// @param _editAdminAddress address of the edit admin
    /// @return address[] address array of the admin which approved the edit admin
    function getEditbyAdmins(address _editAdminAddress)
        external
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_EDIT_ADMIN_KEY][_editAdminAddress];
    }

    /// @dev Get all admin addresses which approved the address in the parameter
    /// @param _removedAdmin address of the approved/proposed added admin.
    /// @return address[] returns the array of the admins which approved the removed admin request
    function getRemovedByAdmins(address _removedAdmin)
        external
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_REMOVE_ADMIN_KEY][_removedAdmin];
    }

    /// @dev Get pending add admin roles
    /// @param _addAdmin address of the pending added admin
    /// @return AdminAccess roles of the pending added admin
    function getpendingAddedAdminRoles(address _addAdmin)
        external
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_addAdmin];
    }

    /// @dev Get pending edit admin roles
    /// @param _addAdmin address of the pending edit admin
    /// @return AdminAccess roles of the pending edit admin

    function getpendingEditedAdminRoles(address _addAdmin)
        external
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_addAdmin];
    }

    /// @dev Get pending remove admin roles
    /// @param _addAdmin address of the pending removed admin
    /// @return AdminAccess returns the roles of the pending removed admin
    function getpendingRemovedAdminRoles(address _addAdmin)
        external
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_REMOVE_ADMIN_KEY][_addAdmin];
    }

    /// @dev Initiate process of removal of admin,
    // in case there is only one admin removal is done instantly.
    // If there are more then one admin all must call removePendingAdmin.
    /// @param _admin Address of the admin requested to be removed

    function removeAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(pendingAdminKeys[PENDING_ADD_ADMIN_KEY].length == 0 && pendingAdminKeys[PENDING_EDIT_ADMIN_KEY].length == 0 && pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY].length == 0, "GAR: only one admin can be add, edit, remove at once");

        require(_admin != address(0), "GAR: invalid address");
        require(_admin != superAdmin, "GAR: cannot remove superadmin");
        require(_admin != msg.sender, "GAR: call for self");
       
        require(_addressExists(_admin, allApprovedAdmins), "GAR: not an admin");

        //this admin is now in the pending list.
        _makePendingForRemove(_admin, PENDING_REMOVE_ADMIN_KEY);

        performPendingActions();
    }

    /// @dev call approved the admin which is already added to pending by other admin
    // if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
    /// @param _admin Address of the new admin

    function approveRemovedAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: cannot call for self");
        //the admin that is adding _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_REMOVE_ADMIN_KEY),
            "GAR: already approved"
        );
        require(
            _addressExists(_admin, pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]),
            "GAR: nonpending admin error"
        );

        areByAdmins[PENDING_REMOVE_ADMIN_KEY][_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, PENDING_REMOVE_ADMIN_KEY)) {
            // _admin is now been removed
            _removeAdmin(_admin);
        } else {
            emit NewAdminApproved(_admin, msg.sender, PENDING_REMOVE_ADMIN_KEY);
        }
        performPendingActions();
    }

    /// @dev internal function call to execute the final approval, removal or editing of the admin roles
    function performPendingActions() internal {
        uint256 length = PENDING_KEYS.length;
        for (uint256 x = 0; x < length; x++) {
            for (uint256 i = 0; i < pendingAdminKeys[x].length; i++) {
                if (this.isDoneByAll(pendingAdminKeys[x][i], PENDING_KEYS[x])) {
                    if (PENDING_KEYS[x] == PENDING_EDIT_ADMIN_KEY)
                        _editAdmin(pendingAdminKeys[x][i]);
                    if (PENDING_KEYS[x] == PENDING_REMOVE_ADMIN_KEY)
                        _removeAdmin(pendingAdminKeys[x][i]);
                    performPendingActions();
                }
            }
        }
    }

    /// @dev Initiate process of edit of an admin,
    // If there are more then one admin all must call approveEditAdmin
    /// @param _admin Address of the admin requested to be removed

    function editAdmin(address _admin, AdminAccess memory _adminAccess)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(
            _adminAccess.addGovIntel ||
                _adminAccess.editGovIntel ||
                _adminAccess.addToken ||
                _adminAccess.editToken ||
                _adminAccess.addSp ||
                _adminAccess.editSp ||
                _adminAccess.addGovAdmin ||
                _adminAccess.editGovAdmin ||
                _adminAccess.addBridge ||
                _adminAccess.editBridge ||
                _adminAccess.addPool ||
                _adminAccess.editPool,
            "GAR: admin right error"
        );
        require(pendingAdminKeys[PENDING_ADD_ADMIN_KEY].length == 0 && pendingAdminKeys[PENDING_EDIT_ADMIN_KEY].length == 0 && pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY].length == 0, "GAR: only one admin can be add, edit, remove at once");
        require(_admin != msg.sender, "GAR: self edit error");
        require(_admin != superAdmin, "GAR: superadmin error");
       
        require(_addressExists(_admin, allApprovedAdmins), "GAR: not admin");

        require(!_adminAccess.superAdmin, "GAR: cannot assign super admin");

            //this admin is now in the pending list.
            _makePendingForAddEdit(
                _admin,
                _adminAccess,
                PENDING_EDIT_ADMIN_KEY
            );
        performPendingActions();
    }

    /// @dev call approved the admin which is already added to pending by other admin
    // if all current admins call approveEditAdmin are complete the admin edits become active
    /// @param _admin Address of the new admin

    function approveEditAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: call for self");
        
        //the admin that is adding _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_EDIT_ADMIN_KEY),
            "GAR: already approved"
        );

        require(
            _addressExists(_admin, pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]),
            "GAR: nonpending admin error"
        );

        areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, PENDING_EDIT_ADMIN_KEY)) {
            // _admin is now an approved admin.
            _editAdmin(_admin);
        } else {
            emit NewAdminApproved(_admin, msg.sender, PENDING_EDIT_ADMIN_KEY);
        }
        performPendingActions();
    }
}