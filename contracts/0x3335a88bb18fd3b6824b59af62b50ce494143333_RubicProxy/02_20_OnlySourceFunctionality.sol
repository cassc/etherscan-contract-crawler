// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./04_20_BridgeBase.sol";

contract OnlySourceFunctionality is BridgeBase {
    event RequestSent(BaseCrossChainParams parameters);

    modifier eventEmitter(BaseCrossChainParams calldata _params) {
        _;
        emit RequestSent(_params);
    }

    function __OnlySourceFunctionalityInit(
        uint256 _fixedCryptoFee,
        uint256 _RubicPlatformFee,
        address[] memory _routers,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts
    ) internal onlyInitializing {
        __BridgeBaseInit(_fixedCryptoFee, _RubicPlatformFee, _routers, _tokens, _minTokenAmounts, _maxTokenAmounts);
    }
}