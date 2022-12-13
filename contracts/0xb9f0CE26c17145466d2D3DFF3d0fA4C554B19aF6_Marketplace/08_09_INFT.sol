// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INFT {
    function mintNFT(
        address to,
        string memory membershipType,
        uint256 validity
    ) external returns (uint256, uint256);

    function soldNftsByDataType(string memory membershipType) external view returns (uint256);
}