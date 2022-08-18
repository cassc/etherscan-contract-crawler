// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract MultiStage {
    // merkle root per stage
    mapping(uint256 => bytes32) internal _merkleRoot;
    // mint count per stage
    mapping(uint256 => mapping(address => uint256)) internal _mintCount;
    // supply per stage
    mapping(uint256 => uint256) internal _supply;

    // Sales Parameters per stage
    mapping(uint256 => uint256) internal _maxAmount;
    mapping(uint256 => uint256) internal _maxPerMint;
    mapping(uint256 => uint256) internal _maxPerWallet;

    // States per stage
    mapping(uint256 => bool) internal _saleActive;
    mapping(uint256 => bool) internal _presaleActive;

    function maxAmount(uint256 stageId) external view returns (uint256) {
        return _maxAmount[stageId];
    }

    function maxPerMint(uint256 stageId) external view returns (uint256) {
        return _maxPerMint[stageId];
    }

    function maxPerWallet(uint256 stageId) external view returns (uint256) {
        return _maxPerWallet[stageId];
    }

    function presaleActive(uint256 stageId) external view returns (bool) {
        return _presaleActive[stageId];
    }

    function saleActive(uint256 stageId) external view returns (bool) {
        return _saleActive[stageId];
    }

    function supply(uint256 stageId) external view returns (uint256) {
        return _supply[stageId];
    }

    function mintCount(uint256 stageId, address account)
        external
        view
        returns (uint256)
    {
        return _mintCount[stageId][account];
    }

    function _startSale(
        uint256 stageId,
        uint256 newMaxAmount,
        uint256 newMaxPerWallet,
        uint256 newMaxPerMint,
        bool presale
    ) internal {
        _saleActive[stageId] = true;
        _maxAmount[stageId] = newMaxAmount;
        _maxPerWallet[stageId] = newMaxPerWallet;
        _maxPerMint[stageId] = newMaxPerMint;
        _presaleActive[stageId] = presale;
    }

    function _stopSale(uint256 stageId) internal {
        _saleActive[stageId] = false;
        _presaleActive[stageId] = false;
    }

    function _setMerkleRoot(uint256 stageId, bytes32 newRoot) internal {
        _merkleRoot[stageId] = newRoot;
    }
}