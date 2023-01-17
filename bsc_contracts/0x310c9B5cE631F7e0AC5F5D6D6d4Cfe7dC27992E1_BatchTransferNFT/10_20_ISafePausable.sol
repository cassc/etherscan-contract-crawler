// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import "../interfaces/IPendingOwnable.sol";

interface ISafePausable is IAccessControlEnumerable, IPendingOwnable {
    function PAUSER_ROLE() external pure returns (bytes32);

    function UNPAUSER_ROLE() external pure returns (bytes32);

    function PAUSER_ADMIN_ROLE() external pure returns (bytes32);

    function UNPAUSER_ADMIN_ROLE() external pure returns (bytes32);

    function pause() external;

    function unpause() external;
}