// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IGlobalConfig.sol";
import "../library/Registry.sol";
import "../library/LEnumerableMetadata.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


contract GlobalConfig is IGlobalConfig, AccessControlEnumerable {

    using LEnumerableMetadata for LEnumerableMetadata.MetadataSet;
    LEnumerableMetadata.MetadataSet private _configSet;

    // roleID -> fatherRoleID.
    // one addr in fatherRole, the addr also in children role.
    mapping(bytes32=>bytes32) public fatherRoleMap;

    constructor(address superAdmin) {
        if (superAdmin == address(0)) revert("GlobalConfig cannot be created");
        _setupRole(Registry.SUPER_ADMIN_ROLE, superAdmin);
        _configSet._init();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IConfig, AccessControlEnumerable) returns (bool) {
      return interfaceId == type(IGlobalConfig).interfaceId || interfaceId == type(IConfig).interfaceId || super.supportsInterface(interfaceId);
    }

    function version() external pure returns (uint256 v) {
        return 1;
    }

    function revokeRole(bytes32 role, address account) external override isRoleAdmin(role){
        require (role != Registry.SUPER_ADMIN_ROLE || getRoleMemberCount(role) > 1, "SC101: one super admin exists at a minimum");
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) external override {
        require (role != Registry.SUPER_ADMIN_ROLE || getRoleMemberCount(role) > 1, "SC101: one super admin exists at a minimum");
        super.renounceRole(role, account);
    }

    function hasRole(bytes32 role, address account) external view override(IAccessControl, IConfig) returns (bool has) {
      if(super.hasRole(role, account)){
        return true;
      }

      // the father role map default value is super admin role.
      if(super.hasRole(fatherRoleMap[role], account)){
        return true;
      }

      // if addr is role admin, so the addr has the role.
      if(super.hasRole(getRoleAdmin(role), account)){
        return true;
      }
      
      if (super.hasRole(Registry.SUPER_ADMIN_ROLE, account)) {
        return true;
      }

      return false;
    }

    function checkAdmin(address account) public view returns(bool) {
      // hasRole always check superadmin.
      return hasRole(Registry.ADMIN_ROLE, account);
    }

    modifier isAdmin() {
        require(checkAdmin(msg.sender), "SC102: invoke restricted to admin role");
        _;
    }

    modifier isSuperAdmin(){
        _checkRole(Registry.SUPER_ADMIN_ROLE, msg.sender);
        _;
    }

    modifier checkNotAdminRole(bytes32 role){
      require(role != Registry.SUPER_ADMIN_ROLE && role != Registry.ADMIN_ROLE, "SC103: ask for neither super admin nor admin role");

      _;
    }

    modifier isRoleAdmin(bytes32 role){
      require(super.hasRole(getRoleAdmin(role), msg.sender) || super.hasRole(Registry.SUPER_ADMIN_ROLE, msg.sender), "SC104: not role admin");
      _;
    }

    function setFatherRole(bytes32 role, bytes32 fatherRole) external isSuperAdmin checkNotAdminRole(role){
      require(getRoleAdmin(fatherRole) != role, "SC105: fatherRole admin can't equal role");
      require(role != fatherRole, "SC106: role == fatherRole");

      fatherRoleMap[role] = fatherRole;
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public isSuperAdmin checkNotAdminRole(role){
      require(fatherRoleMap[adminRole] != role, "SC105: adminRole's admin can't equal role");
      require(role != adminRole, "SC106: role == adminRole");

      _setRoleAdmin(role, adminRole);
    }

    function grantRole(bytes32 role, address account) public override isRoleAdmin(role){
      super._grantRole(role, account);
    }

    function getRawValue(bytes32 key) public view override returns(bytes32 typeID, bytes memory data){
        return _configSet._get(key);
    }

    function getKey(string memory keyStr) public pure override returns(bytes32 key){
        return LEnumerableMetadata._getKeyID(keyStr);
    }

    function getAllkeys(string memory startKey, uint256 pageSize) public view returns (string[] memory keys) {
        return _configSet._getAllKeys(startKey, pageSize);
    }

    function setKVs(bytes[] memory mds) public isAdmin {
        _configSet._setBytesSlice(mds);
        for (uint256 i = 0; i < mds.length; i++) {
            (string memory keyStr, bytes32 typeID, bytes memory data) = abi.decode(mds[i], (string, bytes32, bytes));
            emit SetKVEvent(getKey(keyStr), keyStr, typeID, data);
        }
    }

}