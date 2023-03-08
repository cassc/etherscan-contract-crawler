// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISodiumPrivatePool.sol";

interface ISodiumManager {
    struct PoolRequest {
        address pool;
        uint256 amount;
        ISodiumPrivatePool.Message oracleMessage;
    }

    struct Loan {
        uint256 length;
        uint256 endDate;
        uint256 auctionEndDate;
        uint256 tokenId;
        uint256 totalLiquidityAdded;
        address tokenAddress;
        address borrower;
        uint256 repayment;
        // Corresponding parameters should have the same ids in the arrays
        uint8[] orderTypes; // 1 => pool, 0 => metalener
        address[] lenders;
        uint256[] principals;
        uint256[] APRs;
        uint256[] timestamps;
    }

    struct MetaContribution {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint256 totalFundsOffered;
        uint256 APR; // APR which can be upto 10000; 7000 => 70%; 450 => 4,5%
        uint256 liquidityLimit;
        uint256 nonce;
    }

    struct Auction {
        address highestBidder;
        uint256 bid;
        uint256 boostedBid;
    }

    struct Validation {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice internal struct which is used in borrowFromPoolsAndMetalenders
    /// @notice method to avoid stack is too deep error
    struct Indexes {
        uint256 counter;
        uint256 poolArrayIndex;
        uint256 metaContributionArrayIndex;
    }

    event RequestMade(
        uint256 indexed id,
        address indexed requester,
        address tokenAddress,
        uint256 tokenId,
        uint256 length
    );
    event RequestWithdrawn(uint256 indexed requestId);
    event FundsAdded(uint256 indexed loanId, address lender, uint256 amount, uint256 APR);
    event RepaymentMade(
        uint256 indexed loanId,
        address indexed lender,
        uint256 principal,
        uint256 interest,
        uint256 fee
    );
    event BidMade(uint256 indexed id, address indexed bidder, uint256 bid, uint256 boost, uint256 index);
    event PurchaseMade(uint256 indexed id);
    event AuctionRepaymentMade(uint256 indexed auctionId, address indexed lender, uint256 amount);
    event AuctionConcluded(uint256 indexed id, address indexed winner);
    event FeeUpdated(uint256 feeInBasisPoints);
    event AuctionLengthUpdated(uint256 auctionLength);
    event WalletFactoryUpdated(address walletFactory);
    event TreasuryUpdated(address treasury);
    event ValidatorUpdated(address validator);
    event BorrowFromPoolMade(uint256 indexed loanId, address indexed lender, uint256 amount, uint256 APR);

    /// @notice Withdraws a request if there is no lenders
    /// @param requestId_ id of a request which is being withdrawn
    function withdraw(uint256 requestId_) external;

    /// @notice Borrow from pools
    /// @param loanId_  loanId
    /// @param poolRequests_ array of pool requests
    function borrowFromPools(uint256 loanId_, PoolRequest[] calldata poolRequests_) external;

    /// @notice Borrow from metalendes and pools
    /// @param loanId_  loanId
    /// @param poolRequests_ array of pool requests
    /// @param metaContributions_ array of metacontributions
    /// @param metacontributionAmounts_ array of amounts to use in a corresponding metacontribution
    /// @param validation_ signature which is used to validate meta contibutions
    /// @param orderTypes_ array of order types to distinguish whether lender in the loan struct is a pool of a meta-lender: 1 => pool, 0 => metalener
    function borrowFromPoolsAndMetalenders(
        uint256 loanId_,
        PoolRequest[] calldata poolRequests_,
        MetaContribution[] calldata metaContributions_,
        Validation calldata validation_,
        uint256[] calldata metacontributionAmounts_,
        uint8[] calldata orderTypes_
    ) external;

    /// @notice Borrow from metalenders
    /// @param loanId_  loanId
    /// @param metaContributions_ array of meta contributions
    /// @param amount_ array of amounts
    /// @param validation_ signature which is used to validate meta contibutions
    function borrowFromMetaLenders(
        uint256 loanId_,
        MetaContribution[] calldata metaContributions_,
        uint256[] calldata amount_,
        Validation calldata validation_
    ) external;

    /// @notice repay is used to repay loan partially or wholly
    /// @param loanId_ loan id whivh is being repaid
    /// @param amount_ amount which is used for repayment
    function repay(uint256 loanId_, uint256 amount_) external;

    /// @notice bid is used to place a bid during the auction
    /// @param auctionId_ id of an auctions which corresponds to the same loanId
    /// @param amount_ bid amount
    /// @param index_ index of msg.sender in the lenders array inside Loan structure
    function bid(
        uint256 auctionId_,
        uint256 amount_,
        uint256 index_
    ) external;

    /// @notice purchase loan collateral
    /// @param auctionId_ id of an auctions which corresponds to the same loanId
    function purchase(uint256 auctionId_) external;

    /// @notice resolve auction
    /// @param auctionId_ id of an auctions which corresponds to the same loanId
    function resolveAuction(uint256 auctionId_) external;

    function setFee(uint256 feeInBasisPoints_) external;

    function setAuctionLength(uint256 length) external;

    function setWalletFactory(address factory) external;

    function setTreasury(address treasury) external;

    function setValidator(address validator_) external;
}