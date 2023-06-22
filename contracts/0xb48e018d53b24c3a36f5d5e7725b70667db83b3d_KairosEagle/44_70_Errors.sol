// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFToken, Offer} from "./Objects.sol";

error BadCollateral(Offer offer, NFToken providedNft);
error ERC20TransferFailed(IERC20 token, address from, address to);
error OfferHasExpired(Offer offer, uint256 expirationDate);
error RequestedAmountIsUnderMinimum(Offer offer, uint256 requested, uint256 lowerBound);
error RequestedAmountTooHigh(uint256 requested, uint256 offered, Offer offer);
error LoanAlreadyRepaid(uint256 loanId);
error LoanNotRepaidOrLiquidatedYet(uint256 loanId);
error NotBorrowerOfTheLoan(uint256 loanId);
error BorrowerAlreadyClaimed(uint256 loanId);
error CallerIsNotOwner(address admin);
error InvalidTranche(uint256 nbOfTranches);
error CollateralIsNotLiquidableYet(uint256 endDate, uint256 loanId);
error UnsafeAmountLent(uint256 lent);
error MultipleOffersUsed();
error PriceOverMaximum(uint256 maxPrice, uint256 price);
error CurrencyNotSupported(IERC20 currency);
error ShareMatchedIsTooLow(Offer offer, uint256 requested);