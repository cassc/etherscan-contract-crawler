pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../lib/SafeMath.sol";

/**
 * @notice Contains all the structs and convenience methods for Notional contracts.
 */
library Common {
    using SafeMath for uint256;

    bytes1 internal constant MASK_POOL = 0x01; // 0000 0001
    bytes1 internal constant MASK_NET = 0x02; // 0000 0010
    bytes1 internal constant MASK_ORDER = 0x04; // 0000 0100
    bytes1 internal constant MASK_CASH = 0x08; // 0000 1000

    bytes1 internal constant MASK_PAYER = 0x10; // 0001 0000
    bytes1 internal constant MASK_RECEIVER = 0x20; // 0010 0000
    bytes1 internal constant MASK_PERIODIC = 0x80; // 1000 0000

    int256 internal constant RATE_DECIMALS = 1e9;
    uint128 internal constant DECIMALS = 1e18;
    uint128 internal constant MAX_UINT_128 = (2**128) - 1;
    uint32 internal constant MAX_UINT_32 = (2**32) - 1;
    uint32 internal constant SECONDS_IN_YEAR = 31536000;

    /**
     * The collateral requirement per currency in the portfolio. Only used as an
     * in memory object between the RiskFramework and the freeCollateral calculation.
     */
    struct Requirement {
        // The currency group id that this requirement is for
        uint16 currency;
        // The net fCash value in this particular currency
        int256 netfCashValue;
        // Post haircut cash claims on liquidity tokens
        int256 cashClaim;
    }

    /**
     * Each asset object is a 32 byte word stored in the portfolio.
     */
    struct Asset {
        // The cash group id for this asset
        uint8 cashGroupId;
        // The instrument id for this asset
        uint16 instrumentId;
        // When this asset matures, in seconds
        uint32 maturity;
        // A 1 byte bitfield defined above that contains instrument agnostic
        // information about a asset (i.e. payer or receiver, periodic or nonperiodic)
        bytes1 assetType;
        // The rate for this asset
        uint32 rate;
        // The notional for this asset
        uint128 notional;
        // uint32 unused space
    }

    // These are the factors we used to determine how to settle or liquidate an account
    struct FreeCollateralFactors {
        // Aggregate amount of free collateral
        int256 aggregate;
        // Net available amounts in local currency
        int256 localNetAvailable;
        // Net available amounts in collateral currency
        int256 collateralNetAvailable;
        // Cash claim amount in local currency
        int256 localCashClaim;
        // Cash claim amount in collateral currency
        int256 collateralCashClaim;
    }

    /**
     * Describes a group of instruments that are closely related enough for their risk ladders to net
     * against each other. Also defines the other parameters that will apply to all the instruments in
     * the group such that their risk ladders can net against each other.
     *
     * Each risk ladder is defined by its maturity cadence which maps to an underlying fCash market,
     * therefore each Instrument Group will map to a fCash market called `cashMarket`.
     */
    struct CashGroup {
        // The maximum number of future maturities that instruments in this group will asset
        uint32 numMaturities;
        // The size of maturities (in seconds) for all instruments in this group
        uint32 maturityLength;
        // The precision of the discount rate oracle
        uint32 precision;
        // The discount rate oracle that applies to all instruments in this group
        address cashMarket;
        // The currency group identifier for this cash group
        uint16 currency;
    }

    /**
     * Used to describe deposits in ERC1155.batchOperation
     */
    struct Deposit {
        // Currency Id to deposit
        uint16 currencyId;
        // Amount of tokens to deposit
        uint128 amount;
    }

    /**
     * Used to describe withdraws in ERC1155.batchOperationWithdraw
     */
    struct Withdraw {
        // Destination of the address to withdraw to
        address to;
        // Currency Id to withdraw
        uint16 currencyId;
        // Amount of tokens to withdraw
        uint128 amount;
    }

    enum TradeType {
        TakeCurrentCash,
        TakefCash,
        AddLiquidity,
        RemoveLiquidity
    }

    /**
     * Used to describe a trade in ERC1155.batchOperation
     */
    struct Trade {
        TradeType tradeType;
        uint8 cashGroup;
        uint32 maturity;
        uint128 amount;
        bytes slippageData;
    }

    /**
     * Checks if a asset is a periodic asset, i.e. it matures on the cadence
     * defined by its Instrument Group.
     */
    function isPeriodic(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_PERIODIC) == MASK_PERIODIC);
    }

    /**
     * Checks if a asset is a payer, meaning that the asset is an obligation
     * to pay cash when the asset matures.
     */
    function isPayer(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_PAYER) == MASK_PAYER);
    }

    /**
     * Checks if a asset is a receiver, meaning that the asset is an entitlement
     * to recieve cash when asset matures.
     */
    function isReceiver(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_RECEIVER) == MASK_RECEIVER);
    }

    /**
     * Checks if a asset is a liquidity token, which represents a claim on collateral
     * and fCash in a fCash market. The liquidity token can only be stored
     * as a receiver in the portfolio, but it can be marked as a payer in memory when
     * the contracts remove liquidity.
     */
    function isLiquidityToken(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_ORDER) == MASK_ORDER && (assetType & MASK_CASH) == MASK_CASH);
    }

    /**
     * Checks if an object is a fCash token.
     */
    function isCash(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_ORDER) == 0x00 && (assetType & MASK_CASH) == MASK_CASH);
    }

    function isCashPayer(bytes1 assetType) internal pure returns (bool) {
        return isCash(assetType) && isPayer(assetType);
    }

    function isCashReceiver(bytes1 assetType) internal pure returns (bool) {
        return isCash(assetType) && isReceiver(assetType) && !isLiquidityToken(assetType);
    }

    /**
     * Changes a asset into its counterparty asset.
     */
    function makeCounterparty(bytes1 assetType) internal pure returns (bytes1) {
        if (isPayer(assetType)) {
            return ((assetType & ~(MASK_PAYER)) | MASK_RECEIVER);
        } else {
            return ((assetType & ~(MASK_RECEIVER)) | MASK_PAYER);
        }
    }

    /**
     * Returns a liquidity token asset type, this is marked as receiver that
     * will be stored in the portfolio.
     */
    function getLiquidityToken() internal pure returns (bytes1) {
        return MASK_RECEIVER | MASK_CASH | MASK_PERIODIC | MASK_ORDER;
    }

    function getCashPayer() internal pure returns (bytes1) {
        return MASK_PAYER | MASK_CASH | MASK_PERIODIC;
    }

    function getCashReceiver() internal pure returns (bytes1) {
        return MASK_RECEIVER | MASK_CASH | MASK_PERIODIC;
    }

    /**
     * Returns the asset type from an encoded asset id.
     */
    function getAssetType(uint256 id) internal pure returns (bytes1) {
        return bytes1(bytes32(id) << 248);
    }

    /**
     * Creates a 32 byte asset id from a asset object. This is used to represent the asset in
     * the ERC1155 token standard. The actual id is located in the least significant 8 bytes
     * of the id. The ordering of the elements in the id are important because they define how
     * a portfolio will be sorted by `Common._sortPortfolio`.
     */
    function encodeAssetId(Asset memory asset) internal pure returns (uint256) {
        bytes8 id = (bytes8(bytes1(asset.cashGroupId)) & 0xFF00000000000000) |
            ((bytes8(bytes2(asset.instrumentId)) >> 8) & 0x00FFFF0000000000) |
            ((bytes8(bytes4(asset.maturity)) >> 24) & 0x000000FFFFFFFF00) |
            ((bytes8(asset.assetType) >> 56) & 0x00000000000000FF);

        return uint256(bytes32(id) >> 192);
    }

    /**
     * Decodes a uint256 id for a asset
     *
     * @param _id a uint256 asset id
     * @return (cashGroupId, instrumentId, maturity)
     */
    function decodeAssetId(uint256 _id) internal pure returns (uint8, uint16, uint32)
    {
        bytes32 id = bytes32(_id);
        return (
            // Instrument Group Id
            uint8(bytes1((id & 0x000000000000000000000000000000000000000000000000FF00000000000000) << 192)),
            // Instrument Id
            uint16(bytes2((id & 0x00000000000000000000000000000000000000000000000000FFFF0000000000) << 200)),
            // Maturity
            uint32(bytes4((id & 0x000000000000000000000000000000000000000000000000000000FFFFFFFF00) << 216))
        );
    }

    /**
     * Does a quicksort of the portfolio by the 256 bit id. This sorting is used in a few
     * algorithms to ensure that they work properly.
     *
     * @param data the in memory portfolio to sort
     */
    function _sortPortfolio(Asset[] memory data) internal pure returns (Asset[] memory) {
        if (data.length > 0) {
            _quickSort(data, int256(0), int256(data.length - 1));
        }
        return data;
    }

    function _quickSort(
        Asset[] memory data,
        int256 left,
        int256 right
    ) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;

        uint256 pivot = encodeAssetId(data[uint256(left + (right - left) / 2)]);
        while (i <= j) {
            while (encodeAssetId(data[uint256(i)]) < pivot) i++;
            while (pivot < encodeAssetId(data[uint256(j)])) j--;
            if (i <= j) {
                // Swap positions
                (data[uint256(i)], data[uint256(j)]) = (data[uint256(j)], data[uint256(i)]);
                i++;
                j--;
            }
        }

        if (left < j) _quickSort(data, left, j);
        if (i < right) _quickSort(data, i, right);
    }
}