// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IFileStore} from "ethfs/IFileStore.sol";
import {IFileSystemAdapter} from "./interfaces/IFileSystemAdapter.sol";

contract ETHFSAdapter is IFileSystemAdapter {
    address immutable fileStoreAddress;

    constructor(address _fileStoreAddress) {
        fileStoreAddress = _fileStoreAddress;
    }

    /// @notice Returns the file contents from ETH FS
    function getFile(
        string calldata fileName
    ) external view returns (string memory) {
        return IFileStore(fileStoreAddress).getFile(fileName).read();
    }
}