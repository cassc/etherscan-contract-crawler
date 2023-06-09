// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITinyFamiliarMetadata {
    function setContractURI(string calldata URI) external;

    function setBaseURI(string calldata URI) external;

    function contractURI() external view returns (string memory);
}