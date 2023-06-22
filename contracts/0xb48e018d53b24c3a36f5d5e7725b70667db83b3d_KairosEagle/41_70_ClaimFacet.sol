// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IClaimFacet} from "./interface/IClaimFacet.sol";
import {BorrowerAlreadyClaimed, LoanNotRepaidOrLiquidatedYet, NotBorrowerOfTheLoan} from "./DataStructure/Errors.sol";
import {ERC721CallerIsNotOwner} from "./DataStructure/ERC721Errors.sol";
import {Loan, Protocol, Provision, SupplyPosition} from "./DataStructure/Storage.sol";
import {ONE, protocolStorage, supplyPositionStorage} from "./DataStructure/Global.sol";
import {Ray} from "./DataStructure/Objects.sol";
import {RayMath} from "./utils/RayMath.sol";
import {Erc20CheckedTransfer} from "./utils/Erc20CheckedTransfer.sol";
import {SafeMint} from "./SupplyPositionLogic/SafeMint.sol";

/// @notice claims supplier and borrower rights on loans or supply positions
contract ClaimFacet is IClaimFacet, SafeMint {
    using RayMath for Ray;
    using RayMath for uint256;
    using Erc20CheckedTransfer for IERC20;

    /// @notice claims principal plus interests or liquidation share due as a supplier
    /// @param positionIds identifiers of one or multiple supply position to burn
    /// @return sent amount sent
    function claim(uint256[] calldata positionIds) external returns (uint256 sent) {
        Protocol storage proto = protocolStorage();
        SupplyPosition storage sp = supplyPositionStorage();
        Loan storage loan;
        Provision storage provision;
        uint256 loanId;
        uint256 sentTemp;

        for (uint256 i = 0; i < positionIds.length; i++) {
            if (sp.owner[positionIds[i]] != msg.sender) {
                revert ERC721CallerIsNotOwner();
            }
            _burn(positionIds[i]);
            provision = sp.provision[positionIds[i]];
            loanId = provision.loanId;
            loan = proto.loan[loanId];

            if (loan.payment.liquidated) {
                sentTemp = sendShareOfSaleAsSupplier(loan, provision);
            } else {
                if (loan.payment.paid == 0) {
                    revert LoanNotRepaidOrLiquidatedYet(loanId);
                }
                sentTemp = sendInterests(loan, provision);
            }
            emit Claim(msg.sender, sentTemp, loanId);
            sent += sentTemp;
        }
    }

    /// @notice claims share of liquidation due to a borrower who's collateral has been sold
    /// @param loanIds loan identifiers of one or multiple loans where the borrower wants to claim liquidation share
    /// @return sent amount sent
    function claimAsBorrower(uint256[] calldata loanIds) external returns (uint256 sent) {
        Protocol storage proto = protocolStorage();
        Loan storage loan;
        uint256 sentTemp;
        uint256 loanId;

        for (uint256 i = 0; i < loanIds.length; i++) {
            loanId = loanIds[i];
            loan = proto.loan[loanId];
            if (loan.borrower != msg.sender) {
                revert NotBorrowerOfTheLoan(loanId);
            }
            if (loan.payment.borrowerClaimed) {
                revert BorrowerAlreadyClaimed(loanId);
            }
            if (loan.payment.liquidated) {
                loan.payment.borrowerClaimed = true;
                // 1 - shareLent = share belonging to the borrower (not used as collateral)
                sentTemp = loan.payment.paid.mul(ONE.sub(loan.shareLent));
            } else {
                revert LoanNotRepaidOrLiquidatedYet(loanId);
            }
            if (sentTemp > 0) {
                /* the function may be called to store that the borrower claimed its due, but if this due is of 0 there
                is no point in emitting a transfer and claim event */
                loan.assetLent.checkedTransfer(msg.sender, sentTemp);
                sent += sentTemp;
                emit Claim(msg.sender, sentTemp, loanId);
                // sentTemp is reassigned or the execution reverts on next loop
            }
        }
    }

    /// @notice sends principal plus interests of the loan to `msg.sender`
    /// @param loan - to calculate amount from
    /// @param provision liquidity provision for this loan
    /// @return sent amount sent
    function sendInterests(Loan storage loan, Provision storage provision) internal returns (uint256 sent) {
        uint256 interests = loan.payment.paid - loan.lent;
        if (interests == loan.payment.minInterestsToRepay) {
            // this is the case if the loan is repaid shortly after issuance
            // each lender gets its minimal interest, as an anti ddos measure to spam offer
            sent = provision.amount + interests;
        } else {
            /* provision.amount / lent = share of the interests belonging to the lender. The parenthesis make the
            calculus in the order that maximizes precison */
            sent = provision.amount + (interests * (provision.amount)) / loan.lent;
        }
        loan.assetLent.checkedTransfer(msg.sender, sent);
    }

    /// @notice sends liquidation share due to `msg.sender` as a supplier
    /// @param loan - from which the collateral were liquidated
    /// @param provision liquidity provisioned by this loan by the supplier
    /// @return sent amount sent
    function sendShareOfSaleAsSupplier(Loan storage loan, Provision storage provision) internal returns (uint256 sent) {
        // in the case of a liqudidation, provision.share is considered the share of the NFT acquired by the lender
        sent = loan.payment.paid.mul(provision.share);
        loan.assetLent.checkedTransfer(msg.sender, sent);
    }
}