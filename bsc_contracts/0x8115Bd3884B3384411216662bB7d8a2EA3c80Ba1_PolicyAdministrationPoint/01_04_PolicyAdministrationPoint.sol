// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "../common/Context.sol";
import "../utils/EnumerableSet.sol";
import "./SecurityTypes.sol";

contract PolicyAdministrationPoint is Context {
    using SecurityTypes for SecurityTypes.Policy;
    using SecurityTypes for SecurityTypes.Role;
    using SecurityTypes for SecurityTypes.Rule;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    
    mapping(bytes32 => mapping(bytes32 => SecurityTypes.Policy)) policies;
    mapping(bytes32 => SecurityTypes.Role) roles;
    mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
    mapping(address => EnumerableSet.Bytes32Set) userRoles;

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public constant POLICY_ADMIN = keccak256("POLICY_ADMIN");

    event CreatedRole(string label, bytes32 adminRole, address creator, uint256 timestamp);
    event UpdatedAdminRole(bytes32 role, bytes32 adminRole, address updator, uint256 timestamp);
    event GrantedRole(address granter, bytes32 role, address grantee, uint256 timestamp);
    event RevokedRole(address revoker, bytes32 role, address revoked, uint256 timestamp);
    event RenouncedRole(address renouncer, bytes32 role, uint256 timestamp);

    constructor() {
       address superAdmin = _msgSender();
       roles[ROLE_ADMIN] = SecurityTypes.Role({adminRole: ROLE_ADMIN, label: 'ROLE_ADMIN'});
       roles[POLICY_ADMIN] = SecurityTypes.Role({adminRole: POLICY_ADMIN, label: 'POLICY_ADMIN'});
       roleMembers[ROLE_ADMIN].add(superAdmin);
       roleMembers[POLICY_ADMIN].add(superAdmin);
       userRoles[superAdmin].add(ROLE_ADMIN);
       userRoles[superAdmin].add(POLICY_ADMIN);
    }

    // Policies
    function fetchPolicy(bytes32 resource, bytes32 action) public view returns (SecurityTypes.Policy memory) {
       return policies[resource][action];
    }
    
    function setPolicyRules(SecurityTypes.Policy storage policy, SecurityTypes.Rule[] memory rules) internal {
       require(inRole(POLICY_ADMIN), "missing required POLICY_ADMIN role");
       uint total = rules.length;
       for (uint i=0; i < total; i++) {
          policy.rules.push(rules[i]);
       }
    }
    
    function createPolicy(bytes32 resource, bytes32 action, SecurityTypes.Rule[] memory rules) public {
       SecurityTypes.Policy storage policy = policies[resource][action];
       require(policy.rules.length == 0, "Policy rules already exist!");
       setPolicyRules(policy, rules);
    }

    function updatePolicy(bytes32 resource, bytes32 action, SecurityTypes.Rule[] memory rules) public {
       SecurityTypes.Policy storage policy = policies[resource][action];
       delete policy.rules;
       setPolicyRules(policy, rules);
    }

    // Roles
    function fetchRole(bytes32 role_id) public view returns (SecurityTypes.Role memory) {
       return roles[role_id];
    }
    
    function fetchRoleMembers(bytes32 role_id) public view returns (address[] memory) {
       uint total = roleMembers[role_id].length();
       address[] memory addresses = new address[](total);
       for (uint i=0; i < total; i++) {
          addresses[i] = roleMembers[role_id].at(i);
       }
       return addresses;
    }

    function fetchUserRoles(address user) public view returns (bytes32[] memory) {
       uint total = userRoles[user].length();
       bytes32[] memory user_roles = new bytes32[](total);
       for (uint i=0; i < total; i++) {
          user_roles[i] = userRoles[user].at(i);
       }
       return user_roles;
    }
    
    function hasRole(address user, bytes32 role_id) public view returns (bool) {
       return roleMembers[role_id].contains(user);
    }
    
    function inRole(bytes32 role_id) public view returns (bool) {
       return roleMembers[role_id].contains(_msgSender());
    }

    function createRole(bytes32 adminRole, string memory label) public {
       require(inRole(ROLE_ADMIN), "missing required ROLE_ADMIN");
       bytes32 role_id = keccak256(abi.encodePacked(label));
       require(roles[role_id].adminRole == bytes32(0), "Role already exists!");
       roles[role_id] = SecurityTypes.Role({adminRole: adminRole, label: label});
       emit CreatedRole(label, adminRole, _msgSender(), block.timestamp);
    }

    function updateAdminRole(bytes32 role_id, bytes32 adminRole) public {
       require(inRole(ROLE_ADMIN), "missing required ROLE_ADMIN");
       roles[role_id].adminRole = adminRole;
       emit UpdatedAdminRole(role_id, adminRole, _msgSender(), block.timestamp);
    }
    
    function grantRole(address user, bytes32 role_id) public {
       require(inRole(roles[role_id].adminRole), "missing required adminRole");
       roleMembers[role_id].add(user);
       userRoles[user].add(role_id);
       emit GrantedRole(_msgSender(), role_id, user, block.timestamp);
    }
    
    function revokeRole(address user, bytes32 role_id) public {
       require(inRole(roles[role_id].adminRole), "missing required adminRole");
       require(user != _msgSender(), "use renounceRole for yourself");
       roleMembers[role_id].remove(user);
       userRoles[user].remove(role_id);
       emit RevokedRole(_msgSender(), role_id, user, block.timestamp);
    }

    function renounceRole(bytes32 role_id) public {
       require(roleMembers[role_id].length() > 1 || inRole(ROLE_ADMIN), "only ROLE_ADMIN can renounce the last role member");
       address user = _msgSender();
       roleMembers[role_id].remove(user);
       userRoles[user].remove(role_id);
       emit RenouncedRole(user, role_id, block.timestamp);
    }
    
    function revokeAllRoles(address user) public {
       while (userRoles[user].length() != 0) {
          revokeRole(user, userRoles[user].at(0));
       }
    }
}