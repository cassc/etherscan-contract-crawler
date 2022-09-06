// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IIkaniV1MetadataController } from "../interfaces/IIkaniV1MetadataController.sol";

/**
 * @title StaticUriMetadataController
 * @author Cyborg Labs, LLC
 *
 * @notice Implementation of the tokenURI function using a static URI.
 */
contract StaticUriMetadataController is
    Ownable,
    IIkaniV1MetadataController
{
    string internal _STATIC_URI_;

    constructor(
        string memory staticUri
    ) {
        _STATIC_URI_ = staticUri;
    }

    function setStaticUri(
        string calldata staticUri
    )
        external
        onlyOwner
    {
        _STATIC_URI_ = staticUri;
    }

    function tokenURI(
        uint256 /* tokenId */
    )
        external
        view
        override
        returns (string memory)
    {
        return _STATIC_URI_;
    }
}