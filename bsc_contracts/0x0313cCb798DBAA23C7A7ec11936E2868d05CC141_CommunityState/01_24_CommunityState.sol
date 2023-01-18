// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./CommunityStorage.sol";

//import "hardhat/console.sol";

contract CommunityState is CommunityStorage {
    
    using PackedSet for PackedSet.Set;

    using StringUtils for *;

    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    ///////////////////////////////////////////////////////////
    /// external section
    ///////////////////////////////////////////////////////////
    /**
    * @param hook address of contract implemented ICommunityHook interface. Can be address(0)
    * @param name_ erc721 name
    * @param symbol_ erc721 symbol
    */
    function initialize(
        address hook,
        string memory name_, 
        string memory symbol_
    ) 
        external 
    {
        name = name_;
        symbol = symbol_;

        __CommunityBase_init(hook);

    }

    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////
    
    /**
    * @notice the way to withdraw remaining ETH from the contract. called by owners only 
    * @custom:shortd the way to withdraw ETH from the contract.
    * @custom:calledby owners
    */
    function withdrawRemainingBalance(
    ) 
        public 
        //nonReentrant()
    {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        payable(_msgSender()).transfer(address(this).balance);
    } 

    /**
     * @notice Added new Roles for each account
     * @custom:shortd Added new Roles for each account
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function grantRoles(
        address[] memory accounts, 
        uint8[] memory roleIndexes
    )
        public 
    {
        // uint256 lengthAccounts = accounts.length;
        // uint256 lenRoles = roleIndexes.length;
        uint8[] memory rolesIndexWhichWillGrant;
        uint8 roleIndexWhichWillGrant;

        //address sender = _msgSender();

        for (uint256 i = 0; i < roleIndexes.length; i++) {
            _isRoleValid(roleIndexes[i]); 

            rolesIndexWhichWillGrant = _isCanGrant(_msgSender(), roleIndexes[i], FlagFork.NONE);

            require(
                rolesIndexWhichWillGrant.length != 0,
                string(abi.encodePacked("Sender can not grant role '",_rolesByIndex[roleIndexes[i]].name.bytes32ToString(),"'"))
            );

            roleIndexWhichWillGrant = validateGrantSettings(rolesIndexWhichWillGrant, roleIndexes[i], FlagFork.REVERT);

            for (uint256 j = 0; j < accounts.length; j++) {
                _grantRole(roleIndexWhichWillGrant, _msgSender(), roleIndexes[i], accounts[j]);
            }
        }
    }
    
    /**
     * @notice Removed Roles from each member
     * @custom:shortd Removed Roles from each member
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function revokeRoles(
        address[] memory accounts, 
        uint8[] memory roleIndexes
    ) 
        public 
    {

        uint8 roleWhichWillRevoke;
        address sender = _msgSender();

        for (uint256 i = 0; i < roleIndexes.length; i++) {
            _isRoleValid(roleIndexes[i]); 

            roleWhichWillRevoke = NONE_ROLE_INDEX;
            if (_isTargetInRole(sender, _roles[DEFAULT_OWNERS_ROLE])) {
                // owner can do anything. so no need to calculate or loop
                roleWhichWillRevoke = _roles[DEFAULT_OWNERS_ROLE];
            } else {
                for (uint256 j = 0; j<_rolesByAddress[sender].length(); j++) {
                    if (_rolesByIndex[uint8(_rolesByAddress[sender].get(j))].canRevokeRoles.contains(roleIndexes[i]) == true) {
                        roleWhichWillRevoke = _rolesByAddress[sender].get(j);
                        break;
                    }
                }
            }
            require(roleWhichWillRevoke != NONE_ROLE_INDEX, string(abi.encodePacked("Sender can not revoke role '",_rolesByIndex[roleIndexes[i]].name.bytes32ToString(),"'")));
            for (uint256 k = 0; k < accounts.length; k++) {
                _revokeRole(/*roleWhichWillRevoke, */sender, roleIndexes[i], accounts[k]);
            }

        }

    }
    
    /**
     * @notice creating new role. can called owners role only
     * @custom:shortd creating new role. can called owners role only
     * @param role role name
     */
    function createRole(
        string memory role
    ) 
        public 
        
    {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        // require(_roles[role.stringToBytes32()] == 0, "Such role is already exists");
        // // prevent creating role in CamelCases with admins and owners (Admins,ADMINS,ADminS)
        // require(_roles[role._toLower().stringToBytes32()] == 0, "Such role is already exists");
        require(
            (_roles[role.stringToBytes32()] == 0) &&
            (_roles[role._toLower().stringToBytes32()] == 0) 
            , 
            "Such role is already exists"
        );
        
        require(rolesCount < type(uint8).max -1, "Max amount of roles exceeded");

        _createRole(role.stringToBytes32());
       
    }
    
    /**
     * @notice allow account with byRole:
     * (if canGrantRole ==true) grant ofRole to another account if account has requireRole
     *          it can be available `maxAddresses` during `duration` time
     *          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role
     *          if maxAddresses == 0 then no limit max accounts on this role
     * (if canRevokeRole ==true) revoke ofRole from account.
     */
    function manageRole(
        uint8 byRole, 
        uint8 ofRole, 
        bool canGrantRole, 
        bool canRevokeRole, 
        uint8 requireRole, 
        uint256 maxAddresses, 
        uint64 duration
    )
        public 
    {
        
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(ofRole != _roles[DEFAULT_OWNERS_ROLE], string(abi.encodePacked("ofRole can not be '", _rolesByIndex[ofRole].name.bytes32ToString(), "'")));
        
        _manageRole(
            byRole, 
            ofRole, 
            canGrantRole, 
            canRevokeRole, 
            requireRole, 
            maxAddresses, 
            duration
        );
    }
  
    /**
     * @notice registering invite,. calling by relayers
     * @custom:shortd registering invite 
     * @param sSig signature of admin whom generate invite and signed it
     * @param rSig signature of recipient
     */
    function invitePrepare(
        bytes memory sSig, 
        bytes memory rSig
    ) 
        public 
        
        accummulateGasCost(sSig)
    {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_RELAYERS_ROLE]);
        require(inviteSignatures[sSig].exists == false, "Such signature is already exists");
        inviteSignatures[sSig].sSig= sSig;
        inviteSignatures[sSig].rSig = rSig;
        inviteSignatures[sSig].reimbursed = ReimburseStatus.NONE;
        inviteSignatures[sSig].used = false;
        inviteSignatures[sSig].exists = true;
    }
    
    /**
     * @dev
     * @dev ==P==  
     * @dev format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>"          
     * @dev invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:GregMagarshak  
     * @dev ==R==  
     * @dev format is "<address of R wallet>:<name of user>"  
     * @dev 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe  
     * @notice accepting invite
     * @custom:shortd accepting invite
     * @param p invite message of admin whom generate messageHash and signed it
     * @param sSig signature of admin whom generate invite and signed it
     * @param rp message of recipient whom generate messageHash and signed it
     * @param rSig signature of recipient
     */
    function inviteAccept(
        string memory p, 
        bytes memory sSig, 
        string memory rp, 
        bytes memory rSig
    )
        public 
        refundGasCost(sSig)
        //nonReentrant()
    {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_RELAYERS_ROLE]);

        require(inviteSignatures[sSig].used == false, "Such signature is already used");

        (address pAddr, address rpAddr) = _recoverAddresses(p, sSig, rp, rSig);
       
        string[] memory dataArr = p.slice(":");
        string[] memory rolesArr = dataArr[2].slice(",");
        string[] memory rpDataArr = rp.slice(":");
        
        if (
            pAddr == address(0) || 
            rpAddr == address(0) || 
            keccak256(abi.encode(inviteSignatures[sSig].rSig)) != keccak256(abi.encode(rSig)) ||
            rpDataArr[0].parseAddr() != rpAddr || 
            dataArr[1].parseAddr() != address(this)
        ) {
            revert("Signature are mismatch");
        }
      
        bool isCanProceed = false;
        
        for (uint256 i = 0; i < rolesArr.length; i++) {
            uint8 roleIndex = _roles[rolesArr[i].stringToBytes32()];
            if (roleIndex == 0) {
                emit RoleAddedErrorMessage(_msgSender(), "invalid role");
            }

            uint8[] memory rolesIndexWhichWillGrant = _isCanGrant(pAddr, roleIndex, FlagFork.EMIT);

            uint8 roleIndexWhichWillGrant = validateGrantSettings(rolesIndexWhichWillGrant, roleIndex, FlagFork.EMIT);

            if (roleIndexWhichWillGrant == NONE_ROLE_INDEX) {
                emit RoleAddedErrorMessage(_msgSender(), string(abi.encodePacked("inviting user did not have permission to add role '",_rolesByIndex[roleIndex].name.bytes32ToString(),"'")));
            } else {
                isCanProceed = true;
                _grantRole(roleIndexWhichWillGrant, pAddr, roleIndex, rpAddr);
            }
        }

        if (isCanProceed == false) {
            revert("Can not add no one role");
        }

        inviteSignatures[sSig].used = true;

        //store first inviter
        if (invitedBy[rpAddr] == address(0)) {
            invitedBy[rpAddr] = pAddr;
        }

        invited[pAddr].add(rpAddr);
        
        _rewardCaller();
        _replenishRecipient(rpAddr);
    }

    
    function setTrustedForwarder(
        address forwarder
    ) 
        public 
        override 
    {

        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(
            !_isTargetInRole(forwarder, _roles[DEFAULT_OWNERS_ROLE]),
            "FORWARDER_CAN_NOT_BE_OWNER"
        );
        _setTrustedForwarder(forwarder);
    }
    /**
    * @notice setting tokenURI for role
    * @param roleIndex role index
    * @param roleURI token URI
    * @custom:shortd setting tokenURI for role
    * @custom:calledby any who can manage this role
    */
    function setRoleURI(
        uint8 roleIndex,
        string memory roleURI
    ) 
        public 
    {
        ifTargetInRole(_msgSender(), roleIndex);
        
        _rolesByIndex[roleIndex].roleURI = roleURI;
    }

    /**
    * @notice setting extraURI for role.
    * @custom:calledby any who belong to role
    */
    function setExtraURI(
        uint8 roleIndex,
        string memory extraURI
    )
        public
    {
        ifTargetInRole(_msgSender(), roleIndex);
        _rolesByIndex[roleIndex].extraURI[_msgSender()] = extraURI;
    }
    ///////////////////////////////////////////////////////////
    /// public  section that are view
    ///////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    /// internal section
    ///////////////////////////////////////////////////////////

    ///////////////////////////////////
    // ownable implementation with diff semantic
    /**
    * @dev will grantRoles([address], OWNERS_ROLE) and then revokeRoles(msg.caller, OWNERS_ROLE). 
    * There is no need to have transferRole() function because normally no one can transfer their own roles unilaterally, except owners. 
    * Instead they manage roles under them.
    */
    // The function renounceOwnership() will simply revokeRoles(getAddresses(OWNERS_ROLE), OWNERS_ROLE) from everyone who has it, including the caller. 
    // This function is irreversible. The contract will be ownerless. The trackers should see the appropriate events/logs as from any Ownable interface.
    function _transferOwnership(address newOwner) internal override {
        address sender = _msgSender();
        if (newOwner == address(0)) {
            // if newOwner == address(0) it's just renounceOwnership()    
            // we will simply revokeRoles(getAddresses(OWNERS_ROLE), OWNERS_ROLE) from everyone who has it, including the caller. 
            EnumerableSetUpgradeable.AddressSet storage ownersList = _rolesByIndex[_roles[DEFAULT_OWNERS_ROLE]].members;
            uint256 len = ownersList.length();
            // loop through stack, due to reducing members in role, we just get address from zero position `len` times
            for (uint256 i = 0; i < len; i++) {
                _revokeRole(sender, _roles[DEFAULT_OWNERS_ROLE], ownersList.at(0));
            }
            emit RenounceOwnership();
        } else {
            _grantRole(_roles[DEFAULT_OWNERS_ROLE], sender, _roles[DEFAULT_OWNERS_ROLE], newOwner);
            _revokeRole(sender, _roles[DEFAULT_OWNERS_ROLE], sender);
            emit OwnershipTransferred(sender, newOwner);
        }
    }

    ///////////////////////////////////
    /**
    * @dev find which role can grant `targetRoleIndex` to account
    * @param rolesWhichCanGrant array of role indexes which want to grant `targetRoleIndex` to account
    * @param targetRoleIndex target role index
    * @param flag flag which indicated what is need to do when error happens. 
    *   if FlagFork.REVERT - when transaction will reverts, 
    *   if FlagFork.EMIT - emit event `RoleAddedErrorMessage` 
    *   otherwise - do nothing
    * @return uint8 role index which can grant `targetRoleIndex` to account without error
    */
    function validateGrantSettings(
        uint8[] memory rolesWhichCanGrant,
        uint8 targetRoleIndex,
        FlagFork flag
    ) 
        internal 
        returns(uint8) 
    {

        uint8 roleWhichCanGrant = NONE_ROLE_INDEX;

        for (uint256 i = 0; i < rolesWhichCanGrant.length; i++) {
            if (
                (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses == 0)
            ) {
                roleWhichCanGrant = rolesWhichCanGrant[i];
            } else {
                if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration == 0 ) {
                    if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter+1 <= _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses) {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                    }
                } else {

                    // get current interval index
                    uint64 interval = uint64(block.timestamp)/(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration)*(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration);
                    if (interval == _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].lastIntervalIndex) {
                        if (
                            _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter+1 
                            <= 
                            _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses
                        ) {
                            roleWhichCanGrant = rolesWhichCanGrant[i];
                        }
                    } else {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                        _rolesByIndex[roleWhichCanGrant].grantSettings[targetRoleIndex].lastIntervalIndex = interval;
                        _rolesByIndex[roleWhichCanGrant].grantSettings[targetRoleIndex].grantedAddressesCounter = 0;

                    }
                    
                }
            }

            if (roleWhichCanGrant != NONE_ROLE_INDEX) {
                _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter += 1;
                break;
            }
        }

        if (roleWhichCanGrant == NONE_ROLE_INDEX) {
            
            if (flag == FlagFork.REVERT) {
                revert("Max amount addresses exceeded");
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(_msgSender(), "Max amount addresses exceeded");
            }
        }

        return roleWhichCanGrant;

    }
    
    /**
     * @notice is role can be granted by sender's roles?
     * @param sender sender
     * @param targetRoleIndex role index
     */
    function ifCanGrant(
        address sender, 
        uint8 targetRoleIndex
    ) 
        internal 
    {
     
        _isCanGrant(sender, targetRoleIndex,FlagFork.REVERT);
      
    }
  
    /**
     * @param role role name
     */
    function _createRole(
        bytes32 role
    ) 
        internal 
    {
        _roles[role] = rolesCount;
        _rolesByIndex[rolesCount].name = role;
        rolesCount += 1;
       
        if (hook != address(0)) {            
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleCreated(role, rolesCount);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleCreated(role, _msgSender());
    }
   
    /**
     * Set availability for members with `sourceRole` addMember/removeMember/addMemberRole/removeMemberRole
     * @param byRole source role index
     * @param ofRole target role index
     */
    function _manageRole(
        uint8 byRole, 
        uint8 ofRole, 
        bool canGrantRole, 
        bool canRevokeRole, 
        uint8 requireRole, 
        uint256 maxAddresses, 
        uint64 duration
    ) internal {
    
        _isRoleValid(byRole);
        _isRoleValid(ofRole);
        
        if (canGrantRole) {
            _rolesByIndex[byRole].canGrantRoles.add(ofRole);
        } else {
            _rolesByIndex[byRole].canGrantRoles.remove(ofRole);
        }

        if (canRevokeRole) {
            _rolesByIndex[byRole].canRevokeRoles.add(ofRole);
        } else {
            _rolesByIndex[byRole].canRevokeRoles.remove(ofRole);
        }

        _rolesByIndex[byRole].grantSettings[ofRole].requireRole = requireRole;
        _rolesByIndex[byRole].grantSettings[ofRole].maxAddresses = maxAddresses;
        _rolesByIndex[byRole].grantSettings[ofRole].duration = duration;

        emit RoleManaged(
            byRole, 
            ofRole, 
            canGrantRole, 
            canRevokeRole, 
            requireRole, 
            maxAddresses, 
            duration,
            _msgSender()
        );
    }
 
    /**
     * adding role to member
     * @param sourceRoleIndex sender role index
     * @param sourceAccount sender account's address
     * @param targetRoleIndex target role index
     * @param targetAccount target account's address
     */
    function _grantRole(
        uint8 sourceRoleIndex, 
        address sourceAccount, 
        uint8 targetRoleIndex, 
        address targetAccount
    ) 
        internal 
    {

        if (_rolesByAddress[targetAccount].length() == 0) {
            addressesCounter++;
        }

       _rolesByAddress[targetAccount].add(targetRoleIndex);
       _rolesByIndex[targetRoleIndex].members.add(targetAccount);
       
        grantedBy[targetAccount].push(ActionInfo({
            actor: sourceAccount,
            timestamp: uint64(block.timestamp),
            extra: uint32(targetRoleIndex)
        }));
        granted[sourceAccount].push(ActionInfo({
            actor: targetAccount,
            timestamp: uint64(block.timestamp),
            extra: uint32(targetRoleIndex)
        }));
 

        _rolesByIndex[sourceRoleIndex].grantSettings[targetRoleIndex].grantedAddressesCounter += 1;

        if (hook != address(0)) {
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleGranted(_rolesByIndex[targetRoleIndex].name, targetRoleIndex, targetAccount);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleGranted(_rolesByIndex[targetRoleIndex].name, targetAccount, sourceAccount);
    }
    
    /**
     * removing role from member
     * param sourceRoleIndex sender role index *deprecated*
     * @param sourceAccount sender account's address
     * @param targetRoleIndex target role index
     * @param targetAccount target account's address
     */
    function _revokeRole(
        //uint8 sourceRoleIndex, 
        address sourceAccount, 
        uint8 targetRoleIndex, 
        address targetAccount
        //address account, bytes32 targetRole
    ) 
        internal 
    {
        
        _rolesByAddress[targetAccount].remove(targetRoleIndex);
        _rolesByIndex[targetRoleIndex].members.remove(targetAccount);
       
        if (
            _rolesByAddress[targetAccount].length() == 0 &&
            addressesCounter != 0
        ) {
            addressesCounter--;
        }


        revokedBy[targetAccount].push(ActionInfo({
            actor: sourceAccount,
            timestamp: uint64(block.timestamp),
            extra: uint32(targetRoleIndex)
        }));
        revoked[sourceAccount].push(ActionInfo({
            actor: targetAccount,
            timestamp: uint64(block.timestamp),
            extra: uint32(targetRoleIndex)
        }));

        if (hook != address(0)) {
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleRevoked(_rolesByIndex[targetRoleIndex].name, targetRoleIndex, targetAccount);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleRevoked(_rolesByIndex[targetRoleIndex].name, targetAccount, sourceAccount);
    }
 
    function _isCanGrant(
        address sender, 
        uint8 targetRoleIndex, 
        FlagFork flag
    ) 
        internal 
        returns (uint8[] memory) 
    {

        //uint256 targetRoleID = uint256(targetRoleIndex);
       
        uint256 iLen;
        uint8[] memory rolesWhichCan;

        if (_isTargetInRole(sender, _roles[DEFAULT_OWNERS_ROLE])) {
            // owner can do anything. so no need to calculate or loop
            rolesWhichCan = new uint8[](1);
            rolesWhichCan[0] = _roles[DEFAULT_OWNERS_ROLE];
        } else {

            iLen = 0;
            for (uint256 i = 0; i<_rolesByAddress[sender].length(); i++) {
                if (_rolesByIndex[uint8(_rolesByAddress[sender].get(i))].canGrantRoles.contains(targetRoleIndex) == true) {
                    iLen++;
                }
            }

            rolesWhichCan = new uint8[](iLen);

            iLen = 0;
            for (uint256 i = 0; i<_rolesByAddress[sender].length(); i++) {
                if (_rolesByIndex[uint8(_rolesByAddress[sender].get(i))].canGrantRoles.contains(targetRoleIndex) == true) {
                    rolesWhichCan[iLen] = _rolesByAddress[sender].get(i);
                    iLen++;
                }
            }

            if (rolesWhichCan.length == 0) {
                string memory errMsg = string(abi.encodePacked("Sender can not grant account with role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(), "'"));
                if (flag == FlagFork.REVERT) {
                    revert(errMsg);
                } else if (flag == FlagFork.EMIT) {
                    emit RoleAddedErrorMessage(sender, errMsg);
                }
            }
        
        }

        return rolesWhichCan;
    }

    function __CommunityBase_init(address hook_) internal onlyInitializing {
        
        __TrustedForwarder_init();
        __ReentrancyGuard_init();
        
        rolesCount = 1;
        
        _createRole(DEFAULT_RELAYERS_ROLE);
        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _createRole(DEFAULT_ALUMNI_ROLE);
        _createRole(DEFAULT_VISITORS_ROLE);
        
        //_grantRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        _grantRole(_roles[DEFAULT_OWNERS_ROLE], _msgSender(), _roles[DEFAULT_OWNERS_ROLE], _msgSender());
        
        // initial rules. owners can manage any roles. to save storage we will hardcode in any validate
        // admins can manage members, alumni and visitors
        // any other rules can be added later by owners
        
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_MEMBERS_ROLE],  true, true, 0, 0, 0);
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_ALUMNI_ROLE],   true, true, 0, 0, 0);
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_VISITORS_ROLE], true, true, 0, 0, 0);

        // avoiding hook's trigger for built-in roles
        // so define hook address in the end
        hook = hook_;

    }

    ///////////////////////////////////////////////////////////
    /// internal section that are view
    ///////////////////////////////////////////////////////////
    
    /**
     * @notice does address belong to role
     * @param target address
     * @param targetRoleIndex role index
     */
    function ifTargetInRole(
        address target, 
        uint8 targetRoleIndex
    ) 
        internal 
        view 
    {
        
        require(
            _isTargetInRole(target, targetRoleIndex),
            string(abi.encodePacked("Missing role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(),"'"))
        );

    }
    
    function _isRoleValid(
        uint8 index
    ) 
        internal 
        view 
    {
        require(
            (rolesCount > index), 
            "invalid role"
        ); 
    }

    ///////////////////////////////////////////////////////////
    /// private section
    ///////////////////////////////////////////////////////////
    
    /**
     * reward caller(relayers)
     */
    function _rewardCaller(
    ) 
        private 
    {
        if (REWARD_AMOUNT <= address(this).balance) {
            payable(_msgSender()).transfer(REWARD_AMOUNT);
        }
    }
    
    /**
     * replenish recipient which added via invite
     * @param rpAddr recipient's address 
     */
    function _replenishRecipient(
        address rpAddr
    ) 
        private 
    {
        if (REPLENISH_AMOUNT <= address(this).balance) {
            payable(rpAddr).transfer(REPLENISH_AMOUNT);
        }
    }
    
    function _recoverAddresses(
        string memory p, 
        bytes memory sSig, 
        string memory rp, 
        bytes memory rSig
    ) 
        private 
        pure
        returns(address, address)
    {
        // bytes32 pHash = p.recreateMessageHash();
        // bytes32 rpHash = rp.recreateMessageHash();
        // address pAddr = pHash.recover(sSig);
        // address rpAddr = rpHash.recover(rSig);
        // return (pAddr, rpAddr);

        return (
            p.recreateMessageHash().recover(sSig), 
            rp.recreateMessageHash().recover(rSig)
        );
    }
    

}