// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SacrificeMintDiscount} from "./SacrificeMintDiscount.sol";

interface IMintOnRareboard {
    function mint(
        address _collection,
        address _to,
        uint256 _amount
    ) external payable;
}

abstract contract RareboardSacrificeMintDiscount is SacrificeMintDiscount {
    address public immutable mintOnRareboard =
        0xd695ef1990f1DCc33AD5884128432b0e5F962481;

    function _mint(
        address _to,
        uint256 _amount,
        uint256 _value
    ) internal virtual override {
        IMintOnRareboard(mintOnRareboard).mint{value: _value}(
            token,
            _to,
            _amount
        );
    }
}