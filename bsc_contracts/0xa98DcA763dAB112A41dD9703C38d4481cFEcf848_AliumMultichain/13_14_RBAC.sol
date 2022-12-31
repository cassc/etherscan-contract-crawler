/// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title RBAC - right based access control.
 */
contract RBAC is AccessControlEnumerable {
    constructor(address _admin) {
        require(_admin != address(0), "Admin not set");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    // @dev Returns roles hash.
    function getRoleHash(string memory _role)
        external
        pure
        returns (bytes32 hash)
    {
        hash = keccak256(abi.encodePacked(_role));
    }
}