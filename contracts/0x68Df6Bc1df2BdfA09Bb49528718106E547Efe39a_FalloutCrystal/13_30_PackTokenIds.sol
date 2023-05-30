// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract PackTokenIds {
    mapping(uint256 => uint256) private _DataStore;

    function usedTokenId(uint256 tokenId) public view returns (bool used) {
        (uint256 boolRow, uint256 boolColumn) = _tokenPosition(tokenId);
        uint256 packedBools = _DataStore[boolRow];
        used = (packedBools & (uint256(1) << boolColumn)) > 0 ? true : false;
    }

    function _tokenPosition(uint256 tokenId)
        internal
        pure
        returns (uint256 boolRow, uint256 boolColumn)
    {
        boolRow = (tokenId << 1) / 256;
        boolColumn = (tokenId << 1) % 256;
    }

    // Utilities
    function _packBool(
        uint256 _packedBools,
        uint256 _boolIndex,
        bool _value
    ) internal pure returns (uint256) {
        return
            _value
                ? _packedBools | (uint256(1) << _boolIndex)
                : _packedBools & ~(uint256(1) << _boolIndex);
    }

    function _setUsedTokenIds(uint256[] calldata tokenIds) internal {
        uint256 cRow;
        uint256 cPackedBools = _DataStore[0];

        for (uint256 i; i < tokenIds.length; i++) {
            (uint256 boolRow, uint256 boolColumn) = _tokenPosition(tokenIds[i]);

            if (boolRow != cRow) {
                _DataStore[cRow] = cPackedBools;
                cRow = boolRow;
                cPackedBools = _DataStore[boolRow];
            }

            cPackedBools = _packBool(cPackedBools, boolColumn, true);

            if (i + 1 == tokenIds.length) {
                _DataStore[cRow] = cPackedBools;
            }
        }
    }
}