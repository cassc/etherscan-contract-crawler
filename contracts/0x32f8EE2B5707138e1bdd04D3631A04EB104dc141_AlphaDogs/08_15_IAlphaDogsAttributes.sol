// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsAttributes {
    function tokenURI(
        uint256 id,
        bytes memory name,
        string memory lore
    ) external view returns (string memory);
}