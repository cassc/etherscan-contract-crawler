// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "IERC1155.sol";

interface IShards is IERC1155 {
    error NoRecipients();
    error NonExistent();
    error Untradeable();
    error ArrayLengthMismatch();
    error NoShards();

    function burn(address, uint256) external;
}