/// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title RBAC - Remote based access control.
 */
contract RBAC is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(address _admin) {
        require(_admin != address(0), "RBAC: admin set");

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Calculate role hash by input string.
     */
    function getRoleHash(string memory _role) external pure returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(_role));
    }
}