// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

// Adopted from "@a16z/contracts/licenses/CantBeEvil.sol"
interface ICantBeEvil {
    function getLicenseURI() external view returns (string memory);

    function getLicenseName() external view returns (string memory);
}