/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAutoMarketMakerCore.sol";
import "./IMatchingEngineCore.sol";
import "./IFee.sol";

interface IMatchingEngineAMM is
    IFee,
    IAutoMarketMakerCore,
    IMatchingEngineCore
{
    struct InitParams {
        IERC20 quoteAsset;
        IERC20 baseAsset;
        uint256 basisPoint;
        uint128 maxFindingWordsIndex;
        uint128 initialPip;
        uint128 pipRange;
        uint32 tickSpace;
        address positionLiquidity;
        address spotHouse;
        address router;
    }

    struct ExchangedData {
        uint256 baseAmount;
        uint256 quoteAmount;
        uint256 feeQuoteAmount;
        uint256 feeBaseAmount;
    }

    /// @notice init the pair right after cloned
    /// @param params the init params with struct InitParams
    /// @dev save storage the init data
    function initialize(InitParams memory params) external;

    /// @notice get the base and quote amount can claim
    /// @param pip the pip of the order
    /// @param orderId id of order in pip
    /// @param exData the base amount
    /// @param basisPoint the basis point of price
    /// @param fee the fee percent
    /// @param feeBasis the basis fee froe calculate
    /// @return the Exchanged data
    /// @dev calculate the base and quote from order and pip
    function accumulateClaimableAmount(
        uint128 pip,
        uint64 orderId,
        ExchangedData memory exData,
        uint256 basisPoint,
        uint16 fee,
        uint128 feeBasis
    ) external view returns (ExchangedData memory);
}