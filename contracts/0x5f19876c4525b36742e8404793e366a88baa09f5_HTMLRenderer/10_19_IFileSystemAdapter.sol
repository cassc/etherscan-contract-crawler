//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFileSystemAdapter {
    /// @notice Returns the file contents for the given file name
    function getFile(
        string calldata fileName
    ) external view returns (string memory);
}