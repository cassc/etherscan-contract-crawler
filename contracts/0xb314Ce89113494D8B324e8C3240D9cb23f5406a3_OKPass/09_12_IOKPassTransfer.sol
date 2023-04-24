// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOKPassTransfer {
    function transferOrdinal(uint256 id, address burnerAddress, string memory ordAddress) external returns (bool);
}