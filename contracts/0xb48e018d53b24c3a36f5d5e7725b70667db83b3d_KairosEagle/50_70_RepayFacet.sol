// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IRepayFacet} from "./interface/IRepayFacet.sol";

import {Loan, Protocol} from "./DataStructure/Storage.sol";
import {LoanAlreadyRepaid} from "./DataStructure/Errors.sol";
import {protocolStorage} from "./DataStructure/Global.sol";
import {Ray} from "./DataStructure/Objects.sol";
import {RayMath} from "./utils/RayMath.sol";
import {Erc20CheckedTransfer} from "./utils/Erc20CheckedTransfer.sol";

/// @notice handles repayment with interests of loans
contract RepayFacet is IRepayFacet {
    using RayMath for Ray;
    using RayMath for uint256;
    using Erc20CheckedTransfer for IERC20;

    /// @notice repay one or multiple loans, gives collaterals back
    /// @dev repay on behalf is activated, the collateral goes to the original borrower
    /// @param loanIds identifiers of loans to repay
    function repay(uint256[] memory loanIds) external {
        Protocol storage proto = protocolStorage();
        Loan storage loan;
        uint256 lent;
        uint256 interests;
        uint256 toRepay;

        for (uint256 i = 0; i < loanIds.length; i++) {
            loan = proto.loan[loanIds[i]];
            // loan.payment.paid may be at 0 and considered repaid in case of an auction sale executed at price 0
            if (loan.payment.paid > 0 || loan.payment.borrowerClaimed || loan.payment.liquidated) {
                revert LoanAlreadyRepaid(loanIds[i]);
            }
            lent = loan.lent;
            /* if the linear interests are very low due to a short time elapsed, the minimal interests amount to repay
            is applied as an anti ddos mechanism */
            interests = RayMath.max(
                /* during the interests calculus, we can consider that (block.timestamp - loan.startDate)
                won't exceed 1e10 (>100 years) and interest per second (unwrapped value) won't exceed
                1e27 (corresponding to an amount to repay doubling after 1 second), we can deduce that
                (loan.interestPerSecond.mul(block.timestamp - loan.startDate)) is capped by 1e10 * 1e27 = 1e37
                we want to avoid the interests calculus to overflow so the result must not exceed 1e77
                as (1e77 < type(uint256).max). So we can allow `lent` to go as high as 1e40, but not above.
                This explains why borrowing throws on loan.lent > 1e40, as this realisticly avoids
                repaying being impossible due to an overflow. */
                /* the interest per second is a share of what has been lent to add to the interests each second. The
                next line accrues linearly */
                lent.mul(loan.interestPerSecond.mul(block.timestamp - loan.startDate)),
                loan.payment.minInterestsToRepay
            );
            toRepay = lent + interests;
            loan.payment.paid = toRepay;
            loan.payment.borrowerClaimed = true;
            loan.assetLent.checkedTransferFrom(msg.sender, address(this), toRepay);
            loan.collateral.implem.safeTransferFrom(address(this), loan.borrower, loan.collateral.id);
            emit Repay(loanIds[i]);
        }
    }
}