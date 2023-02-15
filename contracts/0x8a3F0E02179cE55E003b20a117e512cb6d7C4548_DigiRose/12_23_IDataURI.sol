// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDataURI {
    function tokenURI(
        uint256 i_,
        bytes32 b_
    ) external view returns (string memory);
}
