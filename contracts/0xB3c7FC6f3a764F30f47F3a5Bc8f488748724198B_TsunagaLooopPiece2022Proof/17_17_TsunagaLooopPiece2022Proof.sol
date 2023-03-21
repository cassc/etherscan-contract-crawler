// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./BaseSBT.sol";

contract TsunagaLooopPiece2022Proof is BaseSBT {
    uint256 private constant _artTokenID = 0;
    uint256 private constant _firstPieceTokenID = 1;
    uint256 private constant _pieceCount = 9;

    constructor() BaseSBT("Tsunaga-LOOOP Piece NFT 2022 PROOF", "TLP2022P") {}

    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _baseTokenURI = uri_;

        _refreshMetadata();
    }

    function refreshMetadata() external onlyOwner {
        _refreshMetadata();
    }

    function _refreshMetadata() private {
        emit MetadataUpdate(_artTokenID);
        emit BatchMetadataUpdate(
            _firstPieceTokenID,
            _firstPieceTokenID + _pieceCount - 1
        );
    }
}