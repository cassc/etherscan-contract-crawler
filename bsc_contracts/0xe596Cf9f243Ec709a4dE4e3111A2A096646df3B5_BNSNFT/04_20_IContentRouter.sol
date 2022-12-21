// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IContentProvider.sol";


interface IContentRouter {

    enum ContentType {
        INTERNAL,
        EXTERNAL
    }

    struct ContentRoute {
        bool exists;
        ContentType contentType;
        IContentProvider contentProvider;   // used with on-chain content
        string contentAddress;              // used with off-chain conetent
    }

    function setContentOrAddress(string memory name, string memory relativePath, string memory content, ContentType contentType, address contentProvider) external;
    function getContentOrAddress(string memory name, string memory realtivePath) external view returns (ContentType contentType, string memory);

}