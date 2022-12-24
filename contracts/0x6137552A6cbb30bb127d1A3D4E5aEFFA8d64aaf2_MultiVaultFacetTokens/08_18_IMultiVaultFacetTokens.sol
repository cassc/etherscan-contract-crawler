// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./../IEverscale.sol";


interface IMultiVaultFacetTokens {
    enum TokenType { Native, Alien }

    struct TokenPrefix {
        uint activation;
        string name;
        string symbol;
    }

    struct TokenMeta {
        string name;
        string symbol;
        uint8 decimals;
    }

    struct Token {
        uint activation;
        bool blacklisted;
        uint depositFee;
        uint withdrawFee;
        bool isNative;
        address custom;
    }

    function prefixes(address _token) external view returns (TokenPrefix memory);
    function tokens(address _token) external view returns (Token memory);
    function natives(address _token) external view returns (IEverscale.EverscaleAddress memory);

    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external;

    function setTokenBlacklist(
        address token,
        bool blacklisted
    ) external;

    function getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) external view returns (address);
}