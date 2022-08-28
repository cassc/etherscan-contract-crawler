// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC4626Upgradeable.sol";

import "./external/notional/lib/DateTime.sol";
import { IWrappedfCashComplete } from "./external/notional/interfaces/IWrappedfCash.sol";
import { NotionalViews, MarketParameters } from "./external/notional/interfaces/INotional.sol";
import "./interfaces/IFRPViewer.sol";
import "./interfaces/IFRPHarvester.sol";
import "./interfaces/IFRPVault.sol";
import "./interfaces/IFRPViews.sol";

/// @title Fixed rate product vault helper view functions
/// @notice Contains helper view functions
contract FRPViews is IFRPViews {
    /// @inheritdoc IFRPViews
    function getAPY(IFRPViewer _FRP) external view returns (uint) {
        uint16 currencyId = _FRP.currencyId();
        address[2] memory fCashPositions = _FRP.getfCashPositions();
        uint8 supportedMaturities = _FRP.SUPPORTED_MATURITIES();
        uint numerator;
        uint denominator;
        for (uint i = 0; i < supportedMaturities; i++) {
            IWrappedfCashComplete fCashPosition = IWrappedfCashComplete(fCashPositions[i]);
            uint fCashBalance = fCashPosition.balanceOf(address(_FRP));
            if (!fCashPosition.hasMatured() && fCashBalance != 0) {
                // settlement date is the same for 3 and 6 month markets since they both settle at the same time.
                // 3 month market matures while 6 month market rolls to become a 3 month market.
                MarketParameters memory marketParameters = NotionalViews(_FRP.notionalRouter()).getMarket(
                    currencyId,
                    fCashPosition.getMaturity(),
                    DateTime.getReferenceTime(block.timestamp) + Constants.QUARTER
                );
                uint assets = fCashPosition.convertToAssets(fCashBalance);
                numerator += marketParameters.oracleRate * assets;
                denominator += assets;
            }
        }
        if (denominator != 0) {
            return numerator / denominator;
        } else {
            return 0;
        }
    }

    /// @inheritdoc IFRPViews
    function canHarvestMaxDepositedAmount(address _FRP)
        external
        view
        returns (bool canHarvest, uint maxDepositedAmount)
    {
        maxDepositedAmount = getMaxDepositedAmount(_FRP);
        canHarvest = canHarvestAmount(maxDepositedAmount, _FRP);
    }

    /// @inheritdoc IFRPViews
    function canHarvestAmount(uint _amount, address _FRP) public view returns (bool) {
        (, IFRPVault.NotionalMarket memory highestYieldMarket) = IFRPHarvester(_FRP).sortMarketsByOracleRate();
        IWrappedfCashFactory wrappedfCashFactory = IWrappedfCashFactory(IFRPViewer(_FRP).wrappedfCashFactory());
        IWrappedfCashComplete wrappedfCash = IWrappedfCashComplete(
            wrappedfCashFactory.computeAddress(IFRPViewer(_FRP).currencyId(), uint40(highestYieldMarket.maturity))
        );
        uint fCashAmount = wrappedfCash.previewDeposit(_amount);
        uint fCashAmountOracle = wrappedfCash.convertToShares(_amount);
        return (fCashAmount >= (fCashAmountOracle * IFRPViewer(_FRP).maxLoss()) / IFRPViewer(_FRP).BP());
    }

    /// @inheritdoc IFRPViews
    function getMaxDepositedAmount(address _FRP) public view returns (uint maxDepositedAmount) {
        maxDepositedAmount += IERC4626Upgradeable(IERC4626Upgradeable(_FRP).asset()).balanceOf(_FRP);
        address[2] memory fCashPositions = IFRPViewer(_FRP).getfCashPositions();
        uint8 supportedMaturities = IFRPViewer(_FRP).SUPPORTED_MATURITIES();
        for (uint i = 0; i < supportedMaturities; i++) {
            IWrappedfCashComplete fCashPosition = IWrappedfCashComplete(fCashPositions[i]);
            if (fCashPosition.hasMatured()) {
                uint fCashAmount = fCashPosition.balanceOf(address(this));
                if (fCashAmount != 0) {
                    maxDepositedAmount += fCashPosition.previewRedeem(fCashAmount);
                }
            }
        }
    }

    // functions which checks
    //    function
}