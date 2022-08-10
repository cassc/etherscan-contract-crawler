// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract WithFee {
    uint256 internal _transferFee;
    uint256 internal _mintingFee;

    FeeType internal _transferFeeType;
    FeeType internal _mintingFeeType;

    enum FeeType {
        Percentage,
        Fixed
    }

    constructor(
        uint256 transferFee,
        uint256 mintingFee,
        FeeType transferFeeType,
        FeeType mintingFeeType
    ) {
        _transferFee = transferFee;
        _mintingFee = mintingFee;
        _transferFeeType = transferFeeType;
        _mintingFeeType = mintingFeeType;
    }

    function _calculateMintingFee(uint256 amount)
        internal
        view
        returns (uint256)
    {
        if (_mintingFeeType == FeeType.Percentage) {
            return (amount * _mintingFee) / 1 ether;
        }
        return _mintingFee;
    }

    function _setMintingFee(uint256 fee) internal {
        _mintingFee = fee;
    }

    function _setMintingFeeType(FeeType feeType) internal {
        _mintingFeeType = feeType;
    }

    function _calculateTransferFee(uint256 amount)
        internal
        view
        returns (uint256)
    {
        if (_transferFeeType == FeeType.Percentage) {
            return (amount * _transferFee) / 1 ether;
        }
        return _transferFee;
    }

    function _setTransferFee(uint256 fee) internal {
        _transferFee = fee;
    }

    function _setTransferFeeType(FeeType feeType) internal {
        _transferFeeType = feeType;
    }
}