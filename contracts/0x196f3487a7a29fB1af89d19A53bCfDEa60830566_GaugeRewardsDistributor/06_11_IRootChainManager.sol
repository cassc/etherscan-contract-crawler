// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IRootChainManager {
    function depositFor(
        address user,
        address rootToken,
        bytes memory depositData
    ) external;

    function tokenToType(address) external view returns (bytes32);

    function typeToPredicate(bytes32) external view returns (address);
}