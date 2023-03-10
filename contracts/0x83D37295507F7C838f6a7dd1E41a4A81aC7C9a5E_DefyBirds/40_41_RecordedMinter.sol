// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {ERC721ACommon} from "ethier/erc721/ERC721ACommon.sol";

/**
 * @title Recorded minter
 * @dev Records the blocknumber and prevrandao during mint.
 * @author Dave (@cxkoda)
 * @author The KRO raccoon
 * @custom:reviewer Arran (@divergencearran)
 */
abstract contract RecordedMinter is ERC721ACommon {
    /**
     * @dev We use this to reduce the storage requirements for blocknumber.
     */
    uint256 private immutable _blockNumberOffset;

    /**
     * @notice The mixHashes at a given block number.
     * @dev Set during `_mintRecorded`.
     */
    mapping(uint256 => uint256) private _mixHashes;

    constructor() {
        // Subtracting 1 guarantees that `block.number - _blockNumberOffset` can
        // never be zero. Hence we can use a zero value to distingish between
        // recorded and normal mints.
        _blockNumberOffset = block.number - 1;
    }

    /**
     * @notice Callback to mint tokens for a purchase.
     * @dev Store the current `block.number` and `mixHash`.
     */
    function _mintRecorded(address to, uint256 num) internal {
        uint256 startTokenId = _nextTokenId();
        _mint(to, num);

        // This applies to the entire batch of `num` tokens as per ERC721A
        // default.
        _setExtraDataAt(startTokenId, uint24(block.number - _blockNumberOffset));
        _mixHashes[block.number] = block.difficulty;
    }

    /**
     * @notice ECR721A override to propagate the storage-hitchhiking token info
     * during transfers.
     */
    function _extraData(address, address, uint24 previousExtraData)
        internal
        view
        virtual
        override
        returns (uint24)
    {
        return previousExtraData;
    }

    /**
     * @notice Returns the block in which a token has been minted.
     */
    function _mintBlockNumber(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        return uint256(_ownershipOf(tokenId).extraData) + _blockNumberOffset;
    }

    /**
     * @notice Returns the mixHash for a given token.
     */
    function _mixHashOfToken(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        return _mixHashes[_mintBlockNumber(tokenId)];
    }
}