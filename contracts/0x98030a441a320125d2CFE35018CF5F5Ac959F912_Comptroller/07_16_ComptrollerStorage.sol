pragma solidity ^0.5.16;

import "./CToken.sol";
import "./PriceOracle.sol";

contract UnitrollerAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of Unitroller
     */
    address public comptrollerImplementation;

    /**
     * @notice Pending brains of Unitroller
     */
    address public pendingComptrollerImplementation;
}

contract ComptrollerV1Storage is UnitrollerAdminStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => CToken[]) public accountAssets;

    enum Version {
        VANILLA,
        COLLATERALCAP,
        WRAPPEDNATIVE
    }

    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;
        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint256 collateralFactorMantissa;
        /// @notice Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;
        /// @notice CToken version
        Version version;
    }

    /**
     * @notice Official mapping of cTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public guardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice A list of all markets
    CToken[] public allMarkets;

    /// @notice The portion of compRate that each market currently receives
    /// @dev This storage is deprecated.
    mapping(address => uint256) public compSpeeds;

    /// @notice The COMP market supply state for each market
    /// @dev This storage is deprecated.
    mapping(address => CompMarketState) public compSupplyState;

    /// @notice The COMP market borrow state for each market
    /// @dev This storage is deprecated.
    mapping(address => CompMarketState) public compBorrowState;

    /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
    /// @dev This storage is deprecated.
    mapping(address => mapping(address => uint256)) public compSupplierIndex;

    /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
    /// @dev This storage is deprecated.
    mapping(address => mapping(address => uint256)) public compBorrowerIndex;

    /// @notice The COMP accrued but not yet transferred to each user
    /// @dev This storage is deprecated.
    mapping(address => uint256) public compAccrued;

    /// @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    /// @notice Borrow caps enforced by borrowAllowed for each cToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint256) public borrowCaps;

    /// @notice The supplyCapGuardian can set supplyCaps to any number for any market. Lowering the supply cap could disable supplying to the given market.
    address public supplyCapGuardian;

    /// @notice Supply caps enforced by mintAllowed for each cToken address. Defaults to zero which corresponds to unlimited supplying.
    mapping(address => uint256) public supplyCaps;

    /// @notice creditLimits allowed specific protocols to borrow and repay without collateral.
    /// @dev This storage is deprecated.
    mapping(address => uint256) internal _oldCreditLimits;

    /// @notice flashloanGuardianPaused can pause flash loan as a safety mechanism.
    mapping(address => bool) public flashloanGuardianPaused;

    /// @notice liquidityMining the liquidity mining module that handles the LM rewards distribution.
    address public liquidityMining;

    /// @notice creditLimits allowed specific protocols to borrow and repay specific markets without collateral.
    mapping(address => mapping(address => uint256)) internal _creditLimits;

    /// @notice isMarketSoftDelisted records the market which has been soft delisted by us.
    mapping(address => bool) public isMarketSoftDelisted;

    /// @notice creditLimitManager is the role who is in charge of increasing the credit limit.
    address public creditLimitManager;

    /// @notice A list of all soft delisted markets
    address[] public softDelistedMarkets;
}