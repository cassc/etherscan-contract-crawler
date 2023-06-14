// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;
import "../interfaces/IAddressProvider.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract AccessProxy {
    error InvalidRole(address, bytes32);
    IAddressProvider immutable private ADDRESS_PROVIDER;
    function _hasRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        IAccessControl acl = IAccessControl(
            ADDRESS_PROVIDER.getAddress(ADDR_ACCESS_CONTROL)
        );
        return acl.hasRole(role, account);
    }

    modifier onlyRole(bytes32 role) {
        if (!_hasRole(role, msg.sender)) {
            revert InvalidRole(msg.sender, role);
        }
        _;
    }
  constructor(address _addressProvider) {
    ADDRESS_PROVIDER = IAddressProvider(_addressProvider);
  }
}