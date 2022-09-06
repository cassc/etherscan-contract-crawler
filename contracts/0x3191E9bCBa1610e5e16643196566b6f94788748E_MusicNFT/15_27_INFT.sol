// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFT is IERC165 {
    // Mint item
    function mintItem(address user) external returns (uint256);

    // Set base URI
    function setBaseURI(string memory baseTokenURI) external;

    // Set Contract URI
    function setContractURI(string memory newContractURI) external;

    // Get Contract URI
    function contractURI() external view returns (string memory);
}