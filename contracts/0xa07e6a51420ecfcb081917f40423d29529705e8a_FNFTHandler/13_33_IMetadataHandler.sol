// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface IMetadataHandler {

    function getTokenURI(uint fnftId) external view returns (string memory );

    function setTokenURI(uint fnftId, string memory _uri) external;

    function getRenderTokenURI(
        uint tokenId,
        address owner
    ) external view returns (
        string memory baseRenderURI,
        string[] memory parameters
    );

    function setRenderTokenURI(
        uint tokenID,
        string memory baseRenderURI
    ) external;

}