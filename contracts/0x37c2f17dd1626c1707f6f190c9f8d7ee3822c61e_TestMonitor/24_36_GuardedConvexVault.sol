// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC4626} from "./libs/ERC4626.sol";
import {ERC20} from "./libs/ERC20.sol";
import {SafeTransferLib} from "./libs/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libs/FixedPointMathLib.sol";
import {ArchVault} from "./interfaces/ArchVault.sol";
import {IGuardedConvexStrategy} from "./interfaces/IGuardedConvexStrategy.sol";
import "./interfaces/IConvexBaseRewardPool.sol";
import "./interfaces/IConvexBooster.sol";
import "./interfaces/ICurvePool.sol";
import "./libs/WETH.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import {BasicAccessController as AccessControl} from "./AccessControl.sol";
import "hardhat/console.sol";

/*
    TODO: 
    * create test suit 
    * revert on unneeded functions (ERC4626 and ERC20 functions) - WIP
    * reconsider using Uniswap v3 for CRV and CVX swaps (CVX pool fee is 1%) - Nice to have
    * Test what happens when we own a very small precentage of the pool 
    * Preview hard, might require changing to v2
    * write where you pause the contract, cant deposit but can withdraw and then can unpause and deposit 
    * Tests for access control, specifically test executive role 
    * Disable exhanges as needed 
 */

/// @title GuardedConvexVault
/// @notice Based on Solmate ERC4626 tokenized Vault implementation (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
/// @notice after deposit, vault stakes Convex LP tokens in Convex booster
contract GuardedConvexVault is
    ERC4626,
    ArchVault,
    ReentrancyGuard,
    Pausable,
    AccessControl
{
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // variables
    uint256 internal minEthBalanceProportion = 30; // actual number is MAX_BALANCE_PROPORTION/decimalShiftForProportion = actual ratio
    uint256 internal maxEthOwnershipProportion = 50; // actual number is maxEthOwnershipProportion /  decimalShiftProportion = actual percentage ownership of pool we allow
    uint256 internal minIdleEthForAction = 100 ether; // minimum balance to trigger adjustIn
    uint256 internal adjustOutEthProportion = 20; // amount to adjust out if ownership hits max
    uint256 internal adjustInEthProportion = 80; // % of max ownership to adjust in
    uint256 internal pullOutMinEthAmountModifier = 10; // slippage for minimum eth on pull out
    uint256 internal minEthAmountInPool = 5 ether; // minimum amount to have in pool. otherwise we pull out everything
    uint256 internal minAmountOfEthToAdjustIn = 1 ether; // minimum amount of eth to adjust in
    uint256 internal minEthAmountForDoHardWork = 5e17 wei; // minimum amount of eth from rewards to adjust out | .5ether
    uint256 internal minUnderlyingValue = 1e15 wei; // minimum amount of underlying value to adjust out | .001LPToken

    uint256 internal lastAdjustedOutTime = 0;
    uint256 internal lastAdjustedInTime = 0;
    uint256 internal minCoolDownForAdjustOut = 6 hours;
    uint256 internal feeNumerator = 10; // 10%
    address internal treasuryAddress;

    bool private initialized;
    // constants
    int128 internal constant NATIVE_ETH_INDEX = 0;
    uint256 internal constant DECIMAL_SHIFT_HUNDRED = 100;
    uint8 internal constant EIGHTEEN_DECIMALS = 18;
    address internal constant CRV_TOKEN =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CVX_TOKEN =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    address payable internal constant WETH_ADDRESS =
        payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address internal constant UNISWAP_V3_ROUTER_ADDRESS =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; // Uniswap V3 Router address on Ethereum mainnet

    // contracts
    ISwapRouter internal uniswapV3Router;
    ERC20 internal crvToken;
    ERC20 internal cvxToken;
    WETH internal wethToken;
    ERC20 internal convexLPToken;
    ICurvePool internal curvePool;
    IConvexBooster internal convexBoosterPool;
    IConvexBaseRewardPool internal convexBaseRewardPool;
    IGuardedConvexStrategy internal zapper;
    uint256 convexPoolId;

    // how many Convex LP tokens are currently managed by the vault (and staked in Convex)
    uint256 internal tokensUnderManagement = 0;

    /// @notice Constructor for the GuardedConvexVault contract
    /// @param _convexLPToken Address of the Convex LP token
    /// @param _name Name of our vault token
    /// @param _symbol Symbol of our token token
    constructor(
        address _convexLPToken,
        string memory _name,
        string memory _symbol
    ) ERC4626(ERC20(_convexLPToken), _name, _symbol) {
        convexLPToken = ERC20(_convexLPToken);
        _grantRole(ADMIN_ROLE, _msgSender());
    }

    /// @param _curvePool Address of the Curve pool (for newer pools, same as token address)
    /// @param _convexBoosterPool Address of the Convex booster pool
    /// @param _convexRewardPool Address of the Convex reward pool
    /// @param _convexPoolId ID of the Convex pool
    function initialize(
        address _curvePool,
        address _convexBoosterPool,
        address _convexRewardPool,
        uint256 _convexPoolId
    ) external onlyAdmin {
        require(!initialized, "contract already initialized");
        curvePool = ICurvePool(_curvePool);
        convexBoosterPool = IConvexBooster(_convexBoosterPool);
        convexBaseRewardPool = IConvexBaseRewardPool(_convexRewardPool);

        crvToken = ERC20(CRV_TOKEN);
        cvxToken = ERC20(CVX_TOKEN);
        wethToken = WETH(WETH_ADDRESS);
        convexPoolId = _convexPoolId;
        uniswapV3Router = ISwapRouter(UNISWAP_V3_ROUTER_ADDRESS);

        // inifinite approval for Convex BaseRewardPool
        convexLPToken.approve(_convexRewardPool, type(uint256).max);

        // approve WETH contract to unwrap WETH
        wethToken.approve(WETH_ADDRESS, type(uint256).max);

        // approve Uniswap v3 router to spend CRV and CVX
        crvToken.approve(address(uniswapV3Router), type(uint256).max);
        cvxToken.approve(address(uniswapV3Router), type(uint256).max);

        // approve Convex pool to take Curve LP tokens
        curvePool.approve(address(convexBoosterPool), type(uint256).max);

        // just for testing purposes - remove later
        feeNumerator = 10;
        treasuryAddress = msg.sender;
        setExecutive(_msgSender());
        setExecutive2(_msgSender());
        setZapper(_msgSender());
        initialized = true;
    }

    /**
     * @notice Deposits assets and stakes them in Convex reward pool
     * @param assets The amount of assets to deposit
     * @param receiver The address of the receiver who will receive the vault shares and staked assets
     * @return shares The number of shares received after depositing and staking assets
     */
    function depositAndStake(uint256 assets, address receiver)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        // wrapper function for readability
        uint256 sharesReturned = deposit(assets, receiver);

        return sharesReturned;
    }

    /**
     * @notice Redeems assets and unstakes them from Convex reward pool
     * @param shares The number of shares to redeem, convert to Convex LPs and unstake
     * @param receiver The address of the receiver who will receive the redeemed and unstaked assets
     * @param owner The address of the owner who initially staked the assets
     * @return assets (Convex LP tokens) The amount of assets received after redeeming and unstaking shares
     */
    function redeemAndUnstake(
        uint256 shares,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 assets) {
        // wrapper function for readability
        return redeem(shares, receiver, owner);
    }

    /// @notice So we can get ETH to contract
    receive() external payable {}

    /// @notice Returns the total assets managed by the contract
    /// @return Total assets (Convex LP tokens) under management (LP tokens that are stake in the Convex BaseRewardPool)
    function totalAssets() public view override returns (uint256) {
        // Implement your logic for returning total assets here
        return tokensUnderManagement;
    }

    function claimAndConvertRewards(uint256 _minETHAmount)
        internal
        returns (
            uint256 crvTokenAmount,
            uint256 cvxTokenAmount,
            uint256 ethAmount
        )
    {
        // 1. Get rewards
        convexBaseRewardPool.getReward();

        // 2. Record CRV and CVX rewards
        uint256 crvAmount = crvToken.balanceOf(address(this));
        uint256 cvxAmount = cvxToken.balanceOf(address(this));
        // after getting rewards check that its > 0 and revert if not
        require(crvAmount > 0 || cvxAmount > 0, "no rewards to recompound ");
        // print claimed CRV and CVX amounts

        // 3. Convert CRV rewards to ETH
        _convertCRVToWETH(crvAmount, 0);

        // 4. Convert CVX rewards to ETH
        _convertCVXToWETH(cvxAmount, 0);

        // 5. Record ETH amount and check if it's greater than or equal to _minETHAmount
        //uint256 ethAmount = address(this).balance;
        uint256 wethAmount = wethToken.balanceOf(address(this));
        require(
            wethAmount >= _minETHAmount,
            "ETH amount is less than the minimum specified"
        );

        // unwrap WETH to ETH
        wethToken.withdraw(wethAmount);

        return (crvAmount, cvxAmount, wethAmount);
    }

    function recompoundEth(uint256 _ethAmount, uint256 _minCurveLPAmount)
        internal
        returns (uint256 stakedConvexLPTokens)
    {
        // 6. Add liquidity to Curve pool
        curvePool.add_liquidity{value: _ethAmount}([_ethAmount, 0], 0);

        // 7. Deposit Curve LP tokens with Convex
        uint256 curveLPTokens = curvePool.balanceOf(address(this));
        require(
            curveLPTokens >= _minCurveLPAmount,
            "Curve LP token amount is less than the minimum specified"
        );

        convexBoosterPool.deposit(convexPoolId, curveLPTokens, false);

        // 8. Record Convex LP tokens and update tokensUnderManagement
        // note: using balanceOf for this, if someone moves tokens to this contract it should not generate problems and be considered as rewards
        uint256 convexLPTokens = convexLPToken.balanceOf(address(this));
        tokensUnderManagement += convexLPTokens;

        // 9. Stake tokens with Convex
        convexBaseRewardPool.stake(convexLPTokens);

        return convexLPTokens;
    }

    function takeFeeFromRewards(uint256 ethAmount) internal returns (uint256) {
        // take fee from ethAmount using FEE_DENOMINATOR variable (10%)

        uint256 feeAmount = getFractionbyProportion(ethAmount, feeNumerator);
        uint256 ethAmountAfterFee = ethAmount - feeAmount;
        // transfer feeAmount to treasury address
        payable(treasuryAddress).transfer(feeAmount);
        return ethAmountAfterFee;
    }

    /// @notice Executes the hard work of managing the underlying assets
    /// @notice Privilaged function. Only callable by the owner
    /// @param _minETHAmount Minimum amount of ETH expected after swapping rewards (calculated off chain)
    function doHardWork(uint256 _minETHAmount, uint256 _minCurveLPAmount)
        external
        onlyExecutive
    {
        // 1. Claim and convert rewards to ETH
        (
            uint256 crvAmount,
            uint256 cvxAmount,
            uint256 ethAmount
        ) = claimAndConvertRewards(_minETHAmount);

        require(
            ethAmount > minEthAmountForDoHardWork,
            "eth amount from rewards less than min to operate"
        );
        // 2. Take feeAmount from claimed eth
        uint256 ethAmountAfterFee = takeFeeFromRewards(ethAmount);
        // 3. Recompound eth from converted rewards
        uint256 convexLPTokens = recompoundEth(
            ethAmountAfterFee,
            _minCurveLPAmount
        );

        // 4. Emit event with the amounts
        emit HardWorkDone(
            crvAmount,
            cvxAmount,
            ethAmount,
            ethAmountAfterFee,
            convexLPTokens
        );

        // emit HardWorkDone(crvAmount, cvxAmount, ethAmount, 0);
    }

    /// @notice Internal function called before withdrawing assets
    /// @notice input params are calculated by the parent ERC4626 contract calling this function
    /// @param assets Amount of assets to withdraw
    /// @param shares Amount of shares to withdraw
    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        // Withdraw the deposit LP tokens from the Convex BaseRewardPool

        convexBaseRewardPool.withdraw(assets, false);
        tokensUnderManagement -= assets;
    }

    /// @notice Internal function called after depositing assets
    /// @notice input params are calculated by the parent ERC4626 contract calling this function
    /// @param assets Amount of assets to deposit
    /// @param shares Amount of shares to deposit
    function afterDeposit(uint256 assets, uint256 shares) internal override {
        // Deposit the deposit receipt tokens in the Convex BaseRewardPool
        convexBaseRewardPool.stake(assets);
        tokensUnderManagement += assets;
    }

    //TODO: ask tomer to go through these methods and see if they can be improved/merged into convertCoinToWETH
    //todo: abstract into method and leave coins and fee as parameter
    // note we should be using something like lifi , contractor will work on zapping logic

    /// @notice Internal function to convert CRV to WETH
    /// @param amount The amount of CRV to convert
    /// @param minAmount The minimum amount of WETH to receive
    function _convertCRVToWETH(uint256 amount, uint256 minAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(crvToken);
        path[1] = WETH_ADDRESS; // WETH address

        uniswapV3Router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: path[0],
                tokenOut: path[1],
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: amount,
                amountOutMinimum: minAmount,
                sqrtPriceLimitX96: 0
            })
        );
    }

    /// @notice Internal function to convert CVX to WETH
    /// @param amount The amount of CVX to convert
    /// @param minAmount The minimum amount of WETH to receive
    function _convertCVXToWETH(uint256 amount, uint256 minAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(cvxToken);
        path[1] = WETH_ADDRESS;

        // Approve the router to spend CVX tokens before swapping
        cvxToken.approve(address(uniswapV3Router), type(uint256).max);

        try
            uniswapV3Router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    fee: 10000, // 1% fee
                    recipient: address(this),
                    deadline: block.timestamp + 300000, // 5 minutes
                    amountIn: amount,
                    amountOutMinimum: minAmount,
                    sqrtPriceLimitX96: 0
                })
            )
        {} catch Error(string memory reason) {
            revert(string(abi.encodePacked("Swap failed: ", reason)));
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            revert("Swap failed");
        }
    }

    /// @notice External function to do proportion calculations (share to asset ) on arbitrary assets passed by parameter
    /// @notice this is a copy function of convertToAssets that uses the parameter instead of the totalAssets() function
    /// @param amountOfShares The amount of shares to convert
    /// @param amountOfAssets The amount of parameter assets to use for proportion
    function convertToParameterAssets(
        uint256 amountOfShares,
        uint256 amountOfAssets
    ) external view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return
            supply == 0
                ? amountOfShares
                : amountOfShares.mulDivDown(amountOfAssets, supply);
    }

    /// depositWithoutShares function to prevent donation attacks, mints shares to zero address

    function depositWithoutShares(uint256 _initialAmount) external {
        require(_initialAmount > 0, "initial amount must be greater than 0");
        // tokensUnderManagement = _initialAmount;
        deposit(_initialAmount, address(0));
    }

    // setters

    function setFeePercentage(
        uint256 _newFeePerc /**access control */
    ) external {
        feeNumerator = _newFeePerc;
    }

    function setTreasury(
        address _newTreasury /**access control */
    ) external {
        treasuryAddress = _newTreasury;
    }

    /// monitor methods

    function getPoolTokensQuantity() internal view returns (uint256, uint256) {
        uint256[2] memory balances = curvePool.get_balances();
        uint256 totalEthAmountInPool = balances[0];
        uint256 totalTokenAmountInPool = balances[1];
        require(
            totalEthAmountInPool != 0 && totalTokenAmountInPool != 0,
            "No liquidity in pool"
        );
        return (totalEthAmountInPool, totalTokenAmountInPool);
    }

    function getPoolCoins() internal view returns (address, address) {
        address ethAddress = curvePool.coins(0);
        address otherTokenAddress = curvePool.coins(1);

        return (ethAddress, otherTokenAddress);
    }

    // public for tests make internal
    function getStrategyEthAmountInPool() internal view returns (uint256) {
        // get amount of total undermanagement from vault , then calculate the withdraw one coin from curve to get the eamount of eth we have there
        uint256 totalLPUnderManagement = totalAssets();
        if (totalLPUnderManagement == 0) {
            return 0;
        }
        // note: this is possible because curve and convexLP are 1:1
        uint256 strategyEthAmountInPool = curvePool.calc_withdraw_one_coin(
            totalLPUnderManagement,
            NATIVE_ETH_INDEX
        );
        return strategyEthAmountInPool;
    }

    function getFractionbyProportion(uint256 total, uint256 proportion)
        internal
        pure
        returns (uint256)
    {
        // example 10 * 0.1 = 1
        return (total * proportion) / DECIMAL_SHIFT_HUNDRED;
    }

    function getProportion(uint256 portion, uint256 total)
        internal
        pure
        returns (uint256)
    {
        // example 10 / 100 = 0.1
        return (portion * DECIMAL_SHIFT_HUNDRED) / total;
    }

    function getOwnershipProportion(
        uint256 strategyEthAmountInPool,
        uint256 totalEthAmountInPool
    ) internal view returns (uint256) {
        uint256 ownershipProportion = getProportion(
            strategyEthAmountInPool,
            totalEthAmountInPool
        );
        return ownershipProportion;
    }

    function getFeePercentage() public view returns (uint256) {
        return feeNumerator;
    }

    // function should be internal , public for tests
    function isPoolHealthy() public view returns (bool, bool) {
        // check that eth amount in curve pool is 3x the other token amount
        (
            uint256 totalEthAmountInPool,
            uint256 totalTokenAmountInPool
        ) = getPoolTokensQuantity();
        uint256 totalAmountInPool = totalEthAmountInPool +
            totalTokenAmountInPool;
        ///check that both tokens are same decimals or adjust
        (, address otherToken) = getPoolCoins();
        uint8 otherTokenDecimals = ERC20(otherToken).decimals();
        if (otherTokenDecimals < EIGHTEEN_DECIMALS) {
            uint8 decimalDifference = EIGHTEEN_DECIMALS - otherTokenDecimals;
            totalTokenAmountInPool =
                totalTokenAmountInPool *
                10**decimalDifference;
        }

        uint256 ethProportionInPool = getProportion(
            totalEthAmountInPool,
            totalAmountInPool
        );
        // minEthBalanceProportion = 1 -> 0.01, 100 -> 1
        // minEthBalanceProportion should be 0.3 -> 30
        // totalEth = 100 , totalToken = 200 -> 100 *100 / 200 = 50
        // ethProportionInPool > minEthBalanceProportion -> 50 > 30 -> true
        // To get false
        // totalEth = 80 , totalToken = 300 -> 80 *100 / 300 = 26
        // ethProportionInPool > minEthBalanceProportion -> 26 > 30 -> false
        // uint256 ethProportionInPool = totalEthAmountInPool / totalTokenAmountInPool;
        bool isBalanceHealth = ethProportionInPool > minEthBalanceProportion;

        uint256 strategyEthAmountInPool = getStrategyEthAmountInPool();
        uint256 ownershipProportion = getOwnershipProportion(
            strategyEthAmountInPool,
            totalEthAmountInPool
        );
        // check that the amount of eth we have in the pool is less than X% of the total pool eth amount
        // check that ownershipProportion > maxEthOwnershipProportion
        // 5 * 100/ 1000000 = 0.0005 -> 0
        // 50 * 100 / 100 = 50 max ownership proportion is 30
        // 50 < 30 -> false
        // 20 * 100 / 100 = 20 max ownership proportion is 30
        // 20 < 30 -> true
        bool isOwnershipHealth = ownershipProportion <
            maxEthOwnershipProportion;
        // bool isOwnershipHealth = totalEthAmountInPool * decimalShiftForProportion  > strategyEthAmountInPool *  maxEthOwnershipProportion;
        // isOwnershipHealth = 100 * 100 > 50 * 160 -> 10000 > 8000 -> true
        return (isBalanceHealth, isOwnershipHealth);
    }

    function pullOutLPTokens(
        uint256 LPTokenAmountToPullOut,
        uint256 _minOutputEthAmount
    ) internal {
        uint256 remainingUnderlying = tokensUnderManagement -
            LPTokenAmountToPullOut;

        require(
            remainingUnderlying >= minUnderlyingValue,
            "amount to pull out would leave less than min allowed"
        );
        convexBaseRewardPool.withdraw(LPTokenAmountToPullOut, false);
        convexBoosterPool.withdraw(convexPoolId, LPTokenAmountToPullOut);
        /// Note: Third parameter is min accepted amount. Since this is an emergncy action we take slippage based on pullOutMinEthAmountModifier e.g. : 10%  = slippage up to 90%
        uint256 ethPulledOut = curvePool.remove_liquidity_one_coin(
            LPTokenAmountToPullOut - minUnderlyingValue,
            NATIVE_ETH_INDEX,
            _minOutputEthAmount
        );
        require(
            ethPulledOut > _minOutputEthAmount,
            "amount to pull out is less than min "
        );

        // transfer all idle eth to zapper (it manages the idle eth )
        payable(zapper).transfer(ethPulledOut);

        bool pullAll = LPTokenAmountToPullOut ==
            tokensUnderManagement - minUnderlyingValue;
        emit PullOutDone(
            pullAll,
            LPTokenAmountToPullOut,
            ethPulledOut,
            _minOutputEthAmount
        );
        lastAdjustedOutTime = block.timestamp;
    }

    function pullOutAllLPTokens(uint256 _minOutputEthAmount) internal {
        // pull all eth out of the pool
        uint256 underManagementMinusMin = tokensUnderManagement -
            minUnderlyingValue;
        pullOutLPTokens(underManagementMinusMin, _minOutputEthAmount);
        tokensUnderManagement = tokensUnderManagement - underManagementMinusMin;
    }

    function pullOutLPTokensByOwnership(uint256 _minOutputEthAmount) internal {
        // calculate the amount of eth to pull out of the pool so the ownership porportion is good, if that value leaves us <5ETH then pull all eth out of the pool eg: if maxEthOwnershipProportion is 30% then pull out 80% of that
        uint256 strategyEthAmountInPool = getStrategyEthAmountInPool();
        uint256 ethAmountToRemove = getFractionbyProportion(
            strategyEthAmountInPool,
            adjustOutEthProportion
        );
        uint256 strategyRemainderEthInPool = strategyEthAmountInPool -
            ethAmountToRemove;
        if (strategyRemainderEthInPool < minEthAmountInPool) {
            pullOutAllLPTokens(_minOutputEthAmount);
        } else {
            uint256 convexLPTokenAmountToRemove = getFractionbyProportion(
                tokensUnderManagement,
                adjustOutEthProportion
            );
            pullOutLPTokens(convexLPTokenAmountToRemove, _minOutputEthAmount);
            tokensUnderManagement -= convexLPTokenAmountToRemove;
        }
    }

    // reverts isPoolHealthy == true
    // withdraw _amount shares from the vault and keep ETH in this contract
    // doesn't input ETH to the vault
    // doesn't change the overall share number
    function adjustOut(uint256 _minOutputEthAmount)
        external
        onlyExecutive
        nonReentrant
    {
        /**
         * check pool health
         * get idle eth (this balance)
         *
         * if balance is unhealhty then pull all eth out of the pool
         * get amount of eth we have in the pool
         * if ownership is unhealhty then calculate the amount of eth to pull out of the pool so the ownership porportion is good, if that value leaves us <5ETH then pull all eth out of the pool
         * eg: if maxEthOwnershipProportion is 30% then pull out to have 24%
         * */
        (bool isBalanceHealthy, bool isOwnershipHealthy) = isPoolHealthy();
        require(!isBalanceHealthy || !isOwnershipHealthy, "pool is healthy");
        if (!isBalanceHealthy) {
            pullOutAllLPTokens(_minOutputEthAmount);
        }
        if (!isOwnershipHealthy && isBalanceHealthy) {
            pullOutLPTokensByOwnership(_minOutputEthAmount);
        }
    }

    function getAmountByAdjustInProportion(uint256 totalAmount)
        internal
        view
        returns (uint256)
    {
        // calculate the amount of eth to deposit into the pool so the ownership porportion is the correct adjust in proportion which is adjustInEthProportion% of maxEthOwnershipProportion
        // first get the proportion equivalent of adjustInEthProportion% of maxEthOwnershipProportion e.g. 80% of 30% = 24%
        uint256 proportiontoAdjustIn = getFractionbyProportion(
            maxEthOwnershipProportion,
            adjustInEthProportion
        );
        // then get the amount by using the new proportion so proportiontoAdjustIn% of total eth in pool e.g. 24% of 100 = 24
        return getFractionbyProportion(totalAmount, proportiontoAdjustIn);
    }

    // Take _amount ETH from the idle ETH in this contract and depsoit in the vault
    // doesn't change the overall share number or generate new shares

    function adjustIn(uint256 _minAmountOfLP)
        external
        onlyExecutive
        nonReentrant
    {
        /**
         * check pool health
         * get idle eth (this balance)
         * check last adjusted out
         * if last adjusted out is < 6 hours ago then revert
         * check pool TVL to be > $500k
         * check ownership proportion
         * if idle eth if enough to operate based on minIdleEthForAction then deposit enough to be at 80% of max ownership proportion
         * e.g. if current ownership is 15% and max is 30% then deposit enough to be at 24% (30% * 80%)
         * math: ethAmountToAdjustIn = (totalEthInPool * decimalShift / (maxProportion * 80%)) - strategyEthAmountInPool
         * if ethAmountToAdjustIn < 1ETH then revert
         */

        // check pool health
        (bool isBalanceHealthy, bool isOwnershipHealthy) = isPoolHealthy();
        require(isBalanceHealthy, "pool balance is not healthy");
        require(isOwnershipHealthy, "ownership in the pool above threshold");

        // check that last adjusted out was more than 6 hours ago
        require(
            block.timestamp - lastAdjustedOutTime > minCoolDownForAdjustOut,
            "cannot adjust in yet"
        );

        // get amount to adjust
        (uint256 totalEthAmountInPool, ) = getPoolTokensQuantity();
        uint256 strategyEthAmountInPool = getStrategyEthAmountInPool();

        uint256 maxEthAmountToOwn = getAmountByAdjustInProportion(
            totalEthAmountInPool
        );
        uint256 maxEthAmountToAdjustIn = maxEthAmountToOwn -
            strategyEthAmountInPool;
        // we reuse recompound since it does the same thing that we want to do
        // eth in curve pool->curveLP -> convexBooster deposit ->  convexLP -> stake
        uint256 ethAmountToAdjustIn = maxEthAmountToAdjustIn;
        uint256 currentBalance = address(zapper).balance;
        if (currentBalance < maxEthAmountToAdjustIn) {
            ethAmountToAdjustIn = currentBalance;
        }
        require(
            ethAmountToAdjustIn > minAmountOfEthToAdjustIn,
            "amount to adjust is less than min"
        );
        // transfer eth from zapper to this contract
        zapper.sendIdleAmountToVault(ethAmountToAdjustIn);
        uint256 convexLPTokens = recompoundEth(
            ethAmountToAdjustIn,
            _minAmountOfLP
        );
        /// call event
        emit AdjustedIn(convexLPTokens, ethAmountToAdjustIn);
    }

    // preview methods

    function previewPullOutLPTokens(uint256 _amountLPTokensToPullOut)
        internal
        view
        returns (uint256 _outputEthAmount)
    {
        // pull all eth out of the pool
        uint256 ethAmountToPullOut = curvePool.calc_withdraw_one_coin(
            _amountLPTokensToPullOut,
            NATIVE_ETH_INDEX
        );
        return ethAmountToPullOut;
    }

    function previewPullOutByOwnership()
        internal
        view
        returns (uint256 _outputEthAmount)
    {
        uint256 strategyEthAmountInPool = getStrategyEthAmountInPool();
        uint256 ethAmountToRemove = getFractionbyProportion(
            strategyEthAmountInPool,
            adjustOutEthProportion
        );
        uint256 strategyRemainderEthInPool = strategyEthAmountInPool -
            ethAmountToRemove;
        if (strategyRemainderEthInPool < minEthAmountInPool) {
            return previewPullOutAllLPTokens();
        } else {
            uint256 convexLPTokenAmountToRemove = getFractionbyProportion(
                tokensUnderManagement,
                adjustOutEthProportion
            );
            return previewPullOutLPTokens(convexLPTokenAmountToRemove);
        }
    }

    function previewPullOutAllLPTokens()
        internal
        view
        returns (uint256 _outputEthAmount)
    {
        // pull all eth out of the pool
        uint256 LPTokenAmountToPullOut = tokensUnderManagement;
        uint256 ethAmountToPullOut = previewPullOutLPTokens(
            LPTokenAmountToPullOut
        );
        return ethAmountToPullOut;
    }

    function previewAdjustOut()
        external
        view
        returns (uint256 _outputEthAmount)
    {
        // get pool health
        (bool isBalanceHealthy, bool isOwnershipHealthy) = isPoolHealthy();
        // if balance unhealthy preview pulling it all out
        if (!isBalanceHealthy) {
            return previewPullOutAllLPTokens();
        }
        // if ownership unhealthy preview pulling out by ownership
        if (isBalanceHealthy && !isOwnershipHealthy) {
            return previewPullOutByOwnership();
        }
        // if ownership and balance healthy then return 0
        return 0;
    }

    function previewAdjustIn()
        external
        view
        returns (uint256 _outputUnderlying, uint256 _amountOfEthToAdjust)
    {
        // check pool health
        (bool isBalanceHealthy, bool isOwnershipHealthy) = isPoolHealthy();
        bool cooldownCheck = (block.timestamp - lastAdjustedOutTime) >
            minCoolDownForAdjustOut;
        if (!isBalanceHealthy || !isOwnershipHealthy || !cooldownCheck) {
            return (0, 0);
        }
        (uint256 totalEthAmountInPool, ) = getPoolTokensQuantity();
        uint256 strategyEthAmountInPool = getStrategyEthAmountInPool();

        uint256 maxAmountToOwn = getAmountByAdjustInProportion(
            totalEthAmountInPool
        );

        uint256 maxEthAmountToAdjustIn = maxAmountToOwn -
            strategyEthAmountInPool;
        uint256 ethAmountToAdjustIn = maxEthAmountToAdjustIn;
        uint256 currentBalance = address(zapper).balance;
        if (currentBalance < maxEthAmountToAdjustIn) {
            ethAmountToAdjustIn = currentBalance;
        }
        uint256 minAmountOfLPToGet = curvePool.calc_token_amount(
            [ethAmountToAdjustIn, 0],
            true
        );
        return (minAmountOfLPToGet, ethAmountToAdjustIn);
    }

    // todo: preview doHardWork for min ethamount and min lp amount
    function previewDoHardWork()
        external
        view
        returns (uint256 _minOutputEth, uint256 _minOutputLP)
    {
        revert("not implemented");
    }

    // constant setters

    function setMinEthBalanceProportion(uint256 _minBalanceProportion)
        external
        onlyAdmin
    /*add access control */
    {
        minEthBalanceProportion = _minBalanceProportion;
    }

    function setMaxEthOwnershipProportion(uint256 _maxOwnershipProportion)
        external
        onlyAdmin
    /*add access control */
    {
        maxEthOwnershipProportion = _maxOwnershipProportion;
    }

    function setMinIdleEthForAction(uint256 _minIdleEthForAction)
        external
        onlyAdmin
    /*add access control */
    {
        minIdleEthForAction = _minIdleEthForAction;
    }

    function setMinEthAmountInPool(uint256 _minAmountInPool)
        external
        onlyAdmin
    /*add access control */
    {
        minEthAmountInPool = _minAmountInPool;
    }

    function setPullOutMinEthAmountModifier(uint256 _pullOutMinModifier)
        external
        onlyAdmin
    /*add access control */
    {
        pullOutMinEthAmountModifier = _pullOutMinModifier;
    }

    function setAdjustOutEthProportion(uint256 _adjustOutProportion)
        external
        onlyAdmin
    /*add access control */
    {
        adjustOutEthProportion = _adjustOutProportion;
    }

    function setAdjustInEthProportion(uint256 _adjustInProportion)
        external
        onlyAdmin
    /*add access control */
    {
        adjustInEthProportion = _adjustInProportion;
    }

    function setMinAmountOfEthToAdjustIn(uint256 _minAmountOfEthToAdjustIn)
        external
        onlyAdmin
    /*add access control */
    {
        minAmountOfEthToAdjustIn = _minAmountOfEthToAdjustIn;
    }

    function setMinCoolDownForAdjustOut(uint256 _minCoolDownForAdjustOut)
        external
        onlyAdmin
    /*add access control */
    {
        minCoolDownForAdjustOut = _minCoolDownForAdjustOut;
    }

    function setTreasuryAddress(address _treasuryAddress)
        external
        onlyAdmin
    /*add access control */
    {
        treasuryAddress = _treasuryAddress;
    }

    function setMinEthAmountForDoHardWork(uint256 _minEthAmountForDoHardWork)
        external
        onlyAdmin
    /*add access control */
    {
        minEthAmountForDoHardWork = _minEthAmountForDoHardWork;
    }

    function setZapperAddress(address _zapperAddress)
        external
        onlyAdmin
    /*add access control */
    {
        zapper = IGuardedConvexStrategy(payable(_zapperAddress));
    }

    function setMinUnderlyingValue(uint256 _minUnderlyingValue)
        external
        onlyAdmin
    /*add access control */
    {
        minUnderlyingValue = _minUnderlyingValue;
    }

    // getters

    function getMinEthBalanceProportion() external view returns (uint256) {
        return minEthBalanceProportion;
    }

    function getMaxEthOwnershipProportion() external view returns (uint256) {
        return maxEthOwnershipProportion;
    }

    function getMinIdleEthForAction() external view returns (uint256) {
        return minIdleEthForAction;
    }

    function getMinEthAmountInPool() external view returns (uint256) {
        return minEthAmountInPool;
    }

    function getPullOutMinEthAmountModifier() external view returns (uint256) {
        return pullOutMinEthAmountModifier;
    }

    function getAdjustOutEthProportion() external view returns (uint256) {
        return adjustOutEthProportion;
    }

    function getAdjustInEthProportion() external view returns (uint256) {
        return adjustInEthProportion;
    }

    function getMinAmountOfEthToAdjustIn() external view returns (uint256) {
        return minAmountOfEthToAdjustIn;
    }

    function getMinCoolDownForAdjustOut() external view returns (uint256) {
        return minCoolDownForAdjustOut;
    }

    function getTreasuryAddress() external view returns (address) {
        return treasuryAddress;
    }

    function getMinEthAmountForDoHardWork() external view returns (uint256) {
        return minEthAmountForDoHardWork;
    }

    function getStrategyZapper() external view returns (address) {
        return address(zapper);
    }

    function getMinUnderlyingValue() external view returns (uint256) {
        return minUnderlyingValue;
    }

    // sunset functions

    function sunset() external onlyAdmin /**add access control */
    {
        // disables deposits
        _pause();
    }

    function unSunset() external onlyAdmin /**add access control */
    {
        // enables deposits
        _unpause();
    }

    // noone should be able to call the ERC4626 methods
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override onlyAdminOrZapperOrExec returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    function deposit(uint256 assets, address receiver)
        public
        virtual
        override
        onlyAdminOrZapperOrExec
        returns (uint256)
    {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver)
        public
        virtual
        override
        returns (uint256)
    {
        revert("mint method not allowed");
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        revert("withdraw method not allowed");
    }
}