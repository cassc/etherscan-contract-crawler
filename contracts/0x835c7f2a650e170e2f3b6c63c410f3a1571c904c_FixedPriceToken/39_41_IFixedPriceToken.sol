//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IHTMLRenderer} from "../../renderer/interfaces/IHTMLRenderer.sol";

interface IFixedPriceToken {
    struct SaleInfo {
        uint16 artistProofCount;
        uint64 startTime;
        uint64 endTime;
        uint112 price;
    }

    error SaleNotActive();
    error InvalidPrice();
    error SoldOut();
    error ProofsMinted();

    /// @notice initialize the token
    function initialize(address owner, bytes calldata data) external;

    /// @notice contruct a generic data URI from token data
    function genericDataURI(
        string memory _name,
        string memory _description,
        string memory _animationURL,
        string memory _image
    ) external pure returns (string memory);

    /// @notice generate a preview URI for the token
    function generatePreviewURI(
        string memory tokenId
    ) external view returns (string memory);

    /// @notice generate the html for the token
    function tokenHTML(uint256 tokenId) external view returns (string memory);

    /// @notice generate the full script for the token
    function generateFullScript(
        uint256 tokenId
    ) external view returns (string memory);

    /// @notice get the script for the contract
    function getScript() external view returns (string memory);

    /// @notice set the script for the contract
    function setScript(string memory script) external;

    /// @notice get the preview base URI for the token
    function setPreviewBaseURL(string memory uri) external;

    /// @notice set the html renderer for the token
    function setHTMLRenderer(address _htmlRenderer) external;

    /// @notice add multiple imports to the token
    function addManyImports(
        IHTMLRenderer.FileType[] calldata _imports
    ) external;

    /// @notice set a single import to the token for a given index
    function setImport(
        uint256 index,
        IHTMLRenderer.FileType calldata _import
    ) external;

    /// @notice purchase a number of tokens
    function purchase(uint256 amount) external payable;
}