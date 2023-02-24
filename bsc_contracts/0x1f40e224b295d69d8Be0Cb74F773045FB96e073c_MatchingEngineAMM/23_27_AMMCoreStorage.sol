// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../../interfaces/IAutoMarketMakerCore.sol";

abstract contract AMMCoreStorage is IAutoMarketMakerCore {
    /// @inheritdoc IAutoMarketMakerCore
    /// @notice the range of liquidity
    uint128 public override pipRange;

    /// @inheritdoc IAutoMarketMakerCore
    /// @notice the tick space of external bulid order book
    uint32 public override tickSpace;

    /// @inheritdoc IAutoMarketMakerCore
    /// @notice the current index pip active
    uint256 public override currentIndexedPipRange;

    /// @inheritdoc IAutoMarketMakerCore
    /// @notice the mapping with index and the liquidity of index
    mapping(uint256 => Liquidity.Info) public override liquidityInfo;

    /// @inheritdoc IAutoMarketMakerCore
    IGetFeeShareAMM public override spotFactory;
}