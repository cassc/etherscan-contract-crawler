// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NFToken, Ray} from "./Objects.sol";

/// @notice type definitions of data permanently stored

/// @notice Parameters affecting liquidations by dutch auctions. The current auction parameters
///         are assigned to new loans at borrow time and can't be modified during the loan life.
/// @param duration number of seconds after the auction start when the price hits 0
/// @param priceFactor multiplier of the mean tvl used as start price for the auction
struct Auction {
    uint256 duration;
    Ray priceFactor;
}

/// @notice General protocol
/// @param nbOfLoans total number of loans ever issued (active and ended)
/// @param nbOfTranches total number of interest rates tranches ever created (active and inactive)
/// @param auctionParams - sets auctions duration and initial prices
/// @param tranche interest rate of tranche of provided id, in multiplier per second
///         I.e lent * time since loan start * tranche = interests to repay
/// @param loan - of id -
/// @param minOfferCost minimum amount repaid per offer used in a loan
/// @param offerBorrowAmountLowerBound borrow amount per offer has to be strightly higher than this value
struct Protocol {
    uint256 nbOfLoans;
    uint256 nbOfTranches;
    Auction auction;
    mapping(uint256 => Ray) tranche;
    mapping(uint256 => Loan) loan;
    mapping(IERC20 => uint256) minOfferCost;
    mapping(IERC20 => uint256) offerBorrowAmountLowerBound;
}

/// @notice Issued Loan (corresponding to one collateral)
/// @param assetLent currency lent
/// @param lent total amount lent
/// @param shareLent between 0 and 1, the share of the collateral value lent
/// @param startDate timestamp of the borrowing transaction
/// @param endDate timestamp after which sale starts & repay is impossible
/// @param auction duration and price factor of the collateral auction in case of liquidation
/// @param interestPerSecond share of the amount lent added to the debt per second
/// @param borrower borrowing account
/// @param collateral NFT asset used as collateral
/// @param payment data on the payment, a non-0 payment.paid value means the loan lifecyle is over
struct Loan {
    IERC20 assetLent;
    uint256 lent;
    Ray shareLent;
    uint256 startDate;
    uint256 endDate;
    Auction auction;
    Ray interestPerSecond;
    address borrower;
    NFToken collateral;
    Payment payment;
}

/// @notice tracking of the payment state of a loan
/// @param paid amount sent on the tx closing the loan, non-zero value means loan's lifecycle is over
/// @param minInterestsToRepay minimum amount of interests that the borrower will need to repay
/// @param liquidated this loan has been closed at the liquidation stage, the collateral has been sold
/// @param borrowerClaimed borrower claimed his rights on this loan (either collateral or share of liquidation)
struct Payment {
    uint256 paid;
    uint256 minInterestsToRepay;
    bool liquidated;
    bool borrowerClaimed;
}

/// @notice storage for the ERC721 compliant supply position facet. Related NFTs represent supplier positions
/// @param name - of the NFT collection
/// @param symbol - of the NFT collection
/// @param totalSupply number of supply position ever issued - not decreased on burn
/// @param owner - of nft of id -
/// @param balance number of positions owned by -
/// @param tokenApproval address approved to transfer position of id - on behalf of its owner
/// @param operatorApproval address is approved to transfer all positions of - on his behalf
/// @param provision supply position metadata
struct SupplyPosition {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(uint256 => address) owner;
    mapping(address => uint256) balance;
    mapping(uint256 => address) tokenApproval;
    mapping(address => mapping(address => bool)) operatorApproval;
    mapping(uint256 => Provision) provision;
}

/// @notice storage for the ERC721 compliant supply position facet. Related NFTs represent supplier positions
/// @param baseUri - base uri
struct SupplyPositionOffChainMetadata {
    string baseUri;
}

/// @notice data on a liquidity provision from a supply offer in one existing loan
/// @param amount - supplied for this provision
/// @param share - of the collateral matched by this provision
/// @param loanId identifier of the loan the liquidity went to
struct Provision {
    uint256 amount;
    Ray share;
    uint256 loanId;
}