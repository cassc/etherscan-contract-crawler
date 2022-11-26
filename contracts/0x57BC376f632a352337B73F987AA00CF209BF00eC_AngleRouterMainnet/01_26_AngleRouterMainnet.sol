// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "../../interfaces/IFeeDistributorFront.sol";
import "../../interfaces/ISanToken.sol";
import "../../interfaces/IStableMasterFront.sol";
import "../../interfaces/IVeANGLE.sol";

import "../../BaseRouter.sol";

// ============================= STRUCTS AND ENUMS =============================

/// @notice References to the contracts associated to a collateral for a stablecoin
struct Pairs {
    IPoolManager poolManager;
    IPerpetualManagerFrontWithClaim perpetualManager;
    ISanToken sanToken;
    ILiquidityGauge gauge;
}

/// @title AngleRouterMainnet
/// @author Angle Core Team
/// @notice Router contract built specifially for Angle use cases on Ethereum
/// @dev Interfaces were designed for both advanced users which know the addresses of the protocol's contract,
/// but most of the time users which only know addresses of the stablecoins and collateral types of the protocol
/// can perform the actions they want without needing to understand what's happening under the hood
contract AngleRouterMainnet is BaseRouter {
    using SafeERC20 for IERC20;

    // =================================== ERRORS ==================================

    error InvalidParams();

    // ================================== MAPPINGS =================================

    /// @notice Maps an agToken to its counterpart `StableMaster`
    mapping(IERC20 => IStableMasterFront) public mapStableMasters;
    /// @notice Maps a `StableMaster` to a mapping of collateral token to its counterpart `PoolManager`
    mapping(IStableMasterFront => mapping(IERC20 => Pairs)) public mapPoolManagers;

    uint256[48] private __gapMainnet;

    function initialize(
        address _core,
        address _uniswapRouter,
        address _oneInch,
        IERC20 angleAddress,
        IERC20[] calldata stablecoins,
        IPoolManager[] calldata poolManagers,
        ILiquidityGauge[] calldata liquidityGauges,
        bool[] calldata justLiquidityGauges
    ) external {
        initializeRouter(_core, _uniswapRouter, _oneInch);
        angleAddress.safeIncreaseAllowance(address(_getVeANGLE()), type(uint256).max);
        // agEUR and StableMaster for agEUR
        mapStableMasters[IERC20(0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8)] = IStableMasterFront(
            0x5adDc89785D75C86aB939E9e15bfBBb7Fc086A87
        );
        _addPairs(stablecoins, poolManagers, liquidityGauges, justLiquidityGauges);
    }

    // =========================== ROUTER FUNCTIONALITIES ==========================

    /// @inheritdoc BaseRouter
    function _chainSpecificAction(ActionType action, bytes calldata data) internal override {
        if (action == ActionType.claimRewardsWithPerps) {
            (
                address user,
                address[] memory claimLiquidityGauges,
                uint256[] memory claimPerpetualIDs,
                bool addressProcessed,
                address[] memory stablecoins,
                address[] memory collateralsOrPerpetualManagers
            ) = abi.decode(data, (address, address[], uint256[], bool, address[], address[]));
            _claimRewardsWithPerps(
                user,
                claimLiquidityGauges,
                claimPerpetualIDs,
                addressProcessed,
                stablecoins,
                collateralsOrPerpetualManagers
            );
        } else if (action == ActionType.claimWeeklyInterest) {
            (address user, address feeDistributor, bool letInContract) = abi.decode(data, (address, address, bool));
            _claimWeeklyInterest(user, IFeeDistributorFront(feeDistributor), letInContract);
        } else if (action == ActionType.veANGLEDeposit) {
            (address user, uint256 amount) = abi.decode(data, (address, uint256));
            _depositOnLocker(user, amount);
        } else if (action == ActionType.deposit) {
            (
                address user,
                uint256 amount,
                bool addressProcessed,
                address stablecoinOrStableMaster,
                address collateral,
                address poolManager
            ) = abi.decode(data, (address, uint256, bool, address, address, address));
            _deposit(user, amount, addressProcessed, stablecoinOrStableMaster, collateral, IPoolManager(poolManager));
        } else if (action == ActionType.withdraw) {
            (
                uint256 amount,
                bool addressProcessed,
                address stablecoinOrStableMaster,
                address collateralOrPoolManager,
                address sanToken
            ) = abi.decode(data, (uint256, bool, address, address, address));
            if (amount == type(uint256).max) amount = IERC20(sanToken).balanceOf(address(this));
            _withdraw(amount, addressProcessed, stablecoinOrStableMaster, collateralOrPoolManager);
        } else if (action == ActionType.mint) {
            (
                address user,
                uint256 amount,
                uint256 minStableAmount,
                bool addressProcessed,
                address stablecoinOrStableMaster,
                address collateral,
                address poolManager
            ) = abi.decode(data, (address, uint256, uint256, bool, address, address, address));
            _mint(
                user,
                amount,
                minStableAmount,
                addressProcessed,
                stablecoinOrStableMaster,
                collateral,
                IPoolManager(poolManager)
            );
        } else if (action == ActionType.openPerpetual) {
            (
                address user,
                uint256 amount,
                uint256 amountCommitted,
                uint256 extremeRateOracle,
                uint256 minNetMargin,
                bool addressProcessed,
                address stablecoinOrPerpetualManager,
                address collateral
            ) = abi.decode(data, (address, uint256, uint256, uint256, uint256, bool, address, address));
            _openPerpetual(
                user,
                amount,
                amountCommitted,
                extremeRateOracle,
                minNetMargin,
                addressProcessed,
                stablecoinOrPerpetualManager,
                collateral
            );
        } else if (action == ActionType.addToPerpetual) {
            (
                uint256 amount,
                uint256 perpetualID,
                bool addressProcessed,
                address stablecoinOrPerpetualManager,
                address collateral
            ) = abi.decode(data, (uint256, uint256, bool, address, address));
            _addToPerpetual(amount, perpetualID, addressProcessed, stablecoinOrPerpetualManager, collateral);
        }
    }

    /// @inheritdoc BaseRouter
    function _getNativeWrapper() internal pure override returns (IWETH9) {
        return IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    /// @notice Claims rewards for multiple gauges and perpetuals at once
    /// @param gaugeUser Address for which to fetch the rewards from the gauges
    /// @param liquidityGauges Gauges to claim on
    /// @param perpetualIDs Perpetual IDs to claim rewards for
    /// @param addressProcessed Whether `PerpetualManager` list is already accessible in `collateralsOrPerpetualManagers` or if
    ///  it should be retrieved from `stablecoins` and `collateralsOrPerpetualManagers`
    /// @param stablecoins Stablecoin contracts linked to the perpetualsIDs. Array of zero addresses if `addressProcessed` is true
    /// @param collateralsOrPerpetualManagers Collateral contracts linked to the perpetualsIDs or `perpetualManager` contracts if
    /// `addressProcessed` is true
    function _claimRewardsWithPerps(
        address gaugeUser,
        address[] memory liquidityGauges,
        uint256[] memory perpetualIDs,
        bool addressProcessed,
        address[] memory stablecoins,
        address[] memory collateralsOrPerpetualManagers
    ) internal {
        uint256 perpetualIDsLength = perpetualIDs.length;
        if (
            perpetualIDsLength != 0 &&
            (stablecoins.length != perpetualIDsLength || collateralsOrPerpetualManagers.length != perpetualIDsLength)
        ) revert IncompatibleLengths();

        uint256 liquidityGaugesLength = liquidityGauges.length;
        for (uint256 i; i < liquidityGaugesLength; ++i) {
            ILiquidityGauge(liquidityGauges[i]).claim_rewards(gaugeUser);
        }

        for (uint256 i; i < perpetualIDsLength; ++i) {
            IPerpetualManagerFrontWithClaim perpManager;
            if (addressProcessed) perpManager = IPerpetualManagerFrontWithClaim(collateralsOrPerpetualManagers[i]);
            else {
                (, Pairs memory pairs) = _getInternalContracts(
                    IERC20(stablecoins[i]),
                    IERC20(collateralsOrPerpetualManagers[i])
                );
                perpManager = pairs.perpetualManager;
            }
            perpManager.getReward(perpetualIDs[i]);
        }
    }

    /// @notice Deposits ANGLE on an existing locker
    /// @param user Address to deposit for
    /// @param amount Amount to deposit
    function _depositOnLocker(address user, uint256 amount) internal {
        _getVeANGLE().deposit_for(user, amount);
    }

    /// @notice Claims weekly interest distribution and if wanted transfers it to the contract for future use
    /// @param user Address to claim for
    /// @param _feeDistributor Address of the fee distributor to claim to
    /// @dev If `letInContract` (and hence if funds are transferred to the router), you should approve the `angleRouter` to
    /// transfer the token claimed from the `feeDistributor`
    function _claimWeeklyInterest(
        address user,
        IFeeDistributorFront _feeDistributor,
        bool letInContract
    ) internal {
        uint256 amount = _feeDistributor.claim(user);
        if (letInContract) {
            // Fetching info from the `FeeDistributor` to process correctly the withdrawal
            IERC20 token = IERC20(_feeDistributor.token());
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    /// @notice Mints stablecoins using the Core module of the protocol
    /// @param user Address to send the stablecoins to
    /// @param amount Amount of collateral to use for the mint
    /// @param minStableAmount Minimum stablecoin minted for the tx not to revert
    /// @param addressProcessed Whether `msg.sender` provided the contracts address or the tokens one
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateral Collateral to mint from: it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the mint
    /// @param poolManager PoolManager associated to the `collateral` (null if `addressProcessed` is not true)
    function _mint(
        address user,
        uint256 amount,
        uint256 minStableAmount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateral,
        IPoolManager poolManager
    ) internal {
        IStableMasterFront stableMaster;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(IERC20(stablecoinOrStableMaster), IERC20(collateral));
            poolManager = pairs.poolManager;
        }
        stableMaster.mint(amount, user, poolManager, minStableAmount);
    }

    /// @notice Deposits collateral in the Core Module of the protocol
    /// @param user Address where to send the resulting sanTokens, if this address is the router address then it means
    /// that the intention is to stake the sanTokens obtained in a subsequent `gaugeDeposit` action
    /// @param amount Amount of collateral to deposit
    /// @param addressProcessed Whether `msg.sender` provided the contracts addresses or the tokens ones
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateral Token to deposit: it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the deposit
    /// @param poolManager PoolManager associated to the `collateral` (null if `addressProcessed` is not true)
    function _deposit(
        address user,
        uint256 amount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateral,
        IPoolManager poolManager
    ) internal {
        IStableMasterFront stableMaster;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(IERC20(stablecoinOrStableMaster), IERC20(collateral));
            poolManager = pairs.poolManager;
        }
        stableMaster.deposit(amount, user, poolManager);
    }

    /// @notice Withdraws sanTokens from the protocol
    /// @param amount Amount of sanTokens to withdraw
    /// @param addressProcessed Whether `msg.sender` provided the contracts addresses or the tokens ones
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateralOrPoolManager Collateral to withdraw (if `addressProcessed` is false) or directly
    /// the `PoolManager` contract if `addressProcessed`
    function _withdraw(
        uint256 amount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateralOrPoolManager
    ) internal {
        IStableMasterFront stableMaster;
        IPoolManager poolManager;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
            poolManager = IPoolManager(collateralOrPoolManager);
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(
                IERC20(stablecoinOrStableMaster),
                IERC20(collateralOrPoolManager)
            );
            poolManager = pairs.poolManager;
        }
        stableMaster.withdraw(amount, address(this), address(this), poolManager);
    }

    /// @notice Opens a perpetual within the Core Module
    /// @param owner Address to mint perpetual for
    /// @param margin Margin to open the perpetual with
    /// @param amountCommitted Commit amount in the perpetual
    /// @param maxOracleRate Maximum oracle rate required to have a leverage position opened
    /// @param minNetMargin Minimum net margin required to have a leverage position opened
    /// @param addressProcessed Whether msg.sender provided the contracts addresses or the tokens ones
    /// @param stablecoinOrPerpetualManager Token associated to the `StableMaster` (iif `addressProcessed` is false)
    /// or address of the desired `PerpetualManager` (if `addressProcessed` is true)
    /// @param collateral Collateral to mint from (it can be null if `addressProcessed` is true): it can be null if
    /// `addressProcessed` is true but in the corresponding action, the `mixer` needs to get a correct address to compute
    /// the amount of tokens to use for the deposit
    function _openPerpetual(
        address owner,
        uint256 margin,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin,
        bool addressProcessed,
        address stablecoinOrPerpetualManager,
        address collateral
    ) internal returns (uint256 perpetualID) {
        if (!addressProcessed) {
            (, Pairs memory pairs) = _getInternalContracts(IERC20(stablecoinOrPerpetualManager), IERC20(collateral));
            stablecoinOrPerpetualManager = address(pairs.perpetualManager);
        }
        return
            IPerpetualManagerFrontWithClaim(stablecoinOrPerpetualManager).openPerpetual(
                owner,
                margin,
                amountCommitted,
                maxOracleRate,
                minNetMargin
            );
    }

    /// @notice Adds collateral to a perpetual
    /// @param margin Amount of collateral to add
    /// @param perpetualID Perpetual to add collateral to
    /// @param addressProcessed Whether msg.sender provided the contracts addresses or the tokens ones
    /// @param stablecoinOrPerpetualManager Token associated to the `StableMaster` (iif `addressProcessed` is false)
    /// or address of the desired `PerpetualManager` (if `addressProcessed` is true)
    /// @param collateral Collateral to mint from (it can be null if `addressProcessed` is true): it can be null
    /// if `addressProcessed` is true but in the corresponding action, the `mixer` needs to get a correct address
    /// to compute the amount of tokens to use for the deposit
    function _addToPerpetual(
        uint256 margin,
        uint256 perpetualID,
        bool addressProcessed,
        address stablecoinOrPerpetualManager,
        address collateral
    ) internal {
        if (!addressProcessed) {
            (, Pairs memory pairs) = _getInternalContracts(IERC20(stablecoinOrPerpetualManager), IERC20(collateral));
            stablecoinOrPerpetualManager = address(pairs.perpetualManager);
        }
        IPerpetualManagerFrontWithClaim(stablecoinOrPerpetualManager).addToPerpetual(perpetualID, margin);
    }

    // ============================ GOVERNANCE UTILITIES ===========================

    /// @notice Adds a new `StableMaster`
    /// @param stablecoin Address of the new stablecoin
    /// @param stableMaster Address of the new `StableMaster`
    function addStableMaster(IERC20 stablecoin, IStableMasterFront stableMaster) external onlyGovernorOrGuardian {
        if (
            address(stablecoin) == address(0) ||
            address(mapStableMasters[stablecoin]) != address(0) ||
            stableMaster.agToken() != address(stablecoin)
        ) revert InvalidParams();
        mapStableMasters[stablecoin] = stableMaster;
    }

    /// @notice Adds new collateral types to specific stablecoins
    /// @param stablecoins Addresses of the stablecoins associated to the `StableMaster` of interest
    /// @param poolManagers Addresses of the `PoolManager` contracts associated to the pair (stablecoin,collateral)
    /// @param liquidityGauges Addresses of liquidity gauges contract associated to sanToken
    /// @param justLiquidityGauges Whether just the liquidity gauge addresses should be added
    function addPairs(
        IERC20[] calldata stablecoins,
        IPoolManager[] calldata poolManagers,
        ILiquidityGauge[] calldata liquidityGauges,
        bool[] calldata justLiquidityGauges
    ) external onlyGovernorOrGuardian {
        _addPairs(stablecoins, poolManagers, liquidityGauges, justLiquidityGauges);
    }

    // ========================= INTERNAL UTILITY FUNCTIONS ========================

    /// @notice Gets Angle contracts associated to a pair (stablecoin, collateral)
    /// @param stablecoin Token associated to a `StableMaster`
    /// @param collateral Collateral to mint/deposit/open perpetual or add collateral from
    /// @dev This function is used to check that the parameters passed by people calling some of the main
    /// router functions are correct
    function _getInternalContracts(IERC20 stablecoin, IERC20 collateral)
        internal
        view
        returns (IStableMasterFront stableMaster, Pairs memory pairs)
    {
        stableMaster = mapStableMasters[stablecoin];
        pairs = mapPoolManagers[stableMaster][collateral];
        if (address(stableMaster) == address(0) || address(pairs.poolManager) == address(0)) revert ZeroAddress();
        return (stableMaster, pairs);
    }

    /// @notice Internal version of the `addPairs` function
    function _addPairs(
        IERC20[] calldata stablecoins,
        IPoolManager[] calldata poolManagers,
        ILiquidityGauge[] calldata liquidityGauges,
        bool[] calldata justLiquidityGauges
    ) internal {
        uint256 stablecoinsLength = stablecoins.length;
        if (
            poolManagers.length != stablecoinsLength ||
            liquidityGauges.length != stablecoinsLength ||
            justLiquidityGauges.length != stablecoinsLength
        ) revert IncompatibleLengths();
        for (uint256 i; i < stablecoinsLength; ++i) {
            IStableMasterFront stableMaster = mapStableMasters[stablecoins[i]];
            _addPair(stableMaster, poolManagers[i], liquidityGauges[i], justLiquidityGauges[i]);
        }
    }

    /// @notice Adds new collateral type to specific stablecoin
    /// @param stableMaster Address of the `StableMaster` associated to the stablecoin of interest
    /// @param poolManager Address of the `PoolManager` contract associated to the pair (stablecoin,collateral)
    /// @param liquidityGauge Address of the liquidity gauge contract associated to sanToken
    /// @param justLiquidityGauge Whether we should just update the liquidity gauge address
    function _addPair(
        IStableMasterFront stableMaster,
        IPoolManager poolManager,
        ILiquidityGauge liquidityGauge,
        bool justLiquidityGauge
    ) internal {
        // Fetching the associated `sanToken` and `perpetualManager` from the contract
        (
            IERC20 collateral,
            ISanToken sanToken,
            IPerpetualManagerFrontWithClaim perpetualManager,
            ,
            ,
            ,
            ,
            ,

        ) = stableMaster.collateralMap(poolManager);
        // Reverting if the poolManager is not a valid `poolManager`
        if (address(collateral) == address(0)) revert InvalidParams();
        Pairs storage _pairs = mapPoolManagers[stableMaster][collateral];
        if (justLiquidityGauge) {
            // Cannot specify a liquidity gauge if the associated poolManager does not exist
            if (address(_pairs.poolManager) == address(0)) revert ZeroAddress();
            ILiquidityGauge gauge = _pairs.gauge;
            if (address(gauge) != address(0)) {
                _changeAllowance(IERC20(address(sanToken)), address(gauge), 0);
            }
        } else {
            // Checking if the pair has not already been initialized: if yes we need to make the function revert
            // otherwise we could end up with still approved `PoolManager` and `PerpetualManager` contracts
            if (address(_pairs.poolManager) != address(0)) revert InvalidParams();
            _pairs.poolManager = poolManager;
            _pairs.perpetualManager = IPerpetualManagerFrontWithClaim(address(perpetualManager));
            _pairs.sanToken = sanToken;
            _changeAllowance(collateral, address(stableMaster), type(uint256).max);
            _changeAllowance(collateral, address(perpetualManager), type(uint256).max);
        }
        _pairs.gauge = liquidityGauge;
        if (address(liquidityGauge) != address(0)) {
            if (address(sanToken) != liquidityGauge.staking_token()) revert InvalidParams();
            _changeAllowance(IERC20(address(sanToken)), address(liquidityGauge), type(uint256).max);
        }
    }

    /// @notice Returns the veANGLE address
    function _getVeANGLE() internal view virtual returns (IVeANGLE) {
        return IVeANGLE(0x0C462Dbb9EC8cD1630f1728B2CFD2769d09f0dd5);
    }
}