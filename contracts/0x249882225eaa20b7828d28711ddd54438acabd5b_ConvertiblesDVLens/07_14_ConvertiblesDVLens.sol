// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IConvertiblesDVLens.sol";
import "../interfaces/IConvertibleBondBox.sol";
import "../../src/contracts/external/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev View functions only - for front-end use
 */

contract ConvertiblesDVLens is IConvertiblesDVLens {
    struct DecimalPair {
        uint256 tranche;
        uint256 stable;
    }

    struct CollateralBalance {
        uint256 safe;
        uint256 risk;
    }

    struct StagingBalances {
        uint256 safeTranche;
        uint256 riskTranche;
        uint256 safeSlip;
        uint256 riskSlip;
        uint256 stablesBorrow;
        uint256 stablesLend;
        uint256 stablesTotal;
    }

    function viewStagingStatsIBO(IStagingBox _stagingBox)
        external
        view
        returns (StagingDataIBO memory)
    {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond
        ) = fetchElasticStack(_stagingBox);
        CollateralBalance memory simTrancheCollateral = calcTrancheCollateral(
            convertibleBondBox,
            bond,
            _stagingBox.safeTranche().balanceOf(address(_stagingBox)),
            _stagingBox.riskTranche().balanceOf(address(_stagingBox))
        );
        uint256 stableBalance = _stagingBox.stableToken().balanceOf(
            address(_stagingBox)
        );

        DecimalPair memory decimals = DecimalPair(
            ERC20(address(_stagingBox.safeTranche())).decimals(),
            ERC20(address(_stagingBox.stableToken())).decimals()
        );

        StagingDataIBO memory data = StagingDataIBO(
            NumFixedPoint(
                _stagingBox.lendSlip().totalSupply(),
                decimals.stable
            ),
            NumFixedPoint(
                _stagingBox.borrowSlip().totalSupply(),
                decimals.stable
            ),
            NumFixedPoint(
                _stagingBox.safeTranche().balanceOf(address(_stagingBox)),
                decimals.tranche
            ),
            NumFixedPoint(
                _stagingBox.riskTranche().balanceOf(address(_stagingBox)),
                decimals.tranche
            ),
            NumFixedPoint(stableBalance, decimals.stable),
            NumFixedPoint(simTrancheCollateral.safe, decimals.tranche),
            NumFixedPoint(simTrancheCollateral.risk, decimals.tranche),
            NumFixedPoint(
                (simTrancheCollateral.safe + simTrancheCollateral.risk),
                decimals.tranche
            ),
            NumFixedPoint(stableBalance, decimals.stable)
        );

        return data;
    }

    function viewStagingStatsActive(IStagingBox _stagingBox)
        external
        view
        returns (StagingDataActive memory)
    {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond
        ) = fetchElasticStack(_stagingBox);
        CollateralBalance memory simTrancheCollateral = calcTrancheCollateral(
            convertibleBondBox,
            bond,
            _stagingBox.safeTranche().balanceOf(address(_stagingBox)),
            _stagingBox.riskTranche().balanceOf(address(_stagingBox))
        );
        CollateralBalance memory simSlipCollateral = calcTrancheCollateral(
            convertibleBondBox,
            bond,
            convertibleBondBox.safeSlip().balanceOf(address(_stagingBox)),
            convertibleBondBox.riskSlip().balanceOf(address(_stagingBox))
        );

        DecimalPair memory decimals = DecimalPair(
            ERC20(address(_stagingBox.safeTranche())).decimals(),
            ERC20(address(_stagingBox.stableToken())).decimals()
        );

        StagingBalances memory SB_Balances = StagingBalances(
            _stagingBox.safeTranche().balanceOf(address(_stagingBox)),
            _stagingBox.riskTranche().balanceOf(address(_stagingBox)),
            _stagingBox.convertibleBondBox().safeSlip().balanceOf(
                address(_stagingBox)
            ),
            _stagingBox.convertibleBondBox().riskSlip().balanceOf(
                address(_stagingBox)
            ),
            _stagingBox.s_reinitLendAmount(),
            _stagingBox.stableToken().balanceOf(address(_stagingBox)) -
                _stagingBox.s_reinitLendAmount(),
            _stagingBox.stableToken().balanceOf(address(_stagingBox))
        );

        StagingDataActive memory data = StagingDataActive(
            NumFixedPoint(
                _stagingBox.lendSlip().totalSupply(),
                decimals.stable
            ),
            NumFixedPoint(
                _stagingBox.borrowSlip().totalSupply(),
                decimals.stable
            ),
            NumFixedPoint(SB_Balances.safeTranche, decimals.tranche),
            NumFixedPoint(SB_Balances.riskTranche, decimals.tranche),
            NumFixedPoint(SB_Balances.safeSlip, decimals.tranche),
            NumFixedPoint(SB_Balances.riskSlip, decimals.tranche),
            NumFixedPoint(SB_Balances.stablesBorrow, decimals.stable),
            NumFixedPoint(SB_Balances.stablesLend, decimals.stable),
            NumFixedPoint(simTrancheCollateral.safe, decimals.tranche),
            NumFixedPoint(simTrancheCollateral.risk, decimals.tranche),
            NumFixedPoint(simSlipCollateral.safe, decimals.tranche),
            NumFixedPoint(simSlipCollateral.risk, decimals.tranche),
            NumFixedPoint(
                ((simTrancheCollateral.safe +
                    simTrancheCollateral.risk +
                    simSlipCollateral.risk) *
                    10**decimals.stable +
                    _stagingBox.s_reinitLendAmount() *
                    10**decimals.tranche),
                decimals.tranche + decimals.stable
            ),
            NumFixedPoint(
                (SB_Balances.stablesLend) +
                    (SB_Balances.safeSlip *
                        convertibleBondBox.currentPrice() *
                        (10**decimals.stable)) /
                    convertibleBondBox.s_priceGranularity() /
                    (10**decimals.tranche),
                decimals.stable
            )
        );
        return data;
    }

    function viewCBBStatsActive(IConvertibleBondBox _convertibleBondBox)
        external
        view
        returns (CBBDataActive memory)
    {
        CollateralBalance memory simTrancheCollateral = calcTrancheCollateral(
            _convertibleBondBox,
            _convertibleBondBox.bond(),
            _convertibleBondBox.safeTranche().balanceOf(
                address(_convertibleBondBox)
            ),
            _convertibleBondBox.riskTranche().balanceOf(
                address(_convertibleBondBox)
            )
        );
        uint256 stableBalance = _convertibleBondBox.stableToken().balanceOf(
            address(_convertibleBondBox)
        );

        DecimalPair memory decimals = DecimalPair(
            ERC20(address(_convertibleBondBox.safeTranche())).decimals(),
            ERC20(address(_convertibleBondBox.stableToken())).decimals()
        );

        CBBDataActive memory data = CBBDataActive(
            NumFixedPoint(
                _convertibleBondBox.safeSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.riskSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.s_repaidSafeSlips(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.safeTranche().balanceOf(
                    address(_convertibleBondBox)
                ),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.riskTranche().balanceOf(
                    address(_convertibleBondBox)
                ),
                decimals.tranche
            ),
            NumFixedPoint(stableBalance, decimals.stable),
            NumFixedPoint(simTrancheCollateral.safe, decimals.tranche),
            NumFixedPoint(simTrancheCollateral.risk, decimals.tranche),
            NumFixedPoint(
                _convertibleBondBox.currentPrice(),
                _convertibleBondBox.s_priceGranularity()
            ),
            NumFixedPoint(simTrancheCollateral.risk, decimals.tranche),
            NumFixedPoint(
                (simTrancheCollateral.safe *
                    (10**decimals.stable) +
                    stableBalance *
                    (10**decimals.tranche)),
                decimals.tranche + decimals.stable
            )
        );

        return data;
    }

    function viewCBBStatsMature(IConvertibleBondBox _convertibleBondBox)
        external
        view
        returns (CBBDataMature memory)
    {
        CollateralBalance memory simTrancheCollateral = calcTrancheCollateral(
            _convertibleBondBox,
            _convertibleBondBox.bond(),
            _convertibleBondBox.safeTranche().balanceOf(
                address(_convertibleBondBox)
            ),
            _convertibleBondBox.riskTranche().balanceOf(
                address(_convertibleBondBox)
            )
        );
        uint256 stableBalance = _convertibleBondBox.stableToken().balanceOf(
            address(_convertibleBondBox)
        );

        uint256 riskTrancheBalance = _convertibleBondBox
            .riskTranche()
            .balanceOf(address(_convertibleBondBox));

        uint256 zPenaltyTrancheCollateral = ((riskTrancheBalance -
            _convertibleBondBox.riskSlip().totalSupply()) *
            simTrancheCollateral.risk) / riskTrancheBalance;

        DecimalPair memory decimals = DecimalPair(
            ERC20(address(_convertibleBondBox.safeTranche())).decimals(),
            ERC20(address(_convertibleBondBox.stableToken())).decimals()
        );

        CBBDataMature memory data = CBBDataMature(
            NumFixedPoint(
                _convertibleBondBox.safeSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.riskSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.s_repaidSafeSlips(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.safeTranche().balanceOf(
                    address(_convertibleBondBox)
                ),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.riskSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                (riskTrancheBalance -
                    _convertibleBondBox.riskSlip().totalSupply()),
                decimals.tranche
            ),
            NumFixedPoint(stableBalance, decimals.stable),
            NumFixedPoint(simTrancheCollateral.safe, decimals.tranche),
            NumFixedPoint(
                (_convertibleBondBox.riskSlip().totalSupply() *
                    simTrancheCollateral.risk) / riskTrancheBalance,
                decimals.tranche
            ),
            NumFixedPoint(zPenaltyTrancheCollateral, decimals.tranche),
            NumFixedPoint(
                _convertibleBondBox.currentPrice(),
                _convertibleBondBox.s_priceGranularity()
            ),
            NumFixedPoint(
                simTrancheCollateral.risk - zPenaltyTrancheCollateral,
                decimals.tranche
            ),
            NumFixedPoint(
                (simTrancheCollateral.safe + zPenaltyTrancheCollateral) *
                    10**decimals.stable +
                    stableBalance *
                    10**decimals.tranche,
                decimals.stable + decimals.tranche
            )
        );

        return data;
    }

    function calcTrancheCollateral(
        IConvertibleBondBox convertibleBondBox,
        IBondController bond,
        uint256 safeTrancheAmount,
        uint256 riskTrancheAmount
    ) internal view returns (CollateralBalance memory) {
        uint256 riskTrancheCollateral = 0;
        uint256 safeTrancheCollateral = 0;

        uint256 collateralBalance = convertibleBondBox
            .collateralToken()
            .balanceOf(address(bond));

        if (collateralBalance > 0) {
            if (bond.isMature()) {
                riskTrancheCollateral = convertibleBondBox
                    .collateralToken()
                    .balanceOf(address(convertibleBondBox.riskTranche()));

                safeTrancheCollateral = convertibleBondBox
                    .collateralToken()
                    .balanceOf(address(convertibleBondBox.safeTranche()));
            } else {
                for (
                    uint256 i = 0;
                    i < bond.trancheCount() - 1 && collateralBalance > 0;
                    i++
                ) {
                    (ITranche tranche, ) = bond.tranches(i);
                    uint256 amount = Math.min(
                        tranche.totalSupply(),
                        collateralBalance
                    );
                    collateralBalance -= amount;

                    if (i == convertibleBondBox.trancheIndex()) {
                        safeTrancheCollateral = amount;
                    }
                }

                riskTrancheCollateral = collateralBalance;
            }
        }

        safeTrancheCollateral =
            (safeTrancheCollateral * safeTrancheAmount) /
            convertibleBondBox.safeTranche().totalSupply();

        riskTrancheCollateral =
            (riskTrancheCollateral * riskTrancheAmount) /
            convertibleBondBox.riskTranche().totalSupply();

        CollateralBalance memory collateral = CollateralBalance(
            safeTrancheCollateral,
            riskTrancheCollateral
        );

        return collateral;
    }

    function fetchElasticStack(IStagingBox _stagingBox)
        internal
        view
        returns (IConvertibleBondBox, IBondController)
    {
        IConvertibleBondBox convertibleBondBox = _stagingBox
            .convertibleBondBox();
        IBondController bond = convertibleBondBox.bond();
        return (convertibleBondBox, bond);
    }
}