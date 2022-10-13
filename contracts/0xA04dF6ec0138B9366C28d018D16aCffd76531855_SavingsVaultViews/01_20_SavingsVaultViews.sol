// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC4626Upgradeable.sol";

import "./external/notional/lib/DateTime.sol";
import { IWrappedfCashComplete } from "./external/notional/interfaces/IWrappedfCash.sol";
import { NotionalViews, MarketParameters } from "./external/notional/interfaces/INotional.sol";
import "./external/notional/interfaces/INotionalV2.sol";

import "./interfaces/ISavingsVaultViewer.sol";
import "./interfaces/ISavingsVaultHarvester.sol";
import "./interfaces/ISavingsVault.sol";
import "./interfaces/ISavingsVaultViews.sol";

import "./libraries/TypeConversionLibrary.sol";

/// @title Savings vault helper view functions
/// @notice Contains helper view functions
contract SavingsVaultViews is ISavingsVaultViews {
    /// @inheritdoc ISavingsVaultViews
    uint16 public constant BP = 10_000;

    /// @inheritdoc ISavingsVaultViews
    function getAPY(ISavingsVaultViewer _savingsVault) external view returns (uint) {
        uint16 currencyId = _savingsVault.currencyId();
        address[2] memory fCashPositions = _savingsVault.getfCashPositions();
        uint numerator;
        uint denominator;
        for (uint i = 0; i < 2; i++) {
            IWrappedfCashComplete fCashPosition = IWrappedfCashComplete(fCashPositions[i]);
            uint fCashBalance = fCashPosition.balanceOf(address(_savingsVault));
            if (fCashBalance != 0) {
                uint oracleRate;
                if (fCashPosition.hasMatured()) {
                    (, ISavingsVault.NotionalMarket memory highestYieldMarket) = ISavingsVaultHarvester(
                        address(_savingsVault)
                    ).sortMarketsByOracleRate();
                    oracleRate = highestYieldMarket.oracleRate;
                } else {
                    // settlement date is the same for 3 and 6 month markets since they both settle at the same time.
                    // 3 month market matures while 6 month market rolls to become a 3 month market.
                    MarketParameters memory marketParameters = NotionalViews(_savingsVault.notionalRouter()).getMarket(
                        currencyId,
                        fCashPosition.getMaturity(),
                        DateTime.getReferenceTime(block.timestamp) + Constants.QUARTER
                    );
                    oracleRate = marketParameters.oracleRate;
                }
                uint assets = fCashPosition.convertToAssets(fCashBalance);
                numerator += oracleRate * assets;
                denominator += assets;
            }
        }
        return denominator != 0 ? numerator / denominator : 0;
    }

    /// @inheritdoc ISavingsVaultViews
    function scaleAmount(
        address _savingsVault,
        uint _amount,
        uint _percentage,
        uint _steps
    ) external view returns (uint) {
        (
            uint maturity,
            uint32 minImpliedRate,
            uint16 currencyId,
            INotionalV2 calculationViews
        ) = getHighestYieldMarketParameters(_savingsVault);
        (uint fCashAmount, , ) = calculationViews.getfCashLendFromDeposit(
            currencyId,
            _amount,
            maturity,
            minImpliedRate,
            block.timestamp,
            true
        );
        uint scalingAmount = (fCashAmount * _percentage) / BP;
        for (uint i = 0; i <= _steps; ) {
            try
                calculationViews.getDepositFromfCashLend(
                    currencyId,
                    fCashAmount,
                    maturity,
                    minImpliedRate,
                    block.timestamp
                )
            returns (uint amountUnderlying, uint, uint8, bytes32) {
                return amountUnderlying;
            } catch {
                // If we can scale it further we continue, else we exit the for loop.
                if (fCashAmount < scalingAmount) {
                    break;
                }
                fCashAmount -= scalingAmount;
            }
            unchecked {
                i = i + 1;
            }
        }
        return 0;
    }

    /// @inheritdoc ISavingsVaultViews
    function scaleWithBinarySearch(
        address _savingsVault,
        uint _amount,
        uint _steps
    ) external view returns (uint) {
        (
            uint maturity,
            uint32 minImpliedRate,
            uint16 currencyId,
            INotionalV2 calculationViews
        ) = getHighestYieldMarketParameters(_savingsVault);
        (uint high, , ) = calculationViews.getfCashLendFromDeposit(
            currencyId,
            _amount,
            maturity,
            minImpliedRate,
            block.timestamp,
            true
        );
        // try with the highest amount first to see if we can harvest it. In case that is possible return that amount.
        try
            calculationViews.getDepositFromfCashLend(currencyId, high, maturity, minImpliedRate, block.timestamp)
        returns (uint amountUnderlying, uint, uint8, bytes32) {
            return amountUnderlying;
        } catch {}
        // Otherwise find the most optimal amount in several steps
        uint low = 0;
        uint amountToReturn = 0;
        for (uint i = 0; i < _steps; i++) {
            uint mid = (low + high) / 2;
            try
                calculationViews.getDepositFromfCashLend(currencyId, mid, maturity, minImpliedRate, block.timestamp)
            returns (uint amountUnderlying, uint, uint8, bytes32) {
                // high remains the same
                low = mid;
                amountToReturn = amountUnderlying;
            } catch {
                // low remains the same.
                high = mid;
            }
        }
        return amountToReturn;
    }

    /// @inheritdoc ISavingsVaultViews
    function getMaxDepositedAmount(address _savingsVault) public view returns (uint maxDepositedAmount) {
        maxDepositedAmount += IERC4626Upgradeable(IERC4626Upgradeable(_savingsVault).asset()).balanceOf(_savingsVault);
        address[2] memory fCashPositions = ISavingsVaultViewer(_savingsVault).getfCashPositions();
        for (uint i = 0; i < 2; i++) {
            IWrappedfCashComplete fCashPosition = IWrappedfCashComplete(fCashPositions[i]);
            if (fCashPosition.hasMatured()) {
                uint fCashAmount = fCashPosition.balanceOf(address(this));
                if (fCashAmount != 0) {
                    maxDepositedAmount += fCashPosition.previewRedeem(fCashAmount);
                }
            }
        }
    }

    /// @inheritdoc ISavingsVaultViews
    function getHighestYieldMarketParameters(address _savingsVault)
        public
        view
        returns (
            uint maturity,
            uint32 minImpliedRate,
            uint16 currencyId,
            INotionalV2 calculationViews
        )
    {
        (, ISavingsVault.NotionalMarket memory highestYieldMarket) = ISavingsVaultHarvester(_savingsVault)
            .sortMarketsByOracleRate();
        maturity = highestYieldMarket.maturity;
        minImpliedRate = TypeConversionLibrary._safeUint32(
            (highestYieldMarket.oracleRate * ISavingsVaultViewer(_savingsVault).maxLoss()) / BP
        );
        currencyId = ISavingsVaultViewer(_savingsVault).currencyId();
        calculationViews = INotionalV2(ISavingsVaultViewer(_savingsVault).notionalRouter());
    }
}