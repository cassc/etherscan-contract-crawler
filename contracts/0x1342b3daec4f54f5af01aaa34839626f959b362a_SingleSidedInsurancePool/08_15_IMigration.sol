// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IMigration {
    function onMigration(
        address who_,
        uint256 amount_,
        bytes memory data_
    ) external;
}