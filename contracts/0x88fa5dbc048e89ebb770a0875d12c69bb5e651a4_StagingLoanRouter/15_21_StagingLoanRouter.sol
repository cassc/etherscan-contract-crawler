// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IStagingLoanRouter.sol";
import "../interfaces/IConvertibleBondBox.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@buttonwood-protocol/tranche/contracts/interfaces/IBondController.sol";
import "@buttonwood-protocol/tranche/contracts/interfaces/ITranche.sol";
import "@buttonwood-protocol/button-wrappers/contracts/interfaces/IButtonToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "forge-std/console2.sol";

contract StagingLoanRouter is IStagingLoanRouter, Context {
    /**
     * @inheritdoc IStagingLoanRouter
     */
    function simpleWrapTrancheBorrow(
        IStagingBox _stagingBox,
        uint256 _amountRaw,
        uint256 _minBorrowSlips
    ) public {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,
            IERC20 underlying
        ) = fetchElasticStack(_stagingBox);

        TransferHelper.safeTransferFrom(
            address(underlying),
            _msgSender(),
            address(this),
            _amountRaw
        );

        if (
            underlying.allowance(address(this), address(wrapper)) < _amountRaw
        ) {
            underlying.approve(address(wrapper), type(uint256).max);
        }
        uint256 wrapperAmount = wrapper.deposit(_amountRaw);

        wrapper.approve(address(bond), type(uint256).max);
        bond.deposit(wrapperAmount);

        uint256 riskTrancheBalance = _stagingBox.riskTranche().balanceOf(
            address(this)
        );
        uint256 safeTrancheBalance = _stagingBox.safeTranche().balanceOf(
            address(this)
        );

        if (
            _stagingBox.safeTranche().allowance(
                address(this),
                address(_stagingBox)
            ) < safeTrancheBalance
        ) {
            _stagingBox.safeTranche().approve(
                address(_stagingBox),
                type(uint256).max
            );
        }

        if (
            _stagingBox.riskTranche().allowance(
                address(this),
                address(_stagingBox)
            ) < riskTrancheBalance
        ) {
            _stagingBox.riskTranche().approve(
                address(_stagingBox),
                type(uint256).max
            );
        }

        uint256 borrowAmount = (Math.min(
            safeTrancheBalance,
            ((riskTrancheBalance * convertibleBondBox.safeRatio()) /
                convertibleBondBox.riskRatio())
        ) *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        _stagingBox.depositBorrow(_msgSender(), borrowAmount);

        if (borrowAmount < _minBorrowSlips)
            revert SlippageExceeded({
                expectedAmount: borrowAmount,
                minAmount: _minBorrowSlips
            });
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function multiWrapTrancheBorrow(
        IStagingBox _stagingBox,
        uint256 _amountRaw,
        uint256 _minBorrowSlips
    ) external {
        simpleWrapTrancheBorrow(_stagingBox, _amountRaw, _minBorrowSlips);

        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            ,

        ) = fetchElasticStack(_stagingBox);

        //send back unused tranches to _msgSender()
        uint256 trancheCount = bond.trancheCount();
        uint256 trancheIndex = convertibleBondBox.trancheIndex();
        for (uint256 i = 0; i < trancheCount; ) {
            if (i != trancheIndex && i != trancheCount - 1) {
                (ITranche tranche, ) = bond.tranches(i);
                tranche.transfer(
                    _msgSender(),
                    tranche.balanceOf(address(this))
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function simpleWithdrawBorrowUnwrap(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) external {
        //transfer borrowSlips
        _stagingBox.borrowSlip().transferFrom(
            _msgSender(),
            address(this),
            _borrowSlipAmount
        );

        //approve borrowSlips for StagingBox
        if (
            _stagingBox.borrowSlip().allowance(
                address(this),
                address(_stagingBox)
            ) < _borrowSlipAmount
        ) {
            _stagingBox.borrowSlip().approve(
                address(_stagingBox),
                type(uint256).max
            );
        }

        //withdraw borrowSlips for tranches
        _stagingBox.withdrawBorrow(_borrowSlipAmount);

        //redeem tranches with underlying bond & mature
        _redeemTrancheImmatureUnwrap(_stagingBox);
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function redeemLendSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        _stagingBox.lendSlip().transferFrom(
            _msgSender(),
            address(this),
            _lendSlipAmount
        );

        //redeem lendSlips for SafeSlips
        _stagingBox.redeemLendSlip(_lendSlipAmount);

        //get balance of SafeSlips and redeem for stables
        uint256 safeSlipAmount = IERC20(_stagingBox.safeSlipAddress())
            .balanceOf(address(this));

        convertibleBondBox.redeemStable(safeSlipAmount);

        //get balance of stables and send back to user
        uint256 stableBalance = convertibleBondBox.stableToken().balanceOf(
            address(this)
        );

        TransferHelper.safeTransfer(
            address(convertibleBondBox.stableToken()),
            _msgSender(),
            stableBalance
        );
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function redeemLendSlipsForTranchesAndUnwrap(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external {
        //Transfer lendslips to router
        _stagingBox.lendSlip().transferFrom(
            _msgSender(),
            address(this),
            _lendSlipAmount
        );

        //redeem lendSlips for SafeSlips
        _stagingBox.redeemLendSlip(_lendSlipAmount);

        //redeem SafeSlips for SafeTranche
        uint256 safeSlipAmount = IERC20(_stagingBox.safeSlipAddress())
            .balanceOf(address(this));

        _safeSlipsForTranchesUnwrap(_stagingBox, safeSlipAmount);
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function redeemSafeSlipsForTranchesAndUnwrap(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) external {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        //Transfer safeslips to router
        convertibleBondBox.safeSlip().transferFrom(
            _msgSender(),
            address(this),
            _safeSlipAmount
        );

        _safeSlipsForTranchesUnwrap(_stagingBox, _safeSlipAmount);
    }

    function _safeSlipsForTranchesUnwrap(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) internal {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        convertibleBondBox.redeemSafeTranche(_safeSlipAmount);

        //redeem SafeTranche for underlying collateral
        uint256 safeTrancheAmount = convertibleBondBox.safeTranche().balanceOf(
            address(this)
        );
        bond.redeemMature(
            address(convertibleBondBox.safeTranche()),
            safeTrancheAmount
        );

        //redeem penalty riskTranche
        uint256 riskTrancheAmount = convertibleBondBox.riskTranche().balanceOf(
            address(this)
        );
        if (riskTrancheAmount > 0) {
            bond.redeemMature(
                address(convertibleBondBox.riskTranche()),
                riskTrancheAmount
            );
        }

        //unwrap to _msgSender()
        wrapper.withdrawAllTo(_msgSender());
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function redeemRiskSlipsForTranchesAndUnwrap(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    ) external {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //Transfer riskSlips to router
        convertibleBondBox.riskSlip().transferFrom(
            _msgSender(),
            address(this),
            _riskSlipAmount
        );

        //Redeem riskSlips for riskTranches
        convertibleBondBox.redeemRiskTranche(_riskSlipAmount);

        //redeem riskTranche for underlying collateral
        uint256 riskTrancheAmount = convertibleBondBox.riskTranche().balanceOf(
            address(this)
        );
        bond.redeemMature(
            address(convertibleBondBox.riskTranche()),
            riskTrancheAmount
        );

        //unwrap to _msgSender()
        wrapper.withdrawAllTo(_msgSender());
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function repayAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _stableAmount,
        uint256 _stableFees,
        uint256 _riskSlipAmount
    ) external {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        //Transfer Stables to Router
        TransferHelper.safeTransferFrom(
            address(convertibleBondBox.stableToken()),
            _msgSender(),
            address(this),
            _stableAmount + _stableFees
        );

        //Calculate RiskSlips (minus fees) and transfer to router
        convertibleBondBox.riskSlip().transferFrom(
            _msgSender(),
            address(this),
            _riskSlipAmount
        );

        //call repay function
        if (
            convertibleBondBox.stableToken().allowance(
                address(this),
                address(convertibleBondBox)
            ) < _stableAmount + _stableFees
        ) {
            SafeERC20.safeIncreaseAllowance(
                (convertibleBondBox.stableToken()),
                address(convertibleBondBox),
                type(uint256).max - _stableAmount - _stableFees
            );
        }
        convertibleBondBox.repay(_stableAmount);

        _redeemTrancheImmatureUnwrap(_stagingBox);

        //send unpaid riskSlip back

        convertibleBondBox.riskSlip().transfer(
            _msgSender(),
            IERC20(_stagingBox.riskSlipAddress()).balanceOf(address(this))
        );
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function repayMaxAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _stableAmount,
        uint256 _stableFees,
        uint256 _riskSlipAmount
    ) external {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        //Transfer Stables + fees + slippage to Router
        TransferHelper.safeTransferFrom(
            address(convertibleBondBox.stableToken()),
            _msgSender(),
            address(this),
            _stableAmount + _stableFees
        );

        //Transfer risk slips to CBB
        convertibleBondBox.riskSlip().transferFrom(
            _msgSender(),
            address(this),
            _riskSlipAmount
        );

        //call repayMax function
        if (
            convertibleBondBox.stableToken().allowance(
                address(this),
                address(convertibleBondBox)
            ) < _stableAmount + _stableFees
        ) {
            SafeERC20.safeIncreaseAllowance(
                (convertibleBondBox.stableToken()),
                address(convertibleBondBox),
                type(uint256).max - _stableAmount - _stableFees
            );
        }
        convertibleBondBox.repayMax(_riskSlipAmount);

        _redeemTrancheImmatureUnwrap(_stagingBox);

        //send unused stables back to _msgSender()
        TransferHelper.safeTransfer(
            address(convertibleBondBox.stableToken()),
            _msgSender(),
            convertibleBondBox.stableToken().balanceOf(address(this))
        );
    }

    function _redeemTrancheImmatureUnwrap(IStagingBox _stagingBox) internal {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        uint256 safeRatio = convertibleBondBox.safeRatio();
        uint256 riskRatio = convertibleBondBox.riskRatio();

        uint256[] memory redeemAmounts = new uint256[](2);

        redeemAmounts[0] = convertibleBondBox.safeTranche().balanceOf(
            address(this)
        );
        redeemAmounts[1] = convertibleBondBox.riskTranche().balanceOf(
            address(this)
        );

        if (redeemAmounts[0] * riskRatio < redeemAmounts[1] * safeRatio) {
            redeemAmounts[1] = (redeemAmounts[0] * riskRatio) / safeRatio;
        } else {
            redeemAmounts[0] = (redeemAmounts[1] * safeRatio) / riskRatio;
        }

        redeemAmounts[0] -= redeemAmounts[0] % safeRatio;
        redeemAmounts[1] -= redeemAmounts[1] % riskRatio;

        bond.redeem(redeemAmounts);
        //unwrap rebasing collateral and send underlying to _msgSender()
        wrapper.withdrawAllTo(_msgSender());
    }

    /**
     * @inheritdoc IStagingLoanRouter
     */
    function repayAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _stableAmount,
        uint256 _stableFees,
        uint256 _riskSlipAmount
    ) external {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //Transfer Stables to Router
        TransferHelper.safeTransferFrom(
            address(convertibleBondBox.stableToken()),
            _msgSender(),
            address(this),
            _stableAmount + _stableFees
        );

        //Transfer to router
        convertibleBondBox.riskSlip().transferFrom(
            _msgSender(),
            address(this),
            _riskSlipAmount
        );

        //call repay function
        if (
            convertibleBondBox.stableToken().allowance(
                address(this),
                address(convertibleBondBox)
            ) < _stableAmount + _stableFees
        ) {
            SafeERC20.safeIncreaseAllowance(
                (convertibleBondBox.stableToken()),
                address(convertibleBondBox),
                type(uint256).max - _stableAmount - _stableFees
            );
        }
        convertibleBondBox.repay(_stableAmount);

        //call redeemMature on bond
        bond.redeemMature(
            address(convertibleBondBox.safeTranche()),
            convertibleBondBox.safeTranche().balanceOf(address(this))
        );

        bond.redeemMature(
            address(convertibleBondBox.riskTranche()),
            convertibleBondBox.riskTranche().balanceOf(address(this))
        );

        //unwrap rebasing collateral to _msgSender()
        wrapper.withdrawAllTo(_msgSender());
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