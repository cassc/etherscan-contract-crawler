// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Rates {
    uint256 internal _feeBuys;
    uint256 internal _feeSells;
    uint256 internal _divBases = 1e4;
    address internal _marketingWallet;
    address[] internal _marks;

    function __Rates_init(address marketingWallet_, uint256 feeBuy_, uint256 feeSell_, address[] memory marks_) internal {
        _marketingWallet = marketingWallet_;
        _feeBuys = feeBuy_;
        _feeSells = feeSell_;
        _marks = marks_;
    }

    function resetRates(uint256 _buy, uint256 _sell) internal {
        if (_feeBuys != _buy) _feeBuys = _buy;
        if (_feeBuys != _sell) _feeSells = _sell;
    }
}