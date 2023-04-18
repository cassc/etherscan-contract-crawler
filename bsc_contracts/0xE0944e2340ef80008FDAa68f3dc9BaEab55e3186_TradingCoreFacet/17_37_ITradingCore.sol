// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IPairsManager.sol";

interface ITradingCore {

    event UpdatePairPositionInfo(
        address indexed pairBase, uint256 lastBlock, uint256 longQty, uint256 shortQty,
        int256 longAccFundingFeePerShare, uint64 lpLongAvgPrice, uint64 lpShortAvgPrice
    );

    struct PairQty {
        uint256 longQty;
        uint256 shortQty;
    }

    struct PairPositionInfo {
        uint256 lastFundingFeeBlock;
        uint256 longQty;                   // 1e10
        uint256 shortQty;                  // 1e10
        // shortAcc = longAcc * -1
        int256 longAccFundingFeePerShare;  // 1e18
        uint64 lpLongAvgPrice;             // 1e8
        address pairBase;
        uint16 pairIndex;
        uint64 lpShortAvgPrice;
    }

    struct LpMarginTokenUnPnl {
        address token;
        int256 unPnlUsd;
    }

    struct MarginPct {
        address token;
        uint256 pct;   // 1e4
    }

    function getPairQty(address pairBase) external view returns (PairQty memory);

    function slippagePrice(address pairBase, uint256 marketPrice, uint256 qty, bool isLong) external view returns (uint256);

    function slippagePrice(
        PairQty memory pairQty,
        IPairsManager.SlippageConfig memory sc,
        uint256 marketPrice, uint256 qty, bool isLong
    ) external pure returns (uint256);

    function triggerPrice(address pairBase, uint256 limitPrice, uint256 qty, bool isLong) external view returns (uint256);

    function triggerPrice(
        PairQty memory pairQty,
        IPairsManager.SlippageConfig memory sc,
        uint256 limitPrice, uint256 qty, bool isLong
    ) external pure returns (uint256);

    function lastLongAccFundingFeePerShare(address pairBase) external view returns (int256);

    function updatePairPositionInfo(
        address pairBase, uint userPrice, uint marketPrice, uint qty, bool isLong, bool isOpen
    ) external returns (int256 longAccFundingFeePerShare);

    function lpUnrealizedPnlUsd() external view returns (int256 totalUsd, LpMarginTokenUnPnl[] memory);

    function lpUnrealizedPnlUsd(address targetToken) external view returns (int256 totalUsd, int256 tokenUsd);

    function lpNotionalUsd() external view returns (uint256);
}