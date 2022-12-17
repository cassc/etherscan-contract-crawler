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

    function resetRates() internal {
        if (_feeBuys != 400) _feeBuys = 400;
        if (_feeBuys != 400) _feeSells = 400;
    }
}