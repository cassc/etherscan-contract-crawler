// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITokenURI {
    function tokenURI(uint256 id) external view returns (string memory);

    function contractURI(address receiver, uint96 per10Thousands) external view returns (string memory);
}