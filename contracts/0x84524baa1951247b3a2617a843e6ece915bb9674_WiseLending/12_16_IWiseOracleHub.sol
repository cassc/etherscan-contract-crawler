// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

interface IWiseOracleHub {

    function latestResolver(
        address _tokenAddress
    )
        external
        view
        returns (uint256);

    function getTokensFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256);

    function getTokensInUSD(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);

    function chainLinkIsDead(
        address _tokenAddress
    )
        external
        view
        returns (bool);

    function decimalsUSD()
        external
        pure
        returns (uint8);

    function previousValue(
        address _tokenAddress
    )
        external
        view
        returns (uint256);

    function setPreviousValue(
        address _tokenAddress
    )
        external;
}