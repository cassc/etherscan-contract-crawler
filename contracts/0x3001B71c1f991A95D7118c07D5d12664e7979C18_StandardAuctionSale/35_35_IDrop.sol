// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "../libs/AuthStructs.sol";

interface IDrop {
    function setMinter(address minter) external;

    function collection(uint256 dropId) external view returns (address);

    function totalItems(uint256 dropId) external view returns (uint32);

    function remainingItems(uint256 dropId) external view returns (uint32);
}