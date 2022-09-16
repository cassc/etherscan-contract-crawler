// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../libraries/IndexLibrary.sol";

contract TestIndexLibrary {
    function amountInAsset(
        uint _assetPerBaseInUQ,
        uint8 _weight,
        uint _amountInBase
    ) external pure returns (uint) {
        return IndexLibrary.amountInAsset(_assetPerBaseInUQ, _weight, _amountInBase);
    }
}