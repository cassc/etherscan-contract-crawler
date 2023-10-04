// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICurveStakingHelper} from "../../interfaces/compartments/staking/ICurveStakingHelper.sol";
import {ILenderVaultImpl} from "../../interfaces/ILenderVaultImpl.sol";
import {DataTypesPeerToPeer} from "../../DataTypesPeerToPeer.sol";
import {BaseCompartment} from "../BaseCompartment.sol";
import {Errors} from "../../../Errors.sol";

contract CurveLPStakingCompartment is BaseCompartment {
    using SafeERC20 for IERC20;

    address public liqGaugeAddr;

    address internal constant CRV_ADDR =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant GAUGE_CONTROLLER =
        0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;
    address internal constant CRV_MINTER_ADDR =
        0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    mapping(address => bool) public approvedStaker;

    function stake(uint256 gaugeIndex) external {
        DataTypesPeerToPeer.Loan memory loan = ILenderVaultImpl(vaultAddr).loan(
            loanIdx
        );
        if (msg.sender != loan.borrower && !approvedStaker[msg.sender]) {
            revert Errors.InvalidSender();
        }
        if (block.timestamp >= loan.expiry) {
            revert Errors.LoanExpired();
        }
        if (liqGaugeAddr != address(0)) {
            revert Errors.AlreadyStaked();
        }

        uint256 amount = IERC20(loan.collToken).balanceOf(address(this));

        address _liqGaugeAddr = ICurveStakingHelper(GAUGE_CONTROLLER).gauges(
            gaugeIndex
        );

        if (_liqGaugeAddr == address(0)) {
            revert Errors.InvalidGaugeIndex();
        }

        address lpTokenAddrForGauge = ICurveStakingHelper(_liqGaugeAddr)
            .lp_token();
        if (lpTokenAddrForGauge != loan.collToken) {
            revert Errors.IncorrectGaugeForLpToken();
        }
        liqGaugeAddr = _liqGaugeAddr;
        IERC20(loan.collToken).safeIncreaseAllowance(_liqGaugeAddr, amount);
        ICurveStakingHelper(_liqGaugeAddr).deposit(amount);
        IERC20(loan.collToken).safeDecreaseAllowance(
            _liqGaugeAddr,
            IERC20(loan.collToken).allowance(address(this), _liqGaugeAddr)
        );
        emit Staked(gaugeIndex, _liqGaugeAddr, amount);
    }

    function toggleApprovedStaker(address _staker) external {
        DataTypesPeerToPeer.Loan memory loan = ILenderVaultImpl(vaultAddr).loan(
            loanIdx
        );
        if (msg.sender != loan.borrower) {
            revert Errors.InvalidSender();
        }
        bool currStakingState = approvedStaker[_staker];
        approvedStaker[_staker] = !currStakingState;
        emit UpdatedApprovedStaker(_staker, !currStakingState);
    }

    // transfer coll on repays
    function transferCollFromCompartment(
        uint256 repayAmount,
        uint256 repayAmountLeft,
        uint128 /*reclaimCollAmount*/,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr
    ) external {
        _collAccountingHelper(
            repayAmount,
            repayAmountLeft,
            0,
            borrowerAddr,
            collTokenAddr,
            callbackAddr,
            false
        );
    }

    // unlockColl this would be called on defaults
    function unlockCollToVault(address collTokenAddr) external {
        _collAccountingHelper(
            1,
            1,
            0,
            address(0),
            collTokenAddr,
            address(0),
            true
        );
    }

    function getReclaimableBalance(
        address collToken
    ) external view override returns (uint256 reclaimableCollBalance) {
        reclaimableCollBalance = IERC20(collToken).balanceOf(address(this));
        address _liqGaugeAddr = liqGaugeAddr;
        if (_liqGaugeAddr != address(0)) {
            reclaimableCollBalance += IERC20(_liqGaugeAddr).balanceOf(
                address(this)
            );
        }
    }

    function _getRewardTokensAndWithdrawFromGauge(
        address _liqGaugeAddr,
        uint256 repayAmount,
        uint256 repayAmountLeft
    ) internal returns (address[8] memory _rewardTokenAddr) {
        uint256 currentStakedBal = IERC20(_liqGaugeAddr).balanceOf(
            address(this)
        );
        // withdraw proportion of gauge amount
        uint256 withdrawAmount = Math.mulDiv(
            repayAmount,
            currentStakedBal,
            repayAmountLeft
        );
        ICurveStakingHelper(CRV_MINTER_ADDR).mint(_liqGaugeAddr);
        try ICurveStakingHelper(_liqGaugeAddr).reward_tokens(0) returns (
            address rewardTokenAddrZeroIndex
        ) {
            // versions 2, 3, 4, or 5
            _rewardTokenAddr[0] = rewardTokenAddrZeroIndex;
            address rewardTokenAddr;
            for (uint256 i; i < 7; ) {
                rewardTokenAddr = ICurveStakingHelper(_liqGaugeAddr)
                    .reward_tokens(i + 1);
                if (rewardTokenAddr != address(0)) {
                    _rewardTokenAddr[i + 1] = rewardTokenAddr;
                } else {
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            try
                ICurveStakingHelper(_liqGaugeAddr).withdraw(
                    withdrawAmount,
                    true
                )
            // solhint-disable no-empty-blocks
            {
                // version 3, 4, or 5 gauge
            } catch {
                // version 2 gauge
                if (_rewardTokenAddr[0] != address(0)) {
                    ICurveStakingHelper(_liqGaugeAddr).claim_rewards();
                }
                ICurveStakingHelper(_liqGaugeAddr).withdraw(withdrawAmount);
            }
        } catch {
            // version 1 gauge
            ICurveStakingHelper(_liqGaugeAddr).withdraw(withdrawAmount);
        }
    }

    function _collAccountingHelper(
        uint256 repayAmount,
        uint256 repayAmountLeft,
        uint128 /*reclaimableCollBalance*/,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr,
        bool isUnlock
    ) internal returns (uint128 lpTokenAmount) {
        _withdrawCheck();
        if (msg.sender != vaultAddr) revert Errors.InvalidSender();

        address _liqGaugeAddr = liqGaugeAddr;

        // if gaugeAddr has been set, withdraw from gauge and get reward token addresses
        address[8] memory _rewardTokenAddr;
        if (_liqGaugeAddr != address(0)) {
            _rewardTokenAddr = _getRewardTokensAndWithdrawFromGauge(
                _liqGaugeAddr,
                repayAmount,
                repayAmountLeft
            );
        }

        // now check lp token balance of compartment which will be portion unstaked (could have never been staked)
        uint256 currentCompartmentBal = IERC20(collTokenAddr).balanceOf(
            address(this)
        );

        // transfer proportion of compartment lp token balance if never staked or an unlock, else all balance if staked
        lpTokenAmount = SafeCast.toUint128(
            isUnlock || _liqGaugeAddr != address(0)
                ? currentCompartmentBal
                : Math.mulDiv(
                    repayAmount,
                    currentCompartmentBal,
                    repayAmountLeft
                )
        );

        // if unlock, send to vault (msg.sender), else if callback send directly there, else to borrower
        address lpTokenReceiver = isUnlock
            ? msg.sender
            : (callbackAddr == address(0) ? borrowerAddr : callbackAddr);

        IERC20(collTokenAddr).safeTransfer(lpTokenReceiver, lpTokenAmount);

        if (_liqGaugeAddr != address(0)) {
            _transferRewards(
                isUnlock,
                borrowerAddr,
                repayAmount,
                repayAmountLeft,
                collTokenAddr,
                _rewardTokenAddr
            );
        }
    }

    function _transferRewards(
        bool isUnlock,
        address borrowerAddr,
        uint256 repayAmount,
        uint256 repayAmountLeft,
        address collTokenAddr,
        address[8] memory _rewardTokenAddr
    ) internal {
        // rest of rewards are always sent to borrower, not for callback
        // if unlock then sent to vaultAddr (msg.sender)
        address rewardReceiver = isUnlock ? msg.sender : borrowerAddr;
        // check crv token balance
        uint256 currentCrvBal = IERC20(CRV_ADDR).balanceOf(address(this));
        // transfer proportion of crv token balance
        uint256 tokenAmount = isUnlock
            ? currentCrvBal
            : Math.mulDiv(repayAmount, currentCrvBal, repayAmountLeft);

        // only perform crv transfer if
        // 1) crv token amount > 0 and coll token is not CRV else skip
        // if unlock, still ok to skip since then all balance would have been
        // transferred to vault earlier in this _getRewardTokensAndWithdrawFromGauge function
        // note: this should never actually happen since crv
        // and this compartment should not be whitelisted, but just in case
        if (tokenAmount > 0 && CRV_ADDR != collTokenAddr) {
            IERC20(CRV_ADDR).safeTransfer(rewardReceiver, tokenAmount);
        }

        uint256 i;
        uint256 currentRewardTokenBal;
        while (i < 8 && _rewardTokenAddr[i] != address(0)) {
            // skip invalid reward tokens
            if (_checkIfValidRewardToken(collTokenAddr, i, _rewardTokenAddr)) {
                currentRewardTokenBal = IERC20(_rewardTokenAddr[i]).balanceOf(
                    address(this)
                );

                tokenAmount = isUnlock
                    ? currentRewardTokenBal
                    : Math.mulDiv(
                        repayAmount,
                        currentRewardTokenBal,
                        repayAmountLeft
                    );

                if (tokenAmount > 0) {
                    IERC20(_rewardTokenAddr[i]).safeTransfer(
                        rewardReceiver,
                        tokenAmount
                    );
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function _checkIfValidRewardToken(
        address collTokenAddr,
        uint256 index,
        address[8] memory rewardTokens
    ) internal pure returns (bool) {
        // invalid reward if it is equal to collateral or crv token
        if (
            rewardTokens[index] == collTokenAddr ||
            rewardTokens[index] == CRV_ADDR
        ) {
            return false;
        }
        // check if reward token is a duplicate in previous entries
        if (index > 0) {
            for (uint256 i; i < index; ) {
                if (rewardTokens[i] == rewardTokens[index]) {
                    return false;
                }
                unchecked {
                    ++i;
                }
            }
        }
        return true;
    }
}