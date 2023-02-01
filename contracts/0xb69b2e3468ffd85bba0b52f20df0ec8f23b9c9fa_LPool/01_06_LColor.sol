// SPDX-License-Identifier: Business Source License (BSL 1.1)
// (c) 2023 Lyfeloop, Inc.

pragma solidity 0.5.12;

contract LColor {
    function getColor()
        external view
        returns (bytes32);
}

contract BBronze is LColor {
    function getColor()
        external view
        returns (bytes32) {
            return bytes32("BRONZE");
        }
}
