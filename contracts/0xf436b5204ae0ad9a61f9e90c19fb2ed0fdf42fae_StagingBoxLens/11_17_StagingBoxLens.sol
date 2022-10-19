// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IStagingBoxLens.sol";
import "../interfaces/IConvertibleBondBox.sol";
import "@buttonwood-protocol/button-wrappers/contracts/interfaces/IButtonToken.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StagingBoxLens is IStagingBoxLens {
    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewTransmitReInitBool(IStagingBox _stagingBox)
        public
        view
        returns (bool)
    {
        bool isLend = false;

        uint256 stableBalance = _stagingBox.stableToken().balanceOf(
            address(_stagingBox)
        );
        uint256 safeTrancheBalance = _stagingBox.safeTranche().balanceOf(
            address(_stagingBox)
        );
        uint256 expectedStableLoan = (safeTrancheBalance *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        //if excess borrowDemand, call lend
        if (expectedStableLoan >= stableBalance) {
            isLend = true;
        }

        return isLend;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewSimpleWrapTrancheBorrow(
        IStagingBox _stagingBox,
        uint256 _amountRaw
    ) public view returns (uint256, uint256) {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //calculate rebase token qty w wrapperfunction
        uint256 buttonAmount = wrapper.underlyingToWrapper(_amountRaw);

        //calculate safeTranche (borrowSlip amount) amount with tranche ratio & CDR
        uint256 bondCollateralBalance = wrapper.balanceOf(address(bond));

        uint256 bondDebt = bond.totalDebt();

        if (bondDebt == 0) {
            bondDebt = buttonAmount;
            bondCollateralBalance = buttonAmount;
        }

        uint256 safeTrancheAmount = (buttonAmount *
            convertibleBondBox.safeRatio() *
            bondDebt) /
            bondCollateralBalance /
            convertibleBondBox.s_trancheGranularity();

        //calculate stabletoken amount w/ safeTrancheAmount & initialPrice
        uint256 stableLoanAmount = (safeTrancheAmount *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        return (stableLoanAmount, safeTrancheAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewSimpleWithdrawBorrowUnwrap(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) public view returns (uint256, uint256) {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        uint256 safeTrancheAmount = (_borrowSlipAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.stableDecimals();

        uint256 riskTrancheAmount = (safeTrancheAmount *
            convertibleBondBox.riskRatio()) / convertibleBondBox.safeRatio();

        //calculate total amount of tranche tokens by dividing by safeRatio
        uint256 trancheTotal = safeTrancheAmount + riskTrancheAmount;

        //multiply with CDR to get btn token amount
        uint256 buttonAmount = 0;
        if (bond.totalDebt() > 0) {
            if (!bond.isMature()) {
                buttonAmount =
                    (trancheTotal *
                        convertibleBondBox.collateralToken().balanceOf(
                            address(bond)
                        )) /
                    bond.totalDebt();
            } else {
                buttonAmount =
                    (safeTrancheAmount *
                        convertibleBondBox.collateralToken().balanceOf(
                            address(convertibleBondBox.safeTranche())
                        )) /
                    convertibleBondBox.safeTranche().totalSupply();
                buttonAmount +=
                    (riskTrancheAmount *
                        convertibleBondBox.collateralToken().balanceOf(
                            address(convertibleBondBox.riskTranche())
                        )) /
                    convertibleBondBox.riskTranche().totalSupply();
            }
        }

        //calculate underlying with ButtonTokenWrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        return (underlyingAmount, buttonAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewWithdrawLendSlip(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256) {
        return _lendSlipAmount;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewRedeemBorrowSlipForRiskSlip(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) external view returns (uint256, uint256) {
        uint256 loanAmount = _borrowSlipAmount;

        uint256 riskSlipAmount = (loanAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.riskRatio() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.safeRatio() /
            _stagingBox.stableDecimals();

        return (riskSlipAmount, loanAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewRedeemLendSlipForSafeSlip(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256) {
        uint256 safeSlipAmount = (_lendSlipAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.stableDecimals();

        return (safeSlipAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemLendSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) public view returns (uint256, uint256) {
        //calculate lendSlips to safeSlips w/ initialPrice
        uint256 safeSlipsAmount = (_lendSlipAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.stableDecimals();

        return _safeSlipsForStablesWithFees(_stagingBox, safeSlipsAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemSafeSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) public view returns (uint256, uint256) {
        return _safeSlipsForStablesWithFees(_stagingBox, _safeSlipAmount);
    }

    function _safeSlipsForStablesWithFees(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) internal view returns (uint256, uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        uint256 feeSlip = (_safeSlipAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        uint256 stableAmount = _safeSlipsForStables(
            _stagingBox,
            _safeSlipAmount - feeSlip
        );
        uint256 feeAmount = _safeSlipsForStables(_stagingBox, feeSlip);

        return (stableAmount, feeAmount);
    }

    function _safeSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) internal view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        //calculate safeSlips to stables via math for CBB redeemStable
        uint256 cbbStableBalance = _stagingBox.stableToken().balanceOf(
            address(convertibleBondBox)
        );

        uint256 stableAmount = 0;

        if (convertibleBondBox.s_repaidSafeSlips() > 0) {
            stableAmount =
                (_safeSlipAmount * cbbStableBalance) /
                convertibleBondBox.s_repaidSafeSlips();
        }

        return stableAmount;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemLendSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        //calculate lendSlips to safeSlips w/ initialPrice
        uint256 safeSlipsAmount = (_lendSlipAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.stableDecimals();

        return _safeSlipRedeemUnwrapWithFees(_stagingBox, safeSlipsAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemSafeSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return _safeSlipRedeemUnwrapWithFees(_stagingBox, _safeSlipAmount);
    }

    function _safeSlipRedeemUnwrapWithFees(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        uint256 feeSlip = (_safeSlipAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        (
            uint256 underlyingAmount,
            uint256 buttonAmount
        ) = _safeSlipRedeemUnwrap(_stagingBox, _safeSlipAmount - feeSlip);

        (uint256 underlyingFee, uint256 buttonFee) = _safeSlipRedeemUnwrap(
            _stagingBox,
            feeSlip
        );

        return (underlyingAmount, buttonAmount, underlyingFee, buttonFee);
    }

    function _safeSlipRedeemUnwrap(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) internal view returns (uint256, uint256) {
        (
            IConvertibleBondBox convertibleBondBox,
            ,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //safeSlips = safeTranches
        //calculate safe tranches to rebasing collateral via balance of safeTranche address
        uint256 buttonAmount = (wrapper.balanceOf(
            address(_stagingBox.safeTranche())
        ) * _safeSlipAmount) / _stagingBox.safeTranche().totalSupply();

        //calculate penalty riskTranche
        uint256 penaltyTrancheTotal = _stagingBox.riskTranche().balanceOf(
            address(convertibleBondBox)
        ) - IERC20(_stagingBox.riskSlipAddress()).totalSupply();

        uint256 penaltyTrancheRedeemable = (_safeSlipAmount *
            penaltyTrancheTotal) /
            (IERC20(_stagingBox.safeSlipAddress()).totalSupply() -
                convertibleBondBox.s_repaidSafeSlips());

        //calculate rebasing collateral redeemable for riskTranche penalty
        //total the rebasing collateral
        buttonAmount +=
            (wrapper.balanceOf(address(_stagingBox.riskTranche())) *
                penaltyTrancheRedeemable) /
            _stagingBox.riskTranche().totalSupply();

        //convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, buttonAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemRiskSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        //subtract fees
        uint256 feeSlip = (_riskSlipAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        (
            uint256 underlyingAmount,
            uint256 buttonAmount
        ) = _redeemRiskSlipForTranches(_stagingBox, _riskSlipAmount - feeSlip);
        (uint256 underlyingFee, uint256 buttonFee) = _redeemRiskSlipForTranches(
            _stagingBox,
            feeSlip
        );

        return (underlyingAmount, buttonAmount, underlyingFee, buttonFee);
    }

    function _redeemRiskSlipForTranches(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    ) internal view returns (uint256, uint256) {
        (
            IConvertibleBondBox convertibleBondBox,
            ,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //calculate riskSlip to riskTranche - penalty
        uint256 riskTrancheAmount = _riskSlipAmount -
            (_riskSlipAmount * convertibleBondBox.penalty()) /
            convertibleBondBox.s_penaltyGranularity();
        //calculate rebasing collateral redeemable for riskTranche - penalty via tranche balance
        uint256 buttonAmount = (wrapper.balanceOf(
            address(_stagingBox.riskTranche())
        ) * riskTrancheAmount) / _stagingBox.riskTranche().totalSupply();
        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);
        // return both
        return (underlyingAmount, buttonAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRepayAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _stableAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //minus fees
        uint256 stableFees = (_stableAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        //calculate safeTranches for stables w/ current price
        uint256 safeTranchePayout = (_stableAmount *
            convertibleBondBox.s_priceGranularity() *
            convertibleBondBox.trancheDecimals()) /
            convertibleBondBox.currentPrice() /
            convertibleBondBox.stableDecimals();

        uint256 riskTranchePayout = (safeTranchePayout *
            convertibleBondBox.riskRatio()) / convertibleBondBox.safeRatio();

        //get collateral balance for rebasing collateral output
        uint256 collateralBalance = wrapper.balanceOf(address(bond));
        uint256 buttonAmount = (safeTranchePayout *
            convertibleBondBox.s_trancheGranularity() *
            collateralBalance) /
            convertibleBondBox.safeRatio() /
            bond.totalDebt();

        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, _stableAmount, stableFees, riskTranchePayout);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRepayMaxAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //riskTranche payout = riskSlipAmount
        uint256 riskTranchePayout = _riskSlipAmount;
        uint256 safeTranchePayout = (riskTranchePayout *
            _stagingBox.safeRatio()) / _stagingBox.riskRatio();

        //calculate repayment cost
        uint256 stablesOwed = (safeTranchePayout *
            convertibleBondBox.currentPrice() *
            convertibleBondBox.stableDecimals()) /
            convertibleBondBox.s_priceGranularity() /
            convertibleBondBox.trancheDecimals();

        //calculate stable Fees
        uint256 stableFees = (stablesOwed * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        //get collateral balance for rebasing collateral output
        uint256 collateralBalance = wrapper.balanceOf(address(bond));
        uint256 buttonAmount = (safeTranchePayout *
            convertibleBondBox.s_trancheGranularity() *
            collateralBalance) /
            convertibleBondBox.safeRatio() /
            bond.totalDebt();

        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, stablesOwed, stableFees, riskTranchePayout);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRepayAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _stableAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            IConvertibleBondBox convertibleBondBox,
            ,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //calculate fees
        uint256 stableFees = (_stableAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        //calculate tranches
        uint256 safeTranchepayout = (_stableAmount *
            convertibleBondBox.trancheDecimals()) /
            convertibleBondBox.stableDecimals();

        uint256 riskTranchePayout = (safeTranchepayout *
            _stagingBox.riskRatio()) / _stagingBox.safeRatio();

        //get collateral balance for safeTranche rebasing collateral output
        uint256 collateralBalanceSafe = wrapper.balanceOf(
            address(_stagingBox.safeTranche())
        );
        uint256 buttonAmount = (safeTranchepayout * collateralBalanceSafe) /
            convertibleBondBox.safeTranche().totalSupply();

        //get collateral balance for riskTranche rebasing collateral output
        uint256 collateralBalanceRisk = wrapper.balanceOf(
            address(_stagingBox.riskTranche())
        );
        buttonAmount +=
            (riskTranchePayout * collateralBalanceRisk) /
            convertibleBondBox.riskTranche().totalSupply();

        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, _stableAmount, stableFees, riskTranchePayout);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRepayMaxAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            IConvertibleBondBox convertibleBondBox,
            ,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //Calculate tranches
        //riskTranche payout = riskSlipAmount
        uint256 safeTranchePayout = (_riskSlipAmount *
            _stagingBox.safeRatio()) / _stagingBox.riskRatio();

        uint256 stablesOwed = (safeTranchePayout *
            _stagingBox.stableDecimals()) / _stagingBox.trancheDecimals();

        //calculate stable Fees
        uint256 stableFees = (stablesOwed * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        //get collateral balance for safeTranche rebasing collateral output
        uint256 buttonAmount = (safeTranchePayout *
            wrapper.balanceOf(address(_stagingBox.safeTranche()))) /
            convertibleBondBox.safeTranche().totalSupply();

        //get collateral balance for riskTranche rebasing collateral output
        uint256 collateralBalanceRisk = wrapper.balanceOf(
            address(_stagingBox.riskTranche())
        );

        buttonAmount +=
            (_riskSlipAmount * collateralBalanceRisk) /
            convertibleBondBox.riskTranche().totalSupply();

        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, stablesOwed, stableFees, _riskSlipAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewMaxRedeemBorrowSlip(IStagingBox _stagingBox, address _account)
        public
        view
        returns (uint256)
    {
        uint256 userBorrowSlip = _stagingBox.borrowSlip().balanceOf(_account);
        return Math.min(userBorrowSlip, _stagingBox.s_reinitLendAmount());
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemLendSlipForSafeSlip(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userLendSlip = _stagingBox.lendSlip().balanceOf(_account);
        uint256 sb_safeSlips = convertibleBondBox.safeSlip().balanceOf(
            address(_stagingBox)
        );

        uint256 maxRedeemableLendSlips = (sb_safeSlips *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        return Math.min(userLendSlip, maxRedeemableLendSlips);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemLendSlipForStables(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userLendSlip = _stagingBox.lendSlip().balanceOf(_account);

        uint256 sb_safeSlips = convertibleBondBox.safeSlip().balanceOf(
            address(_stagingBox)
        );

        uint256 maxRedeemableLendSlips = (Math.min(
            sb_safeSlips,
            convertibleBondBox.s_repaidSafeSlips()
        ) *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        return Math.min(userLendSlip, maxRedeemableLendSlips);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemSafeSlipForStables(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userSafeSlip = convertibleBondBox.safeSlip().balanceOf(
            _account
        );

        return Math.min(userSafeSlip, convertibleBondBox.s_repaidSafeSlips());
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxWithdrawLendSlips(IStagingBox _stagingBox, address _account)
        public
        view
        returns (uint256)
    {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        uint256 userLendSlip = _stagingBox.lendSlip().balanceOf(_account);

        uint256 maxWithdrawableLendSlips = userLendSlip;

        if (convertibleBondBox.s_startDate() > 0) {
            uint256 withdrawableStables = _stagingBox.stableToken().balanceOf(
                address(_stagingBox)
            ) - _stagingBox.s_reinitLendAmount();

            maxWithdrawableLendSlips = Math.min(
                userLendSlip,
                withdrawableStables
            );
        }

        return maxWithdrawableLendSlips;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxWithdrawBorrowSlips(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        uint256 userBorrowSlip = _stagingBox.borrowSlip().balanceOf(_account);

        uint256 maxWithdrawableBorrowSlip = userBorrowSlip;

        if (convertibleBondBox.s_startDate() > 0) {
            uint256 withdrawableSafeTranche = _stagingBox
                .safeTranche()
                .balanceOf(address(_stagingBox));

            uint256 withdrawableSafeTrancheToBorrowSlip = (withdrawableSafeTranche *
                    _stagingBox.initialPrice() *
                    _stagingBox.stableDecimals()) /
                    _stagingBox.priceGranularity() /
                    _stagingBox.trancheDecimals();

            maxWithdrawableBorrowSlip = Math.min(
                userBorrowSlip,
                withdrawableSafeTrancheToBorrowSlip
            );
        }

        return maxWithdrawableBorrowSlip;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemSafeSlipForTranches(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userSafeSlip = convertibleBondBox.safeSlip().balanceOf(
            _account
        );

        uint256 cbbSafeTrancheBalance = convertibleBondBox
            .safeTranche()
            .balanceOf(address(convertibleBondBox));

        return Math.min(userSafeSlip, cbbSafeTrancheBalance);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemLendSlipForTranches(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userLendSlip = _stagingBox.lendSlip().balanceOf(_account);

        uint256 cbbSafeTrancheBalance = convertibleBondBox
            .safeTranche()
            .balanceOf(address(convertibleBondBox));

        uint256 cbbSafeTrancheToLendSlip = (cbbSafeTrancheBalance *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        return Math.min(userLendSlip, cbbSafeTrancheToLendSlip);
    }

    function fetchElasticStack(IStagingBox _stagingBox)
        internal
        view
        returns (
            IConvertibleBondBox,
            IBondController,
            IButtonToken,
            IERC20
        )
    {
        IConvertibleBondBox convertibleBondBox = _stagingBox
            .convertibleBondBox();
        IBondController bond = convertibleBondBox.bond();
        IButtonToken wrapper = IButtonToken(bond.collateralToken());
        IERC20 underlying = IERC20(wrapper.underlying());

        return (convertibleBondBox, bond, wrapper, underlying);
    }
}