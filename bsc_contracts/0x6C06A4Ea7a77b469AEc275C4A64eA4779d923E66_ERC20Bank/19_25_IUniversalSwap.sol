// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "./INFTPoolInteractor.sol";
import "../libraries/SwapFinder.sol";
import "../libraries/Conversions.sol";

struct Desired {
    address[] outputERC20s;
    Asset[] outputERC721s;
    uint256[] ratios;
    uint256[] minAmountsOut;
}

struct Provided {
    address[] tokens;
    uint256[] amounts;
    Asset[] nfts;
}

/// @title Interface for UniversalSwap utility
/// @notice UniversalSwap allows trading between pool tokens and tokens tradeable on DEXes
interface IUniversalSwap {
    /// Getters
    function networkToken() external view returns (address tokenAddress);
    function oracle() external view returns (address oracle);
    function stableToken() external view returns (address stableToken);
    function getSwappers() external view returns (address[] memory swappers);
    function getPoolInteractors() external view returns (address[] memory poolInteractors);
    function getNFTPoolInteractors() external view returns (address[] memory nftPoolInteractors);

    /// @notice Checks if a provided token is composed of other underlying tokens or not
    function isSimpleToken(address token) external view returns (bool);

    /// @notice Get the pool interactor for a token
    function getProtocol(address token) external view returns (address);

    /// @notice get values of provided tokens and amounts in terms of network token
    function getTokenValues(
        address[] memory tokens,
        uint256[] memory tokenAmounts
    ) external view returns (uint256[] memory values, uint256 total);

    /// @notice Estimates the combined values of the provided tokens in terms of another token
    /// @param assets ERC20 or ERC721 assets for whom the value needs to be estimated
    /// @param inTermsOf Token whose value equivalent value to the provided tokens needs to be returned
    /// @return value The amount of inTermsOf that is equal in value to the provided tokens
    function estimateValue(Provided memory assets, address inTermsOf) external view returns (uint256 value);

    /// @notice Checks if a provided token is swappable using UniversalSwap
    /// @param token Address of token to be swapped or swapped for
    /// @return supported Wether the provided token is supported or not
    function isSupported(address token) external returns (bool supported);

    /// @notice Estimates the value of a single ERC20 token in terms of another ERC20 token
    function estimateValueERC20(address token, uint256 amount, address inTermsOf) external view returns (uint256 value);

    /// @notice Estimates the value of an ECR721 token in terms of an ERC20 token
    function estimateValueERC721(Asset memory nft, address inTermsOf) external view returns (uint256 value);

    /// @notice Find the underlying tokens and amounts for some complex tokens
    function getUnderlying(
        Provided memory provided
    ) external view returns (address[] memory underlyingTokens, uint256[] memory underlyingAmounts);

    /// @notice Performs the pre swap computation and calculates the approximate amounts and corresponding usd values that can be expected from the swap
    /// @return amounts Amounts of the desired assets that can be expected to be received during the actual swap
    /// @return swaps Swaps that need to be performed with the provided assets
    /// @return conversions List of conversions from simple ERC20 tokens to complex assets such as LP tokens, Uniswap v3 positions, etc
    /// @return expectedUSDValues Expected usd values for the assets that can be expected from the swap
    function getAmountsOut(
        Provided memory provided,
        Desired memory desired
    )
        external
        view
        returns (
            uint256[] memory amounts,
            SwapPoint[] memory swaps,
            Conversion[] memory conversions,
            uint256[] memory expectedUSDValues
        );

    /// @notice The pre swap computations can be performed off-chain much faster, hence this function was created as a faster alternative to getAmountsOut
    /// @notice Calculates the expected amounts and usd values from a swap given the pre swap calculations
    function getAmountsOutWithSwaps(
        Provided memory provided,
        Desired memory desired,
        SwapPoint[] memory swaps,
        Conversion[] memory conversions
    ) external view returns (uint[] memory amounts, uint[] memory expectedUSDValues);

    /// @notice Calculate the underlying tokens, amount and values for provided assets in a swap, as well
    /// as the conversions needed to obtain desired assets along with the conversion underlying and the value that needs to be allocated to each underlying
    /// @param provided List of provided ERC20/ERC721 assets provided to convert into the desired assets
    /// @param desired Assets to convert provided assets into
    /// @return tokens Tokens that can be obtained by breaking down complex assets in provided
    /// @return amounts Amounts of tokens that will be obtained from breaking down provided assetts
    /// @return values Worth of the amounts of tokens, in terms of usd or network token (not relevant which for purpose of swapping)
    /// @return conversions Data structures representing the conversions that need to take place from simple assets to complex assets to obtain the desired assets
    /// @return conversionUnderlying The simplest tokens needed in order to perform the previously mentioned conversions
    /// @return conversionUnderlyingValues The values in terms of usd or network token that need to be allocated to each of the underlying tokens in order to perform the conversions
    function preSwapCalculateUnderlying(
        Provided memory provided,
        Desired memory desired
    )
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory values,
            Conversion[] memory conversions,
            address[] memory conversionUnderlying,
            uint256[] memory conversionUnderlyingValues
        );

    /// @notice Calculates the swaps and conversions that need to be performed prior to calling swap/swapAfterTransfer
    /// @notice It is recommended to use this function and provide the return values to swap/swapAfterTransfer as that greatly reduces gas consumption
    /// @return swaps Swaps that need to be performed with the provided assets
    /// @return conversions List of conversions from simple ERC20 tokens to complex assets such as LP tokens, Uniswap v3 positions, etc
    function preSwapCalculateSwaps(
        Provided memory provided,
        Desired memory desired
    ) external view returns (SwapPoint[] memory swaps, Conversion[] memory conversions);

    /// @notice Swap provided assets into desired assets
    /// @dev Before calling, make sure UniversalSwap contract has approvals to transfer provided assets
    /// @dev swaps ans conversions can be provided as empty list, in which case the contract will calculate them, but this will result in high gas usage
    /// @param provided List of provided ERC20/ERC721 assets provided to convert into the desired assets
    /// @param swaps Swaps that need to be performed with the provided assets
    /// @param conversions List of conversions from simple ERC20 tokens to complex assets such as LP tokens, Uniswap v3 positions, etc
    /// @param desired Assets to convert provided assets into
    /// @param receiver Address that will receive output desired assets
    /// @return amountsAndIds Amount of outputTokens obtained and Token IDs for output NFTs
    function swap(
        Provided memory provided,
        SwapPoint[] memory swaps,
        Conversion[] memory conversions,
        Desired memory desired,
        address receiver
    ) external payable returns (uint256[] memory amountsAndIds);

    /// @notice Functions just like swap, but assets are transferred to universal swap contract before calling this function rather than using approval
    /// @notice Implemented as a way to save gas by eliminating needless transfers
    /// @dev Before calling, make sure all assets in provided have been transferred to universal swap contract
    /// @param provided List of provided ERC20/ERC721 assets provided to convert into the desired assets
    /// @param swaps Swaps that need to be performed with the provided assets. Can be provided as empty list, in which case it will be calculated by the contract
    /// @param conversions List of conversions from simple ERC20 tokens to complex assets such as LP tokens, Uniswap v3 positions, etc. Can be provided as empty list.
    /// @param desired Assets to convert provided assets into
    /// @param receiver Address that will receive output desired assets
    /// @return amountsAndIds Amount of outputTokens obtained and Token IDs for output NFTs
    function swapAfterTransfer(
        Provided memory provided,
        SwapPoint[] memory swaps,
        Conversion[] memory conversions,
        Desired memory desired,
        address receiver
    ) external payable returns (uint256[] memory amountsAndIds);

    /// Setters
    function setSwappers(address[] calldata _swappers) external;
    function setOracle(address _oracle) external;
    function setPoolInteractors(address[] calldata _poolInteractors) external;
    function setNFTPoolInteractors(address[] calldata _nftPoolInteractors) external;
}