// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

struct ClaimTokenData {
    // token type is used for token type sun or peg token
    uint256 tokenType;
    address[] pegTokens;
    uint256[] pegTokensPricePercentage;
    address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
}

interface IClaimToken {
    function isClaimToken(address _claimTokenAddress)
        external
        view
        returns (bool);

    function getClaimTokensData(address _claimTokenAddress)
        external
        view
        returns (ClaimTokenData memory);

    function getClaimTokenofSUNToken(address _sunToken)
        external
        view
        returns (address);
}