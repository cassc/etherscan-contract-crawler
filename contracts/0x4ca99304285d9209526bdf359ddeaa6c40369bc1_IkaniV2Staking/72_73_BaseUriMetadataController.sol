// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IIkaniV1MetadataController } from "../interfaces/IIkaniV1MetadataController.sol";

/**
 * @title BaseUriMetadataController
 * @author Cyborg Labs, LLC
 *
 * @notice Implementation of the tokenURI function using a base URI.
 */
contract BaseUriMetadataController is
    Ownable,
    IIkaniV1MetadataController
{
    using Strings for uint256;

    string internal _BASE_URI_;

    constructor(
        string memory baseUri
    ) {
        _BASE_URI_ = baseUri;
    }

    function setBaseUri(
        string calldata baseUri
    )
        external
        onlyOwner
    {
        _BASE_URI_ = baseUri;
    }

    function baseURI()
        external
        view
        returns (string memory)
    {
        return _BASE_URI_;
    }

    function tokenURI(
        uint256 tokenId
    )
        external
        view
        override
        returns (string memory)
    {
        string memory baseUri = _BASE_URI_;
        return bytes(baseUri).length > 0
            ? string(abi.encodePacked(baseUri, tokenId.toString()))
            : "";
    }
}