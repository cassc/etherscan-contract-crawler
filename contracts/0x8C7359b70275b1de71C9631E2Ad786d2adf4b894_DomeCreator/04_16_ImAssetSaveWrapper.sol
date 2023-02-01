// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ImAssetSaveWrapper {
    function saveViaMint(
        address _mAsset,
        address _save,
        address _vault,
        address _bAsset,
        uint256 _amount,
        uint256 _minOut,
        bool _stake
    ) external;
}