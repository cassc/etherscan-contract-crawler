//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

contract PlanetSandboxAccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set private _roles;
    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl, IAccessControl)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl, IAccessControl)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(role, account);
    }

    function getRoles()
        public
        view
        virtual
        returns (
            bytes32 defaultRole,
            uint256 count,
            bytes32[] memory roles
        )
    {
        return (DEFAULT_ADMIN_ROLE, _roles.length(), _roles.values());
    }

    function getMemberByRole(bytes32 role) public view virtual returns (uint256 count, address[] memory members) {
        return (_roleMembers[role].length(), _roleMembers[role].values());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);

        _roles.add(role);
        _roleMembers[role].add(account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}