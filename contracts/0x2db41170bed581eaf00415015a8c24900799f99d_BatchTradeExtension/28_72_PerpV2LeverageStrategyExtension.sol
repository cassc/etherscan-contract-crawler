/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { IAccountBalance } from "@setprotocol/set-protocol-v2/contracts/interfaces/external/perp-v2/IAccountBalance.sol";
import { IPerpV2LeverageModuleV2 } from "@setprotocol/set-protocol-v2/contracts/interfaces/IPerpV2LeverageModuleV2.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { IVault } from "@setprotocol/set-protocol-v2/contracts/interfaces/external/perp-v2/IVault.sol";
import { PreciseUnitMath } from "@setprotocol/set-protocol-v2/contracts/lib/PreciseUnitMath.sol";
import { StringArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/StringArrayUtils.sol";

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { IPriceFeed } from "../interfaces/IPriceFeed.sol";


/**
 * @title PerpV2LeverageStrategyExtension
 * @author Set Protocol
 *
 * Smart contract that enables trustless leverage tokens with USDC as collateral. This extension is paired with the PerpV2LeverageModule from
 * Set protocol where module interactions are invoked via the IBaseManager contract. Any leveraged token can be constructed as long as the
 * market  is listed on Perp V2. This extension contract also allows the operator to set an ETH reward to incentivize keepers calling the
 * rebalance function at different leverage thresholds.
 */
contract PerpV2LeverageStrategyExtension is BaseExtension {
    using Address for address;
    using PreciseUnitMath for uint256;
    using PreciseUnitMath for int256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using StringArrayUtils for string[];

    /* ============ Enums ============ */

    enum ShouldRebalance {
        NONE,                   // Indicates no rebalance action can be taken
        REBALANCE,              // Indicates rebalance() function can be successfully called
        ITERATE_REBALANCE,      // Indicates iterateRebalance() function can be successfully called
        RIPCORD                 // Indicates ripcord() function can be successfully called
    }

    /* ============ Structs ============ */

    struct ActionInfo {
        int256 baseBalance;                                 // Balance of virtual base asset from Perp in precise units (10e18). E.g. vWBTC = 10e18
        int256 quoteBalance;                                // Balance of virtual quote asset from Perp in precise units (10e18). E.g. vUSD = 10e18
        IPerpV2LeverageModuleV2.AccountInfo accountInfo;      // Info on perpetual account including, collateral balance, owedRealizedPnl and pendingFunding
        int256 basePositionValue;                           // Valuation in USD adjusted for decimals in precise units (10e18)
        int256 quoteValue;                                  // Valuation in USD adjusted for decimals in precise units (10e18)
        int256 basePrice;                                   // Price of base asset in precise units (10e18) from PerpV2 Oracle
        int256 quotePrice;                                  // Price of quote asset in precise units (10e18) from PerpV2 Oracle
        uint256 setTotalSupply;                             // Total supply of SetToken
    }

    struct LeverageInfo {
        ActionInfo action;
        int256 currentLeverageRatio;                    // Current leverage ratio of Set. For short tokens, this will be negative
        uint256 slippageTolerance;                      // Allowable percent trade slippage in preciseUnits (1% = 10^16)
        uint256 twapMaxTradeSize;                       // Max trade size in base asset units allowed for rebalance action
    }

    struct ContractSettings {
        ISetToken setToken;                             // Instance of leverage token
        IPerpV2LeverageModuleV2 perpV2LeverageModule;     // Instance of Perp V2 leverage module
        IAccountBalance perpV2AccountBalance;           // Instance of Perp V2 AccountBalance contract used to fetch position balances
        IPriceFeed baseUSDPriceOracle;                  // PerpV2 oracle that returns TWAP price for base asset in USD. IPriceFeed is a PerpV2 specific interface
                                                        // to interact with differnt oracle providers, e.g. Band Protocol and Chainlink, for different assets
                                                        // listed on PerpV2
        uint256 twapInterval;                           // TWAP interval to be used to fetch base asset price in seconds
                                                        // PerpV2 uses a 15 min TWAP interval, i.e. twapInterval = 900
        uint256 basePriceDecimalAdjustment;             // Decimal adjustment for the price returned by the PerpV2 oracle for the base asset.
                                                        // Equal to vBaseAsset.decimals() - baseUSDPriceOracle.decimals()
        address virtualBaseAddress;                     // Address of virtual base asset (e.g. vETH, vWBTC etc)
        address virtualQuoteAddress;                    // Address of virtual USDC quote asset. The Perp V2 system uses USDC for all markets
    }

    struct MethodologySettings {
        int256 targetLeverageRatio;                     // Long term target ratio in precise units (10e18). For short tokens target ratio is negative.
                                                        // E.g. 2e18 for ETH 2x and -2e18 for ETH -2x.
        int256 minLeverageRatio;                        // For both long and short tokens, if magnitude of current leverage is lower, rebalance target is
                                                        // this ratio. In precise units (10e18). E.g. 1.7e17 for ETH 2x and -1.7e17 for ETH -1x.
        int256 maxLeverageRatio;                        // For both long and short tokens, if magniutde of current leverage is higher, rebalance target is
                                                        // this ratio. In precise units (10e18). E.g. 1.7e17 for ETH 2x and -1.7e17 for ETH -1x.
        uint256 recenteringSpeed;                       // % at which to rebalance back to target leverage in precise units (10e18). Always a positive number
        uint256 rebalanceInterval;                      // Period of time required since last rebalance timestamp in seconds
    }

    struct ExecutionSettings {
        uint256 slippageTolerance;                       // % in precise units to price min token receive amount from trade quantities
        uint256 twapCooldownPeriod;                      // Cooldown period required since last trade timestamp in seconds
    }

    struct ExchangeSettings {
        uint256 twapMaxTradeSize;                        // Max trade size in base assset base units. Always a positive number
        uint256 incentivizedTwapMaxTradeSize;            // Max trade size for incentivized rebalances in base asset units. Always a positive number
    }

    struct IncentiveSettings {
        uint256 etherReward;                             // ETH reward for incentivized rebalances
        int256 incentivizedLeverageRatio;                // Leverage ratio for incentivized rebalances. For long tokens, this is a positive number higher than
                                                         // maxLeverageRatio. For short tokens, this is a negative number lower than maxLeverageRatio
        uint256 incentivizedSlippageTolerance;           // Slippage tolerance percentage for incentivized rebalances
        uint256 incentivizedTwapCooldownPeriod;          // TWAP cooldown in seconds for incentivized rebalances
    }

    /* ============ Events ============ */

    event Engaged(int256 _currentLeverageRatio, int256 _newLeverageRatio, int256 _chunkRebalanceNotional, int256 _totalRebalanceNotional);
    event Rebalanced(
        int256 _currentLeverageRatio,
        int256 _newLeverageRatio,
        int256 _chunkRebalanceNotional,
        int256 _totalRebalanceNotional
    );
    event RebalanceIterated(
        int256 _currentLeverageRatio,
        int256 _newTwapLeverageRatio,
        int256 _chunkRebalanceNotional,
        int256 _totalRebalanceNotional
    );
    event RipcordCalled(
        int256 _currentLeverageRatio,
        int256 _newLeverageRatio,
        int256 _rebalanceNotional,
        uint256 _etherIncentive
    );
    event Disengaged(int256 _currentLeverageRatio, int256 _newLeverageRatio, int256 _chunkRebalanceNotional, int256 _totalRebalanceNotional);
    event MethodologySettingsUpdated(
        int256 _targetLeverageRatio,
        int256 _minLeverageRatio,
        int256 _maxLeverageRatio,
        uint256 _recenteringSpeed,
        uint256 _rebalanceInterval
    );
    event ExecutionSettingsUpdated(
        uint256 _twapCooldownPeriod,
        uint256 _slippageTolerance
    );
    event ExchangeSettingsUpdated(
        uint256 _twapMaxTradeSize,
        uint256 _incentivizedTwapMaxTradeSize
    );
    event IncentiveSettingsUpdated(
        uint256 _etherReward,
        int256 _incentivizedLeverageRatio,
        uint256 _incentivizedSlippageTolerance,
        uint256 _incentivizedTwapCooldownPeriod
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if rebalance is currently in TWAP
     */
    modifier noRebalanceInProgress() {
        require(twapLeverageRatio == 0, "Rebalance is currently in progress");
        _;
    }

    /* ============ State Variables ============ */

    ContractSettings internal strategy;                     // Struct of contracts used in the strategy (SetToken, price oracles, leverage module etc)
    MethodologySettings internal methodology;               // Struct containing methodology parameters
    ExecutionSettings internal execution;                   // Struct containing execution parameters
    ExchangeSettings internal exchange;                     // Struct containing exchange settings
    IncentiveSettings internal incentive;                   // Struct containing incentive parameters for ripcord
    int256 public twapLeverageRatio;                        // Stored leverage ratio to keep track of target between TWAP rebalances
    uint256 public lastTradeTimestamp;                      // Last rebalance timestamp. Current timestamp must be greater than this variable + rebalance interval to rebalance

    /* ============ Constructor ============ */

    /**
     * Instantiate addresses, methodology parameters, execution parameters, exchange parameters and incentive parameters.
     *
     * @param _manager                  Address of IBaseManager contract
     * @param _strategy                 Struct of contract addresses
     * @param _methodology              Struct containing methodology parameters
     * @param _execution                Struct containing execution parameters
     * @param _incentive                Struct containing incentive parameters for ripcord
     * @param _exchange                 Struct containing exchange parameters
     */
    constructor(
        IBaseManager _manager,
        ContractSettings memory _strategy,
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive,
        ExchangeSettings memory _exchange
    )
        public
        BaseExtension(_manager)
    {
        strategy = _strategy;
        methodology = _methodology;
        execution = _execution;
        incentive = _incentive;
        exchange = _exchange;

        _validateExchangeSettings(_exchange);
        _validateNonExchangeSettings(methodology, execution, incentive);
    }

    /* ============ External Functions ============ */

    /**
     * OPERATOR ONLY: Engage to target leverage ratio for the first time. SetToken will open a new base token position on PerpV2. Under the hood, perp would
     * mint virtual quote assets (vUSDC) for SetToken and swap them for base token. If target leverage ratio is above max trade size, then TWAP is kicked off.
     * To complete engage if TWAP, any valid caller must call iterateRebalance until target is met.
     * Note: Engage should be called after collateral has been deposited to PerpV2 using `deposit()`.
     */
    function engage() external onlyOperator {
        LeverageInfo memory leverageInfo = _getAndValidateEngageInfo();

        // Calculate total rebalance units and kick off TWAP if above max trade size
        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateEngageRebalanceSize(leverageInfo, methodology.targetLeverageRatio);

        _trade(leverageInfo, chunkRebalanceNotional);

        _updateRebalanceState(
            chunkRebalanceNotional,
            totalRebalanceNotional,
            methodology.targetLeverageRatio
        );

        emit Engaged(
            leverageInfo.currentLeverageRatio,
            methodology.targetLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Rebalance product. If |min leverage ratio| < |current leverage ratio| < |max leverage ratio|, then rebalance
     * can only be called once the rebalance interval has elapsed since last timestamp. If outside the max and min but below incentivized leverage ratio,
     * rebalance can be called anytime to bring leverage ratio back to the max or min bounds. The methodology will determine whether to delever or lever.
     *
     * Note: If the calculated current leverage ratio is above the incentivized leverage ratio or in TWAP then rebalance cannot be called. Instead, you must call
     * ripcord() which is incentivized with a reward in Ether or iterateRebalance().
     */
    function rebalance() external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateNormalRebalance(leverageInfo, methodology.rebalanceInterval, lastTradeTimestamp);
        _validateNonTWAP();

        int256 newLeverageRatio = _calculateNewLeverageRatio(leverageInfo.currentLeverageRatio);

        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _handleRebalance(leverageInfo, newLeverageRatio);

        _updateRebalanceState(chunkRebalanceNotional, totalRebalanceNotional, newLeverageRatio);

        emit Rebalanced(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Iterate a rebalance when in TWAP. TWAP cooldown period must have elapsed. If price moves advantageously, then
     * exit without rebalancing and clear TWAP state. This function can only be called when |current leverage ratio| < |incentivized leverage ratio|
     * and in TWAP state.
     */
    function iterateRebalance() external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateNormalRebalance(leverageInfo, execution.twapCooldownPeriod, lastTradeTimestamp);
        _validateTWAP();

        int256 chunkRebalanceNotional;
        int256 totalRebalanceNotional;
        if (!_isAdvantageousTWAP(leverageInfo.currentLeverageRatio)) {
            (chunkRebalanceNotional, totalRebalanceNotional) = _handleRebalance(leverageInfo, twapLeverageRatio);
        }

        // If not advantageous, then rebalance is skipped and chunk and total rebalance notional are both 0, which means TWAP state is cleared
        _updateIterateState(chunkRebalanceNotional, totalRebalanceNotional);

        emit RebalanceIterated(
            leverageInfo.currentLeverageRatio,
            twapLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA: In case |current leverage ratio| > |incentivized leverage ratio|, the ripcord function can be called by anyone to return leverage ratio
     * back to the max leverage ratio. This function typically would only be called during times of high downside/upside volatility and / or normal keeper malfunctions. The
     * caller of ripcord() will receive a reward in Ether. The ripcord function uses it's own TWAP cooldown period, slippage tolerance and TWAP max trade size which are
     * typically looser than in regular rebalances. If chunk rebalance size is above max incentivized trade size, then caller must continue to call this function to pull
     * the leverage ratio under the incentivized leverage ratio. Incentivized TWAP cooldown period must have elapsed. The function iterateRebalance will not work.
     */
    function ripcord() external onlyEOA {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            incentive.incentivizedSlippageTolerance,
            exchange.incentivizedTwapMaxTradeSize
        );

        _validateRipcord(leverageInfo, lastTradeTimestamp);

        ( int256 chunkRebalanceNotional, ) = _calculateChunkRebalanceNotional(leverageInfo, methodology.maxLeverageRatio);

        _trade(leverageInfo, chunkRebalanceNotional);

        _updateRipcordState();

        uint256 etherTransferred = _transferEtherRewardToCaller(incentive.etherReward);

        emit RipcordCalled(
            leverageInfo.currentLeverageRatio,
            methodology.maxLeverageRatio,
            chunkRebalanceNotional,
            etherTransferred
        );
    }

    /**
     * OPERATOR ONLY: Close open baseToken position on Perpetual Protocol. TWAP cooldown period must have elapsed. This can be used for upgrading or shutting down the strategy. SetToken will sell all
     * virtual base token positions into virtual USDC. If the chunk rebalance size is less than the total notional size, then this function will trade out of base
     * token position in one go. If chunk rebalance size is above max trade size, then operator must continue to call this function to completely unwind position.
     * The function iterateRebalance will not work.
     *
     * Note: If rebalancing is open to anyone disengage TWAP can be counter traded by a griefing party calling rebalance. Set anyoneCallable to false before disengage to prevent such attacks.
     */
    function disengage() external onlyOperator {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateDisengage(lastTradeTimestamp);

        // Reduce leverage to 0
        int256 newLeverageRatio = 0;

        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio);

        _trade(leverageInfo, chunkRebalanceNotional);

        _updateDisengageState();

        emit Disengaged(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * OEPRATOR ONLY: Deposits specified units of current USDC tokens not already being used as collateral into Perpetual Protocol.
     *
     * @param  _collateralUnits     Collateral to deposit in position units
     */
    function deposit(uint256 _collateralUnits) external onlyOperator {
        bytes memory depositCalldata = abi.encodeWithSelector(
            IPerpV2LeverageModuleV2.deposit.selector,
            address(strategy.setToken),
            _collateralUnits
        );

        invokeManager(address(strategy.perpV2LeverageModule), depositCalldata);
    }

    /**
     * OPERATOR ONLY: Withdraws specified units of USDC tokens from Perpetual Protocol and adds it as default position on the SetToken.
     *
     * @param  _collateralUnits     Collateral to withdraw in position units
     */
    function withdraw(uint256 _collateralUnits) external onlyOperator {
        bytes memory withdrawCalldata = abi.encodeWithSelector(
            IPerpV2LeverageModuleV2.withdraw.selector,
            address(strategy.setToken),
            _collateralUnits
        );

        invokeManager(address(strategy.perpV2LeverageModule), withdrawCalldata);
    }

    /**
     * OPERATOR ONLY: Set methodology settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newMethodologySettings          Struct containing methodology parameters
     */
    function setMethodologySettings(MethodologySettings memory _newMethodologySettings) external onlyOperator noRebalanceInProgress {
        methodology = _newMethodologySettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit MethodologySettingsUpdated(
            methodology.targetLeverageRatio,
            methodology.minLeverageRatio,
            methodology.maxLeverageRatio,
            methodology.recenteringSpeed,
            methodology.rebalanceInterval
        );
    }

    /**
     * OPERATOR ONLY: Set execution settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newExecutionSettings          Struct containing execution parameters
     */
    function setExecutionSettings(ExecutionSettings memory _newExecutionSettings) external onlyOperator noRebalanceInProgress {
        execution = _newExecutionSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit ExecutionSettingsUpdated(
            execution.twapCooldownPeriod,
            execution.slippageTolerance
        );
    }

    /**
     * OPERATOR ONLY: Set incentive settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newIncentiveSettings          Struct containing incentive parameters
     */
    function setIncentiveSettings(IncentiveSettings memory _newIncentiveSettings) external onlyOperator noRebalanceInProgress {
        incentive = _newIncentiveSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit IncentiveSettingsUpdated(
            incentive.etherReward,
            incentive.incentivizedLeverageRatio,
            incentive.incentivizedSlippageTolerance,
            incentive.incentivizedTwapCooldownPeriod
        );
    }

    /**
     * OPERATOR ONLY: Set exchange settings and check new settings are valid.Updating exchange settings during rebalances is allowed, as it is not possible
     * to enter an unexpected state while doing so. Note: Need to pass in existing parameters if only changing a few settings.
     *
     * @param _newExchangeSettings     Struct containing exchange parameters
     */
    function setExchangeSettings(ExchangeSettings memory _newExchangeSettings)
        external
        onlyOperator
    {
        exchange = _newExchangeSettings;
        _validateExchangeSettings(_newExchangeSettings);

        exchange.twapMaxTradeSize = _newExchangeSettings.twapMaxTradeSize;
        exchange.incentivizedTwapMaxTradeSize = _newExchangeSettings.incentivizedTwapMaxTradeSize;

        emit ExchangeSettingsUpdated(
            _newExchangeSettings.twapMaxTradeSize,
            _newExchangeSettings.incentivizedTwapMaxTradeSize
        );
    }

    /**
     * OPERATOR ONLY: Withdraw entire balance of ETH in this contract to operator. Rebalance must not be in progress
     */
    function withdrawEtherBalance() external onlyOperator noRebalanceInProgress {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}

    /* ============ External Getter Functions ============ */

    /**
     * Get current leverage ratio. Current leverage ratio is defined as the sum of USD values of all SetToken open positions on Perp V2 divided by its account value on
     * PerpV2. Prices for base and quote asset are retrieved from the Chainlink Price Oracle.
     *
     * return currentLeverageRatio         Current leverage ratio in precise units (10e18)
     */
    function getCurrentLeverageRatio() public view returns(int256) {
        ActionInfo memory currentLeverageInfo = _createActionInfo();

        return _calculateCurrentLeverageRatio(currentLeverageInfo);
    }

    /**
     * Calculates the chunk rebalance size. This can be used by external contracts and keeper bots to track rebalances and fetch assets to be bought and sold.
     * Note: This function does not take into account timestamps, so it may return a nonzero value even when shouldRebalance would return ShouldRebalance.NONE
     * (since minimum delays have not elapsed).
     *
     * @return size             Total notional chunk size. Measured in the asset that would be sold.
     * @return sellAsset        Asset that would be sold during a rebalance
     * @return buyAsset         Asset that would be purchased during a rebalance
     */
    function getChunkRebalanceNotional()
        external
        view
        returns(int256 size, address sellAsset, address buyAsset)
    {

        int256 newLeverageRatio;
        int256 currentLeverageRatio = getCurrentLeverageRatio();
        bool isRipcord = false;

        // if over incentivized leverage ratio, always ripcord
        if (currentLeverageRatio.abs() > incentive.incentivizedLeverageRatio.abs()) {
            newLeverageRatio = methodology.maxLeverageRatio;
            isRipcord = true;
        // if we are in an ongoing twap, use the cached twapLeverageRatio as our target leverage
        } else if (twapLeverageRatio != 0) {
            newLeverageRatio = twapLeverageRatio;
        // if all else is false, then we would just use the normal rebalance new leverage ratio calculation
        } else {
            newLeverageRatio = _calculateNewLeverageRatio(currentLeverageRatio);
        }

        ActionInfo memory actionInfo = _createActionInfo();

        LeverageInfo memory leverageInfo = LeverageInfo({
            action: actionInfo,
            currentLeverageRatio: currentLeverageRatio,
            slippageTolerance: isRipcord ? incentive.incentivizedSlippageTolerance : execution.slippageTolerance,
            twapMaxTradeSize: isRipcord ?
                exchange.incentivizedTwapMaxTradeSize :
                exchange.twapMaxTradeSize
        });

        (size, ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio);

        bool increaseLeverage = newLeverageRatio.abs() > currentLeverageRatio.abs();

        /*
        ------------------------------------------------------------------------------
        |   New LR             |  increaseLeverage |    sellAsset   |    buyAsset    |
        ------------------------------------------------------------------------------
        |   = 0 (not possible) |        x          |        x       |      x         |
        |   > 0  (long)        |       true        |      quote     |    base        |
        |   > 0  (long)        |       false       |      base      |    quote       |
        |   < 0  (short)       |       true        |      base      |    quote       |
        |   < 0  (short)       |       false       |      quote     |    base        |
        ------------------------------------------------------------------------------
        */

        if (newLeverageRatio > 0) {
            sellAsset = increaseLeverage ? strategy.virtualQuoteAddress : strategy.virtualBaseAddress;
            buyAsset = increaseLeverage ? strategy.virtualBaseAddress : strategy.virtualQuoteAddress;
        } else {
            sellAsset = increaseLeverage ? strategy.virtualBaseAddress : strategy.virtualQuoteAddress;
            buyAsset = increaseLeverage ? strategy.virtualQuoteAddress : strategy.virtualBaseAddress;
        }
    }

    /**
     * Get current Ether incentive for when current leverage ratio exceeds incentivized leverage ratio and ripcord can be called. If ETH balance on the contract is
     * below the etherReward, then return the balance of ETH instead.
     *
     * return etherReward               Quantity of ETH reward in base units (10e18)
     */
    function getCurrentEtherIncentive() external view returns(uint256) {
        int256 currentLeverageRatio = getCurrentLeverageRatio();

        if (currentLeverageRatio.abs() >= incentive.incentivizedLeverageRatio.abs()) {
            // If ETH reward is below the balance on this contract, then return ETH balance on contract instead
            return incentive.etherReward < address(this).balance ? incentive.etherReward : address(this).balance;
        } else {
            return 0;
        }
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord. Returns an enum with 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance()
     * 3 = call ripcord()
     *
     * @return ShouldRebalance      Enum representing whether should rebalance
     */
    function shouldRebalance() external view returns(ShouldRebalance) {
        int256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, methodology.minLeverageRatio, methodology.maxLeverageRatio);
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord with custom max and min bounds specified by caller. This function simplifies the
     * logic for off-chain keeper bots to determine what threshold to call rebalance when leverage exceeds max or drops below min. Returns an enum with
     * 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance(), 3 = call ripcord()
     *
     * @param _customMinLeverageRatio          Min leverage ratio passed in by caller
     * @param _customMaxLeverageRatio          Max leverage ratio passed in by caller
     *
     * @return ShouldRebalance      Enum representing whether should rebalance
     */
    function shouldRebalanceWithBounds(
        int256 _customMinLeverageRatio,
        int256 _customMaxLeverageRatio
    )
        external
        view
        returns(ShouldRebalance)
    {
        require (
            _customMinLeverageRatio.abs() <= methodology.minLeverageRatio.abs()
            && _customMaxLeverageRatio.abs() >= methodology.maxLeverageRatio.abs(),
            "Custom bounds must be valid"
        );

        int256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, _customMinLeverageRatio, _customMaxLeverageRatio);
    }

    /**
     * Explicit getter functions for parameter structs are defined as workaround to issues fetching structs that have dynamic types.
     */
    function getStrategy() external view returns (ContractSettings memory) { return strategy; }
    function getMethodology() external view returns (MethodologySettings memory) { return methodology; }
    function getExecution() external view returns (ExecutionSettings memory) { return execution; }
    function getIncentive() external view returns (IncentiveSettings memory) { return incentive; }
    function getExchangeSettings() external view returns (ExchangeSettings memory) { return exchange; }

    /* ============ Internal Functions ============ */

    /**
     * Calculate base rebalance units, opposite bound units and invoke trade on PerpV2LeverageModule.
     */
    function _trade(
        LeverageInfo memory _leverageInfo,
        int256 _chunkRebalanceNotional
    )
        internal
    {
        int256 baseRebalanceUnits = _chunkRebalanceNotional.preciseDiv(_leverageInfo.action.setTotalSupply.toInt256());

        uint256 oppositeBoundUnits = _calculateOppositeBoundUnits(baseRebalanceUnits, _leverageInfo.action, _leverageInfo.slippageTolerance);

        bytes memory tradeCallData = abi.encodeWithSelector(
            IPerpV2LeverageModuleV2.trade.selector,
            address(strategy.setToken),
            strategy.virtualBaseAddress,
            baseRebalanceUnits,
            oppositeBoundUnits
        );

        invokeManager(address(strategy.perpV2LeverageModule), tradeCallData);
    }

    /**
     * Calculates chunk rebalance notional and calls trade to open a position. Used in the rebalance() and iterateRebalance() functions
     *
     * return uint256           Calculated notional to trade
     * return uint256           Total notional to rebalance over TWAP
     */
    function _handleRebalance(LeverageInfo memory _leverageInfo, int256 _newLeverageRatio) internal returns(int256, int256) {
        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(_leverageInfo, _newLeverageRatio);

        _trade(_leverageInfo, chunkRebalanceNotional);

        return (chunkRebalanceNotional, totalRebalanceNotional);
    }

    /**
     * Validate the Set is not already engaged. Create the leverage info struct to be used in engage.
     */
    function _getAndValidateEngageInfo() internal view returns(LeverageInfo memory) {
        ActionInfo memory engageInfo = _createActionInfo();

        require(engageInfo.accountInfo.collateralBalance > 0, "Collateral balance must be > 0");

        // Assert base position unit is zero. Asserting base position unit instead of base balance allows us to neglect small dust amounts.
        require(engageInfo.baseBalance.preciseDiv(strategy.setToken.totalSupply().toInt256()) == 0, "Base position must NOT exist");

        return LeverageInfo({
            action: engageInfo,
            currentLeverageRatio: 0, // 0 position leverage
            slippageTolerance: execution.slippageTolerance,
            twapMaxTradeSize: exchange.twapMaxTradeSize
        });
    }

    /**
     * Create the leverage info struct to be used in internal functions.
     *
     * return LeverageInfo                Struct containing ActionInfo and other data
     */
    function _getAndValidateLeveragedInfo(uint256 _slippageTolerance, uint256 _maxTradeSize) internal view returns(LeverageInfo memory) {
        ActionInfo memory actionInfo = _createActionInfo();

        require(actionInfo.setTotalSupply > 0, "SetToken must have > 0 supply");

        // Get current leverage ratio
        int256 currentLeverageRatio = _calculateCurrentLeverageRatio(actionInfo);

        // This function is called during rebalance, iterateRebalance, ripcord and disengage.
        // Assert currentLeverageRatio is 0 as the set should be engaged before this function is called.
        require(currentLeverageRatio.abs() > 0, "Current leverage ratio must NOT be 0");

        return LeverageInfo({
            action: actionInfo,
            currentLeverageRatio: currentLeverageRatio,
            slippageTolerance: _slippageTolerance,
            twapMaxTradeSize: _maxTradeSize
        });
    }

    /**
     * Create the action info struct to be used in internal functions
     *
     * return ActionInfo                Struct containing data used by internal lever and delever functions
     */
    function _createActionInfo() internal view returns(ActionInfo memory) {
        ActionInfo memory rebalanceInfo;

        // Fetch base token prices from PerpV2 oracles and adjust them to 18 decimal places.
        int256 rawBasePrice = strategy.baseUSDPriceOracle.getPrice(strategy.twapInterval).toInt256();
        rebalanceInfo.basePrice = rawBasePrice.mul((10 ** strategy.basePriceDecimalAdjustment).toInt256());

        // vUSD price is fixed to 1$
        rebalanceInfo.quotePrice = PreciseUnitMath.preciseUnit().toInt256();

        // Note: getTakerPositionSize returns zero if base balance is less than 10 wei
        rebalanceInfo.baseBalance = strategy.perpV2AccountBalance.getTakerPositionSize(address(strategy.setToken), strategy.virtualBaseAddress);

        // Note: Fetching quote balance associated with a single position and not the net quote balance
        rebalanceInfo.quoteBalance = strategy.perpV2AccountBalance.getTakerOpenNotional(address(strategy.setToken), strategy.virtualBaseAddress);

        rebalanceInfo.accountInfo = strategy.perpV2LeverageModule.getAccountInfo(strategy.setToken);

        // In Perp v2, all virtual tokens have 18 decimals, therefore we do not need to make further adjustments to determine base valuation.
        rebalanceInfo.basePositionValue = rebalanceInfo.basePrice.preciseMul(rebalanceInfo.baseBalance);
        rebalanceInfo.quoteValue = rebalanceInfo.quoteBalance;

        rebalanceInfo.setTotalSupply = strategy.setToken.totalSupply();

        return rebalanceInfo;
    }

    /**
     * Validate non-exchange settings in constructor and setters when updating.
     */
    function _validateNonExchangeSettings(
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive
    )
        internal
        pure
    {
        uint256 minLeverageRatioAbs = _methodology.minLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = _methodology.targetLeverageRatio.abs();
        uint256 maxLeverageRatioAbs = _methodology.maxLeverageRatio.abs();
        uint256 incentivizedLeverageRatioAbs = _incentive.incentivizedLeverageRatio.abs();

        require (
            minLeverageRatioAbs <= targetLeverageRatioAbs && minLeverageRatioAbs > 0,
            "Must be valid min leverage"
        );
        require (
            maxLeverageRatioAbs >= targetLeverageRatioAbs,
            "Must be valid max leverage"
        );
        require (
            _methodology.recenteringSpeed <= PreciseUnitMath.preciseUnit() && _methodology.recenteringSpeed > 0,
            "Must be valid recentering speed"
        );
        require (
            _execution.slippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Slippage tolerance must be <100%"
        );
        require (
            _incentive.incentivizedSlippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Incentivized slippage tolerance must be <100%"
        );
        require (
            incentivizedLeverageRatioAbs >= maxLeverageRatioAbs,
            "Incentivized leverage ratio must be > max leverage ratio"
        );
        require (
            _methodology.rebalanceInterval >= _execution.twapCooldownPeriod,
            "Rebalance interval must be greater than TWAP cooldown period"
        );
        require (
            _execution.twapCooldownPeriod >= _incentive.incentivizedTwapCooldownPeriod,
            "TWAP cooldown must be greater than incentivized TWAP cooldown"
        );
    }

    /**
     * Validate an ExchangeSettings struct settings.
     */
    function _validateExchangeSettings(ExchangeSettings memory _settings) internal pure {
        require(_settings.twapMaxTradeSize != 0, "Max TWAP trade size must not be 0");
        require(
            _settings.twapMaxTradeSize <= _settings.incentivizedTwapMaxTradeSize,
            "Max TWAP trade size must not be greater than incentivized max TWAP trade size"
        );
    }

    /**
     * Validate that current leverage is below incentivized leverage ratio and cooldown / rebalance period has elapsed or outsize max/min bounds. Used
     * in rebalance() and iterateRebalance() functions
     */
    function _validateNormalRebalance(LeverageInfo memory _leverageInfo, uint256 _coolDown, uint256 _lastTradeTimestamp) internal view {
        uint256 currentLeverageRatioAbs = _leverageInfo.currentLeverageRatio.abs();
        require(currentLeverageRatioAbs < incentive.incentivizedLeverageRatio.abs(), "Must be below incentivized leverage ratio");
        require(
            block.timestamp.sub(_lastTradeTimestamp) > _coolDown
            || currentLeverageRatioAbs > methodology.maxLeverageRatio.abs()
            || currentLeverageRatioAbs < methodology.minLeverageRatio.abs(),
            "Cooldown not elapsed or not valid leverage ratio"
        );
    }

    /**
     * Validate that current leverage is above incentivized leverage ratio and incentivized cooldown period has elapsed in ripcord()
     */
    function _validateRipcord(LeverageInfo memory _leverageInfo, uint256 _lastTradeTimestamp) internal view {
        require(_leverageInfo.currentLeverageRatio.abs() >= incentive.incentivizedLeverageRatio.abs(), "Must be above incentivized leverage ratio");
        // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
        require(_lastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp, "TWAP cooldown must have elapsed");
    }

    /**
     * Validate cooldown period has elapsed in disengage()
     */
    function _validateDisengage(uint256 _lastTradeTimestamp) internal view {
        require(_lastTradeTimestamp.add(execution.twapCooldownPeriod) < block.timestamp, "TWAP cooldown must have elapsed");
    }

    /**
     * Validate TWAP in the iterateRebalance() function
     */
    function _validateTWAP() internal view {
        require(twapLeverageRatio != 0, "Not in TWAP state");
    }

    /**
     * Validate not TWAP in the rebalance() function
     */
    function _validateNonTWAP() internal view {
        require(twapLeverageRatio == 0, "Must call iterate");
    }

    /**
     * Check if price has moved advantageously while in the midst of the TWAP rebalance. This means the current leverage ratio has moved over/under
     * the stored TWAP leverage ratio on lever/delever so there is no need to execute a rebalance. Used in iterateRebalance()
     *
     * return bool          True if price has moved advantageously, false otherwise
     */
    function _isAdvantageousTWAP(int256 _currentLeverageRatio) internal view returns (bool) {
        uint256 twapLeverageRatioAbs = twapLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = methodology.targetLeverageRatio.abs();
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();

        return (
            (twapLeverageRatioAbs < targetLeverageRatioAbs && currentLeverageRatioAbs >= twapLeverageRatioAbs)
            || (twapLeverageRatioAbs > targetLeverageRatioAbs && currentLeverageRatioAbs <= twapLeverageRatioAbs)
        );
    }

    /**
     * Calculate the current leverage ratio.
     *
     * return int256            Current leverage ratio
     */
    function _calculateCurrentLeverageRatio(ActionInfo memory _actionInfo) internal pure returns(int256) {
        /*
        Account Specs:
        -------------
        collateral:= balance of USDC in vault
        owedRealizedPnl:= realized PnL (in USD) that hasn't been settled
        pendingFundingPayment := funding payment (in USD) that hasn't been settled

        settling collateral (on withdraw)
            collateral <- collateral + owedRealizedPnL
            owedRealizedPnL <- 0

        settling funding (on every trade)
            owedRealizedPnL <- owedRealizedPnL + pendingFundingPayment
            pendingFundingPayment <- 0

        Note: Collateral balance, owedRealizedPnl and pendingFundingPayments belong to the entire account and
        NOT just the single market managed by this contract. So, while managing multiple positions across multiple
        markets via multiple separate extension contracts, `totalCollateralValue` should be counted only once.
        */
        int256 totalCollateralValue = _actionInfo.accountInfo.collateralBalance
            .add(_actionInfo.accountInfo.owedRealizedPnl)
            .add(_actionInfo.accountInfo.pendingFundingPayments);

        // Note: Both basePositionValue and quoteValue are values that belong to the single market managed by this contract.
        int256 unrealizedPnl = _actionInfo.basePositionValue.add(_actionInfo.quoteValue);

        int256 accountValue = totalCollateralValue.add(unrealizedPnl);

        if (accountValue <= 0) {
            return 0;
        }

        // `accountValue` is always positive. Do not use absolute value of basePositionValue in the below equation,
        //  to keep the sign of CLR same as that of basePositionValue.
        return _actionInfo.basePositionValue.preciseDiv(accountValue);
    }

    /**
     * Calculate the new leverage ratio. The methodology reduces the size of each rebalance by weighting
     * the current leverage ratio against the target leverage ratio by the recentering speed percentage. The lower the recentering speed, the slower
     * the leverage token will move towards the target leverage each rebalance.
     *
     * return int256          New leverage ratio
     */
    function _calculateNewLeverageRatio(int256 _currentLeverageRatio) internal view returns(int256) {
        // Convert int256 variables to uint256 prior to passing through methodology
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = methodology.targetLeverageRatio.abs();
        uint256 maxLeverageRatioAbs = methodology.maxLeverageRatio.abs();
        uint256 minLeverageRatioAbs = methodology.minLeverageRatio.abs();

        // CLRt+1 = max(MINLR, min(MAXLR, CLRt * (1 - RS) + TLR * RS))
        // a: TLR * RS
        // b: (1- RS) * CLRt
        // c: (1- RS) * CLRt + TLR * RS
        // d: min(MAXLR, CLRt * (1 - RS) + TLR * RS)
        uint256 a = targetLeverageRatioAbs.preciseMul(methodology.recenteringSpeed);
        uint256 b = PreciseUnitMath.preciseUnit().sub(methodology.recenteringSpeed).preciseMul(currentLeverageRatioAbs);
        uint256 c = a.add(b);
        uint256 d = Math.min(c, maxLeverageRatioAbs);
        uint256 newLeverageRatio = Math.max(minLeverageRatioAbs, d);

        return _currentLeverageRatio > 0 ? newLeverageRatio.toInt256() : newLeverageRatio.toInt256().neg();
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in base asset units.
     *
     * return int256          Chunked rebalance notional in base asset units
     * return int256          Total rebalance notional in base asset units
     */
    function _calculateChunkRebalanceNotional(
        LeverageInfo memory _leverageInfo,
        int256 _newLeverageRatio
    )
        internal
        pure
        returns (int256, int256)
    {
        // Calculate difference between new and current leverage ratio
        int256 leverageRatioDifference = _newLeverageRatio.sub(_leverageInfo.currentLeverageRatio);

        int256 totalRebalanceNotional = leverageRatioDifference.preciseDiv(_leverageInfo.currentLeverageRatio).preciseMul(_leverageInfo.action.baseBalance);

        uint256 chunkRebalanceNotionalAbs = Math.min(totalRebalanceNotional.abs(), _leverageInfo.twapMaxTradeSize);
        return (
            // Return int256 chunkRebalanceNotional
            totalRebalanceNotional >= 0 ? chunkRebalanceNotionalAbs.toInt256() : chunkRebalanceNotionalAbs.toInt256().neg(),
            totalRebalanceNotional
        );
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in base asset units for engaging the SetToken. Used in engage().
     * Leverage ratio (for the base asset) is zero before engage. We open a new base asset position with size equals to (collateralBalance * targetLeverageRatio / baseAssetPrice)
     * to gain (targetLeverageRatio * collateralBalance) worth of exposure to the base asset.
     * Note: We can't use `_calculateChunkRebalanceNotional` function because CLR is 0 during engage and it would lead to a divison by zero error.
     *
     * return int256          Chunked rebalance notional in base asset units
     * return int256          Total rebalance notional in base asset units
     */
    function _calculateEngageRebalanceSize(
        LeverageInfo memory _leverageInfo,
        int256 _targetLeverageRatio
    )
        internal
        pure
        returns (int256, int256)
    {
        int256 totalRebalanceNotional = _leverageInfo.action.accountInfo.collateralBalance.preciseMul(_targetLeverageRatio).preciseDiv(_leverageInfo.action.basePrice);

        uint256 chunkRebalanceNotionalAbs = Math.min(totalRebalanceNotional.abs(), _leverageInfo.twapMaxTradeSize);

        return (
            // Return int256 chunkRebalanceNotional
            totalRebalanceNotional >= 0 ? chunkRebalanceNotionalAbs.toInt256() : chunkRebalanceNotionalAbs.toInt256().neg(),
            totalRebalanceNotional
        );
    }

    /**
     * Derive the quote token units for slippage tolerance. The units are calculated by the base token units multiplied by base asset price divided by quote asset price.
     * Output is measured to precise units (1e18).
     *
     * return int256           Position units to quote
     */
    function _calculateOppositeBoundUnits(int256 _baseRebalanceUnits, ActionInfo memory _actionInfo, uint256 _slippageTolerance) internal pure returns (uint256) {
        uint256 oppositeBoundUnits;
        if (_baseRebalanceUnits > 0) {
            oppositeBoundUnits = _baseRebalanceUnits
                .preciseMul(_actionInfo.basePrice)
                .preciseDiv(_actionInfo.quotePrice)
                .preciseMul(PreciseUnitMath.preciseUnit().add(_slippageTolerance).toInt256()).toUint256();
        } else {
            oppositeBoundUnits = _baseRebalanceUnits
                .neg()
                .preciseMul(_actionInfo.basePrice)
                .preciseDiv(_actionInfo.quotePrice)
                .preciseMul(PreciseUnitMath.preciseUnit().sub(_slippageTolerance).toInt256()).toUint256();
        }
        return oppositeBoundUnits;
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is less than total rebalance notional, store new leverage ratio to kick off TWAP. Used in
     * the engage() and rebalance() functions
     */
    function _updateRebalanceState(
        int256 _chunkRebalanceNotional,
        int256 _totalRebalanceNotional,
        int256 _newLeverageRatio
    )
        internal
    {
        _updateLastTradeTimestamp();

        if (_chunkRebalanceNotional.abs() < _totalRebalanceNotional.abs()) {
            twapLeverageRatio = _newLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is equal to the total rebalance notional, end TWAP by clearing state. This function is used
     * in iterateRebalance()
     */
    function _updateIterateState(int256 _chunkRebalanceNotional, int256 _totalRebalanceNotional) internal {

        _updateLastTradeTimestamp();

        // If the chunk size is equal to the total notional meaning that rebalances are not chunked, then clear TWAP state.
        if (_chunkRebalanceNotional == _totalRebalanceNotional) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if currently in a TWAP, delete the TWAP state. Used in the ripcord() function.
     */
    function _updateRipcordState() internal {

        _updateLastTradeTimestamp();

        // If TWAP leverage ratio is stored, then clear state. This may happen if we are currently in a TWAP rebalance, and the leverage ratio moves above the
        // incentivized threshold for ripcord.
        if (twapLeverageRatio != 0) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp. Used in the disengage() function.
     */
    function _updateDisengageState() internal {
        _updateLastTradeTimestamp();
    }

    /**
     * Update lastTradeTimestamp value. This function updates the global timestamp so that the epoch rebalance can use the global timestamp.
     */
     function _updateLastTradeTimestamp() internal {
        lastTradeTimestamp = block.timestamp;
     }

    /**
     * Transfer ETH reward to caller of the ripcord function. If the ETH balance on this contract is less than required
     * incentive quantity, then transfer contract balance instead to prevent reverts.
     *
     * return uint256           Amount of ETH transferred to caller
     */
    function _transferEtherRewardToCaller(uint256 _etherReward) internal returns(uint256) {
        uint256 etherToTransfer = _etherReward < address(this).balance ? _etherReward : address(this).balance;

        msg.sender.transfer(etherToTransfer);

        return etherToTransfer;
    }

    /**
     * Internal function returning the ShouldRebalance enum used in shouldRebalance and shouldRebalanceWithBounds external getter functions
     *
     * return ShouldRebalance         Enum detailing whether to rebalance, iterateRebalance, ripcord or no action
     */
    function _shouldRebalance(
        int256 _currentLeverageRatio,
        int256 _minLeverageRatio,
        int256 _maxLeverageRatio
    )
        internal
        view
        returns(ShouldRebalance)
    {
        // If none of the below conditions are satisfied, then should not rebalance
        ShouldRebalance shouldRebalanceEnum = ShouldRebalance.NONE;

        // Get absolute value of current leverage ratio
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();

        // If above ripcord threshold, then check if incentivized cooldown period has elapsed
        if (currentLeverageRatioAbs >= incentive.incentivizedLeverageRatio.abs()) {
            if (lastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp) {
                shouldRebalanceEnum = ShouldRebalance.RIPCORD;
            }
        } else {
            // If TWAP, then check if the cooldown period has elapsed
            if (twapLeverageRatio != 0) {
                if (lastTradeTimestamp.add(execution.twapCooldownPeriod) < block.timestamp) {
                    shouldRebalanceEnum = ShouldRebalance.ITERATE_REBALANCE;
                }
            } else {
                // If not TWAP, then check if the rebalance interval has elapsed OR current leverage is above max leverage OR current leverage is below
                // min leverage
                if (
                    block.timestamp.sub(lastTradeTimestamp) > methodology.rebalanceInterval
                    || currentLeverageRatioAbs > _maxLeverageRatio.abs()
                    || currentLeverageRatioAbs < _minLeverageRatio.abs()
                ) {
                    shouldRebalanceEnum = ShouldRebalance.REBALANCE;
                }
            }
        }

        return shouldRebalanceEnum;
    }
}