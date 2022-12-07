// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which implements admin roles.
 */
interface IRoles {
    function isAdmin(address account) external view returns (bool);

    function isOperator(address account) external view returns (bool);

    function isModule(address account) external view returns (bool);

    function isNode(address account) external view returns (bool);

    function hasGranted(bytes32 role, address account)
        external
        view
        returns (bool);
}