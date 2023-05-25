// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IContractURI {
    /**
     * @notice Collection metadata URI
     */
    function contractURI() external view returns (string memory);
}