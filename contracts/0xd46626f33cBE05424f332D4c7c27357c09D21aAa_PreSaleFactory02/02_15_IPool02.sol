// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1;

interface IPool02 {
    // normal pool
    function initialize(
        address _token,
        uint256 _duration,
        uint256 _openTime,
        address _offeredCurrency,
        uint256 _offeredCurrencyDecimals,
        uint256 _offeredRate,
        uint256 _taxRate,
        address _walletAddress,
        address _signer
    ) external;

    // pre-sale pool
    function initialize(
        address _token,
        address _offeredCurrency,
        uint256 _offeredRate,
        uint256 _offeredCurrencyDecimals,
        uint256 _taxRate,
        address _wallet,
        address _signer
    ) external;
}