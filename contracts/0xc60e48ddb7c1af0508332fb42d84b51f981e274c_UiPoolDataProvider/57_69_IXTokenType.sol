// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IXTokenType
 * @author ParallelFi
 * @notice Defines the basic interface for an IXTokenType.
 **/
enum XTokenType {
    PhantomData, // unused
    NToken,
    NTokenMoonBirds,
    NTokenUniswapV3,
    NTokenBAYC,
    NTokenMAYC,
    PToken,
    DelegationAwarePToken,
    RebasingPToken,
    PTokenAToken,
    PTokenStETH,
    PTokenSApe,
    NTokenBAKC,
    PYieldToken,
    PTokenCAPE,
    NTokenOtherdeed,
    NTokenStakefish,
    NTokenChromieSquiggle,
    PhantomData1,
    PhantomData2,
    PhantomData3,
    PhantomData4,
    PhantomData5,
    PhantomData6,
    PhantomData7,
    PhantomData8,
    PhantomData9,
    PhantomData10,
    PTokenStKSM
}

interface IXTokenType {
    /**
     * @notice return token type`of xToken
     **/
    function getXTokenType() external pure returns (XTokenType);
}