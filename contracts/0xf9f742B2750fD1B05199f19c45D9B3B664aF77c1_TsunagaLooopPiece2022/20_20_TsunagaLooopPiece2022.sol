// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./BaseNFT.sol";

contract TsunagaLooopPiece2022 is BaseNFT {
    uint256 private constant _artTokenID = 0;
    uint256 private constant _firstPieceTokenID = 1;
    uint256 private constant _pieceCount = 9;

    mapping(uint256 tokenID => bool isAirdropped) private _isAirdroppeds;
    mapping(uint256 tokenID => bool isFitted) private _isFitteds;

    constructor(
        address firstOwnerProof_
    ) BaseNFT("Tsunaga-LOOOP Piece NFT 2022", "TLP2022", firstOwnerProof_) {}

    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _baseTokenURI = uri_;

        _refreshMetadata();
    }

    function airdrop(address to_, uint256 tokenID_) external onlyMinter {
        require(
            _firstPieceTokenID <= tokenID_ &&
                tokenID_ < _firstPieceTokenID + _pieceCount,
            "TsunagaLooopPiece2022: invalid token ID"
        );
        require(
            !_isAirdroppeds[tokenID_],
            "TsunagaLooopPiece2022: already airdropped"
        );

        _isAirdroppeds[tokenID_] = true;

        _mint(to_, tokenID_, tokenID_);
    }

    function isFitted(uint256 tokenID_) external view returns (bool) {
        return _isFitteds[tokenID_];
    }

    function fit(uint256 tokenID_) external {
        _requireApprovedOrOwner(msg.sender, tokenID_);

        _isFitteds[tokenID_] = true;

        _burn(tokenID_);
    }

    function mintArt() external onlyOwner {
        for (
            uint256 pieceTokenID = _firstPieceTokenID;
            pieceTokenID < _firstPieceTokenID + _pieceCount;
            pieceTokenID++
        ) {
            require(
                _isFitteds[pieceTokenID],
                "TsunagaLooopPiece2022: not all pieces fitted"
            );
        }

        _mint(msg.sender, _artTokenID, _artTokenID);
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