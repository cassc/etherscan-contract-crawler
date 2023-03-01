// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import {IFixedPriceToken} from "../interfaces/IFixedPriceToken.sol";
import {IHTMLRenderer} from "../../renderer/interfaces/IHTMLRenderer.sol";

abstract contract FixedPriceTokenStorageV1 {
    /// @notice Storage pointer for the generative script
    address scriptPointer;

    /// @notice Address of the HTML renderer
    address htmlRenderer;

    /// @notice Base URI for the preview URI
    string previewBaseURI;

    /// @notice Required imports for the renderer
    IHTMLRenderer.FileType[] public imports;

    /// @notice Sales info for token purchases
    IFixedPriceToken.SaleInfo public saleInfo;

    /// @notice Flag to indicate if the artist proofs have been minted
    bool proofsMinted;
}