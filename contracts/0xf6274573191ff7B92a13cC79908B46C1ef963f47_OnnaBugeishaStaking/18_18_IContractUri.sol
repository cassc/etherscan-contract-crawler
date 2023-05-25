// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IContractUri {
    function contractURI() external view returns (string memory);

    /**
     * @notice Allows the owner to set the contracy URI to be used
     * @param _uri: contract URI
     * @dev Callable by owner
     */
    function setContractURI(string memory _uri) external;
}