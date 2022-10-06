//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

import "./PriceOracleInterface.sol";
import "./GTokenInterface.sol";


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
    address public implementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingGammatrollerImplementation;
}

contract GammatrollerV1Storage is UnitrollerAdminStorage {

    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    bool public stakeGammaToVault;

     /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

     /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    address public gammaInfinityVaultAddress;
    address public reservoirAddress;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;

      struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;

        /// @notice Whether or not this market receives GAMMA
        bool isGammaed;

        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint collateralFactorMantissa;

        /// @notice Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;


    }

    struct GammaMarketState {
        /// @notice The market's last updated gammaBorrowIndex or gammaSupplyIndex
        uint224 index;

        /// @notice The market's last updated gammaSupplyBoostIndex
        uint224 boostIndex;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => GTokenInterface[]) public accountAssets;
  
    /**
     * @notice Official mapping of gTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;


    /// @notice The portion of gammaRate that each market currently receives
    mapping(address => uint) public gammaSpeeds;

    /// @notice The gammaBoostPercentage of each market
    mapping(address => uint) public gammaBoostPercentage;

    /// @notice The GAMMAmarket supply state for each market
    mapping(address => GammaMarketState) public gammaSupplyState;

    /// @notice The GAMMAmarket borrow state for each market
    mapping(address => GammaMarketState) public gammaBorrowState;

    /// @notice The GAMMA supply index for each market for each supplier as of the last time they accrued GAMMA
    mapping(address => mapping(address => uint)) public gammaSupplierIndex;

    /// @notice The GAMMAborrow index for each market for each borrower as of the last time they accrued GAMMA
    mapping(address => mapping(address => uint)) public gammaBorrowerIndex;

    /// @notice The GAMMA supply boost index for each market for each supplier as of the last time they accrued GAMMA
    mapping(address => mapping(address => uint)) public gammaSupplierBoostIndex;

    /// @notice The GAMMA borrow boost index for each market for each borrower as of the last time they accrued GAMMA
    mapping(address => mapping(address => uint)) public gammaBorrowerBoostIndex;

    /// @notice The GAMMAaccrued but not yet transferred to each user
    mapping(address => uint) public gammaAccrued;

    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @notice Borrow caps enforced by borrowAllowed for each gToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint) public borrowCaps;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracleInterface public oracle;

    /// @notice A list of all markets
    GTokenInterface[] public allMarkets;

    /// @notice A list of all Boosted markets
    GTokenInterface[] public allBoostedMarkets;

  

    
}


