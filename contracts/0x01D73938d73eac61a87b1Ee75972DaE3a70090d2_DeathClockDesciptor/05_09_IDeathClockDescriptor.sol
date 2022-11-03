// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IDeathClockDescriptor {
    struct TokenParams {
        uint8 cid;
        uint8 tid;
        uint8 bid;
    }
    struct MetadataPayload {
        uint256 id;
        uint256 minted;
        uint256 expDate;
        uint256 remnants;
        uint256 resets;
        address acct;
    }

    function setViewerCID(string memory _viewerCID) external;
    function setPreviewCID(string memory _previewCID) external;
    function setTokenParams(TokenParams[] memory _tokenParams, uint256 startsWith) external;
    function getMetadataJSON(MetadataPayload calldata metadataPayload) external view returns (string memory);
}