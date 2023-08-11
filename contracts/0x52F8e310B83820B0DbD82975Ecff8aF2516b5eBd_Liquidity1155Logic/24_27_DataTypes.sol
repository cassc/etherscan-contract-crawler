// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title library for Data structures
 * @author Souq.Finance
 * @notice Defines the structures used by the contracts of the Souq protocol
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
library DataTypes {
    struct ERC1155Collection {
        address tokenAddress;
        uint256 tokenID;
    }

    struct AMMShare1155 {
        uint256 tokenId;
        uint256 amount;
    }

    struct Shares1155Params {
        uint256[] amounts;
        uint256[] tokenIds;
    }

    struct ParamGroup {
        uint256 amount;
        uint256 tokenId;
        uint256 subPoolId;
    }

    struct SubPoolGroup {
        uint256 id;
        uint256 counter;
        uint256 total;
        AMMShare1155[] shares;
        SharesCalculationReturn sharesCal;
    }
    struct SharePrice {
        uint256 id;
        uint256 value;
        FeeReturn fees;
    }
    struct MoveSharesVars {
        uint256 i;
        uint256 poolId;
    }
    struct Quotation {
        uint256 total;
        FeeReturn fees;
        SharePrice[] shares;
    }
    struct QuoteParams {
        bool buy;
        bool useFee;
    }
    struct LocalQuoteVars {
        uint256 i;
        uint256 y;
        uint256 total;
        uint256 poolId;
        uint256 counter;
        uint256 counterShares;
        FeeReturn fees;
        SubPoolGroup currentSubPool;
        AMMShare1155 currentShare;
        SubPoolGroup[] subPoolGroups;
    }
    struct LocalGroupVars {
        uint256 i;
        uint256 index;
        uint256 subPoolId;
        SharesCalculationReturn cal;
        ParamGroup[] paramGroups;
    }
    struct Withdraw1155Data {
        address to;
        uint256 unlockTimestamp;
        uint256 amount;
        AMMShare1155[] shares;
    }

    struct Queued1155Withdrawals {
        mapping(uint => Withdraw1155Data) withdrawals;
        //Head is for reading and next is for saving
        uint256 headId;
        uint256 nextId;
    }

    struct AMMSubPool1155 {
        uint256 reserve;
        uint256 totalShares;
        bool status;
        uint256 V;
        uint256 F;
        //tokenid -> amount
        mapping(uint256 => uint256) shares;
    }

    struct AMMSubPool1155Details {
        uint256 reserve;
        uint256 totalShares;
        uint256 V;
        uint256 F;
        bool status;
    }

    struct FactoryFeeConfig {
        uint256 lpBuyFee;
        uint256 lpSellFee;
        uint256 minLpFee;
        uint256 maxLpBuyFee;
        uint256 maxLpSellFee;
        uint256 protocolSellRatio;
        uint256 protocolBuyRatio;
        uint256 minProtocolRatio;
        uint256 maxProtocolRatio;
        uint256 royaltiesBuyFee;
        uint256 royaltiesSellFee;
        uint256 maxRoyaltiesFee;
    }
    struct PoolFee {
        uint256 lpBuyFee;
        uint256 lpSellFee;
        uint256 royaltiesBuyFee;
        uint256 royaltiesSellFee;
        uint256 protocolBuyRatio;
        uint256 protocolSellRatio;
        uint256 royaltiesBalance;
        uint256 protocolBalance;
        address royaltiesAddress;
        address protocolFeeAddress;
    }

    //cooldown between deposit and withdraw in seconds
    //percentage and multiplier are in wad and wadPercentage
    struct LiquidityLimit {
        uint256 poolTvlLimit;
        uint256 cooldown;
        uint256 maxDepositPercentage;
        uint256 maxWithdrawPercentage;
        uint256 minFeeMultiplier;
        uint256 maxFeeMultiplier;
        uint8 addLiqMode;
        uint8 removeLiqMode;
        bool onlyAdminProvisioning;
    }
    struct IterativeLimit {
        uint256 minimumF;
        uint16 maxBulkStepSize;
        uint16 iterations;
    }

    struct PoolData {
        bool useAccessToken;
        address accessToken;
        address poolLPToken;
        address stable;
        address[] tokens;
        address stableYieldAddress;
        uint256 coefficientA;
        uint256 coefficientB;
        uint256 coefficientC;
        PoolFee fee;
        LiquidityLimit liquidityLimit;
        IterativeLimit iterativeLimit;
    }

    struct FeeReturn {
        uint256 totalFee;
        uint256 swapFee;
        uint256 lpFee;
        uint256 royalties;
        uint256 protocolFee;
    }
    struct SharesCalculationVars {
        uint16 i;
        uint256 V;
        uint256 PV;
        uint256 PV_0;
        uint256 swapPV;
        uint256 shares;
        uint256 stable;
        uint256 value;
        uint256 den;
        uint256 newCash;
        uint256 newShares;
        uint256 steps;
        uint256 stepIndex;
        uint256 stepAmount;
        FeeReturn fees;
    }

    struct SharesCalculationReturn {
        uint256 PV;
        uint256 swapPV;
        uint256 amount;
        uint256 value;
        uint256 F;
        FeeReturn fees;
    }

    struct LiqLocalVars {
        uint256 TVL;
        uint256 LPPrice;
        uint256 LPAmount;
        uint256 stable;
        uint256 stableTotal;
        uint256 stableRemaining;
        uint256 weighted;
        uint256 poolId;
        uint256 maxLPPerShares;
        uint256 remainingLP;
        uint256 i;
        uint256 y;
        uint256 counter;
        AMMShare1155 currentShare;
        SubPoolGroup currentSubPool;
        SubPoolGroup[] subPoolGroups;
    }
    struct SwapLocalVars {
        uint256 stable;
        uint256 stableOut;
        uint256 remaining;
        uint256 poolId;
        uint256 i;
        uint256 y;
        uint256 counter;
        AMMShare1155 currentShare;
        SubPoolGroup currentSubPool;
        SubPoolGroup[] subPoolGroups;
        FeeReturn fees;
    }
    enum FeeType {
        royalties,
        protocol
    }
    enum OperationType {
        buyShares,
        sellShares
    }
}