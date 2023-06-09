// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICallWhitelist {
    // ============= Events ==============

    event CallAdded(address operator, address callee, bytes4 selector);
    event CallRemoved(address operator, address callee, bytes4 selector);

    // ================ View Functions ================

    function isWhitelisted(address callee, bytes4 selector) external view returns (bool);

    function isBlacklisted(bytes4 selector) external view returns (bool);

    // ================ Update Operations ================

    function add(address callee, bytes4 selector) external;

    function remove(address callee, bytes4 selector) external;
}