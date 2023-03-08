// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/ISodiumWalletFactory.sol";
import "./interfaces/ISodiumWallet.sol";
import "./interfaces/ISodiumManager.sol";
import "./interfaces/ISodiumPrivatePool.sol";
import "./interfaces/IWETH.sol";

import "./libraries/Maths.sol";

abstract contract SodiumManager is
    ISodiumManager,
    Initializable,
    EIP712Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    ISodiumWalletFactory public sodiumWalletFactory;

    address internal sodiumTreasury;
    address internal validator;

    IWETH internal WETH;

    uint256 internal feeInBasisPoints; // fee ratio which can be upto 10000; 7000 => 70%; 450 => 4,5%
    uint256 internal auctionLengthInSeconds;

    mapping(address => address) public eoaToWallet;
    mapping(address => mapping(uint256 => bool)) private blackList;
    mapping(uint256 => mapping(address => uint256)) public nonces;

    mapping(uint256 => Loan) public loans; // loans and auctions have the same ids
    mapping(uint256 => Auction) public auctions; // loans and auctions have the same ids

    bytes32 private constant META_CONTRIBUTION_TYPE_HASH =
        keccak256(
            "MetaContribution(uint256 id,uint256 totalFundsOffered,uint256 APR,uint256 liquidityLimit,uint256 nonce)"
        );

    modifier duringAuctionOnly(uint256 auctionId) {
        require(
            block.timestamp > loans[auctionId].endDate && block.timestamp < loans[auctionId].auctionEndDate,
            "Sodium: loan is not ended; auction is ended"
        );
        _;
    }

    function initialize(
        string calldata name_,
        string calldata version_,
        uint256 feeInBasisPoints_,
        uint256 auctionLengthInSeconds_,
        address walletFactory_,
        address weth_,
        address treasury_,
        address validator_
    ) public initializer {
        __EIP712_init(name_, version_);
        __Ownable_init();
        feeInBasisPoints = feeInBasisPoints_;
        auctionLengthInSeconds = auctionLengthInSeconds_;
        sodiumWalletFactory = ISodiumWalletFactory(walletFactory_);
        sodiumTreasury = treasury_;
        validator = validator_;
        WETH = IWETH(weth_);
    }

    function withdraw(uint256 requestId_) external nonReentrant {
        Loan storage loan = loans[requestId_];

        require(loan.lenders.length == 0, "Sodium: there is unpaid lender");
        require(_msgSender() == loan.borrower, "Sodium: msg.sender is not borrower");
        _transferCollateral(loan.tokenAddress, loan.tokenId, eoaToWallet[loan.borrower], loan.borrower);

        delete loans[requestId_];
        emit RequestWithdrawn(requestId_);
    }

    function borrowFromPoolsAndMetalenders(
        uint256 loanId_,
        PoolRequest[] calldata poolRequests_,
        MetaContribution[] calldata metaContributions_,
        Validation calldata validation_,
        uint256[] calldata metacontributionAmounts_,
        uint8[] memory orderTypes_
    ) external nonReentrant {
        Loan storage loan = loans[loanId_];

        _preBorrowLogic(loan);
        _checkValidation(metaContributions_, validation_);

        Indexes memory i = Indexes(0, 0, 0);
        for (; i.counter < orderTypes_.length; ) {
            if (orderTypes_[i.counter] == 1) {
                _processPoolRequest(loanId_, loan, poolRequests_[i.poolArrayIndex]);
                unchecked {
                    ++i.poolArrayIndex;
                }
            } else if (orderTypes_[i.counter] == 0) {
                _processMetaContribution(
                    loan,
                    metaContributions_[i.metaContributionArrayIndex],
                    metacontributionAmounts_[i.metaContributionArrayIndex],
                    loanId_
                );

                unchecked {
                    ++i.metaContributionArrayIndex;
                }
            }
            unchecked {
                ++i.counter;
            }
        }
    }

    function borrowFromPools(uint256 loanId_, PoolRequest[] calldata poolRequests_) external nonReentrant {
        Loan storage loan = loans[loanId_];
        _preBorrowLogic(loan);

        uint256 i = 0;
        for (; i < poolRequests_.length; ) {
            _processPoolRequest(loanId_, loan, poolRequests_[i]);

            unchecked {
                ++i;
            }
        }
    }

    function borrowFromMetaLenders(
        uint256 loanId_,
        MetaContribution[] calldata metaContributions_,
        uint256[] calldata amount_,
        Validation calldata validation_
    ) external nonReentrant {
        Loan storage loan = loans[loanId_];

        _preBorrowLogic(loan);
        _checkValidation(metaContributions_, validation_);

        for (uint256 i = 0; i < metaContributions_.length; i++) {
            _processMetaContribution(loan, metaContributions_[i], amount_[i], loanId_);
        }
    }

    function repay(uint256 loanId_, uint256 amount_) external nonReentrant {
        Loan storage loan = loans[loanId_];

        require(block.timestamp < loan.endDate, "Sodium: loan ended");

        uint256 remainingFunds = amount_;
        uint256 minimumDuration = loan.length / 2; // Borrowers must pay interest on at least half the requested loan length

        for (uint256 k = loan.lenders.length; 0 < k; k--) {
            uint256 i = k - 1;

            uint256 principal = loan.principals[i];
            uint256 timePassed = block.timestamp - loan.timestamps[i];
            uint256 effectiveLoanDuration;

            if (loan.orderTypes[i] == 0) {
                effectiveLoanDuration = timePassed > minimumDuration ? timePassed : minimumDuration;
            } else {
                effectiveLoanDuration = timePassed;
            }

            (uint256 interest, uint256 fee) = Maths.calculateInterestAndFee(
                principal,
                loan.APRs[i],
                effectiveLoanDuration,
                feeInBasisPoints
            );

            address lender = loan.lenders[i];
            if (remainingFunds < principal + interest + fee) {
                (principal, interest, fee) = Maths.partialPaymentParameters(
                    remainingFunds,
                    loan.APRs[i],
                    effectiveLoanDuration,
                    feeInBasisPoints
                );
                loan.principals[i] -= principal;
                k = 1;
            } else if (remainingFunds == principal + interest + fee) {
                loan.lenders.pop();
                k = 1;
            } else {
                loan.lenders.pop();
            }

            _transferFromWETH(msg.sender, lender, principal + interest);
            _transferFromWETH(msg.sender, sodiumTreasury, fee);

            remainingFunds -= principal + interest + fee;

            emit RepaymentMade(loanId_, lender, principal, interest, fee);
        }

        if (loan.lenders.length == 0) {
            _transferCollateral(loan.tokenAddress, loan.tokenId, eoaToWallet[loan.borrower], loan.borrower);
            delete loans[loanId_];
        } else {
            loan.repayment += amount_;
        }
    }

    function bid(
        uint256 auctionId_,
        uint256 amount_,
        uint256 index_
    ) external duringAuctionOnly(auctionId_) nonReentrant {
        Loan storage loan = loans[auctionId_];
        Auction storage auction = auctions[auctionId_];

        address poolOrMetaContributor = msg.sender;

        if (auction.highestBidder != address(0)) {
            _transferWETH(auction.highestBidder, auction.bid);
        }
        _transferFromWETH(msg.sender, address(this), amount_);

        uint256 boost;
        auction.bid = amount_;
        if (index_ != loan.lenders.length) {
            require(poolOrMetaContributor == loan.lenders[index_], "Sodium: wrong index");

            uint256 lenderLiquidityStart = 0;
            uint256 end = loan.endDate;

            // Sum loan debt owed to those below lender in lending queue
            for (uint256 i = 0; i < index_; i++) {
                lenderLiquidityStart += Maths.principalPlusInterest(
                    loan.principals[i],
                    loan.APRs[i],
                    end - loan.timestamps[i]
                );
            }

            // Boost bid with lender's loaned liqudity
            if (amount_ >= lenderLiquidityStart) {
                boost = Maths.principalPlusInterest(
                    loan.principals[index_],
                    loan.APRs[index_],
                    end - loan.timestamps[index_]
                );

                amount_ += boost;
            }
        }

        // Check post-boost bid is greater than previous
        require(auction.boostedBid < amount_, "Sodium: previous boosted bid is higher");

        auction.boostedBid = amount_;
        auction.highestBidder = poolOrMetaContributor;

        emit BidMade(auctionId_, poolOrMetaContributor, amount_, boost, index_);
    }

    function purchase(uint256 auctionId_) external duringAuctionOnly(auctionId_) nonReentrant {
        Auction memory auction = auctions[auctionId_];
        Loan storage loan = loans[auctionId_];

        if (auction.highestBidder != address(0)) {
            // Pay back bidder
            // Funds are returned before paying other debt if bidder is the caller
            _transferWETH(auction.highestBidder, auction.bid);
        }

        if (loan.borrower != msg.sender && loan.repayment != 0) {
            // Pay back borrower if not the caller => will fail if to zero address
            _transferFromWETH(msg.sender, loan.borrower, loan.repayment);
        }

        uint256 i = 0;
        for (; i < loan.lenders.length; ) {
            // Repay lender
            if (loan.lenders[i] != msg.sender) {
                uint256 owedToLender = Maths.principalPlusInterest(
                    loan.principals[i],
                    loan.APRs[i],
                    loan.endDate - loan.timestamps[i]
                );

                _transferFromWETH(msg.sender, loan.lenders[i], owedToLender);
                emit AuctionRepaymentMade(auctionId_, loan.lenders[i], owedToLender);
            }

            unchecked {
                ++i;
            }
        }

        _auctionCleanup(auctionId_, msg.sender);
        emit PurchaseMade(auctionId_);
    }

    function resolveAuction(uint256 auctionId_) external nonReentrant {
        Loan storage loan = loans[auctionId_];

        require(loan.lenders.length != 0, "Sodium: no lenders in loan");
        require(loan.auctionEndDate < block.timestamp, "Sodium: auction is not ended");

        Auction memory auction = auctions[auctionId_];
        address winner = auction.highestBidder == address(0) ? loan.lenders[0] : auction.highestBidder;

        uint256 i = 0;
        for (; i < loan.lenders.length; ) {
            if (winner != loan.lenders[i]) {
                uint256 owed = Maths.principalPlusInterest(
                    loan.principals[i],
                    loan.APRs[i],
                    loan.endDate - loan.timestamps[i]
                );

                if (auction.bid <= owed) {
                    _transferWETH(loan.lenders[i], auction.bid);

                    emit AuctionRepaymentMade(auctionId_, loan.lenders[i], auction.bid);
                    auction.bid = 0;
                } else {
                    _transferWETH(loan.lenders[i], owed);
                    auction.bid -= owed;

                    emit AuctionRepaymentMade(auctionId_, loan.lenders[i], owed);
                }
            }

            unchecked {
                ++i;
            }
        }

        if (auction.bid != 0) {
            _transferWETH(loan.borrower, auction.bid);
        }

        _auctionCleanup(auctionId_, winner);
        emit AuctionConcluded(auctionId_, winner);
    }

    function setFee(uint256 feeInBasisPoints_) external onlyOwner {
        feeInBasisPoints = feeInBasisPoints_;
        emit FeeUpdated(feeInBasisPoints_);
    }

    function setAuctionLength(uint256 length) external onlyOwner {
        auctionLengthInSeconds = length;
        emit AuctionLengthUpdated(length);
    }

    function setWalletFactory(address factory) external onlyOwner {
        sodiumWalletFactory = ISodiumWalletFactory(factory);
        emit WalletFactoryUpdated(factory);
    }

    function setTreasury(address treasury) external onlyOwner {
        sodiumTreasury = treasury;
        emit TreasuryUpdated(treasury);
    }

    function setValidator(address validator_) external onlyOwner {
        validator = validator_;
        emit ValidatorUpdated(validator);
    }

    function setBlackList(
        address[] calldata collections_,
        uint256[] calldata tokenIds_,
        bool[] calldata values_
    ) external onlyOwner {
        uint256 i = 0;

        for (; i < collections_.length; i++) {
            blackList[collections_[i]][tokenIds_[i]] = values_[i];

            unchecked {
                ++i;
            }
        }
    }

    function _processPoolRequest(
        uint256 loanId_,
        Loan storage loan_,
        PoolRequest memory poolRequest_
    ) internal {
        uint256 APR = ISodiumPrivatePool(poolRequest_.pool).borrow(
            loan_.tokenAddress,
            loan_.borrower,
            poolRequest_.amount,
            loan_.totalLiquidityAdded,
            loan_.length,
            poolRequest_.oracleMessage
        );

        loan_.orderTypes.push(1);
        loan_.principals.push(poolRequest_.amount);
        loan_.lenders.push(address(poolRequest_.pool));
        loan_.APRs.push(APR);
        loan_.timestamps.push(block.timestamp);
        loan_.totalLiquidityAdded += poolRequest_.amount;

        emit BorrowFromPoolMade(loanId_, poolRequest_.pool, poolRequest_.amount, APR);
    }

    function _processMetaContribution(
        Loan storage loan_,
        MetaContribution calldata contribution_,
        uint256 amount_,
        uint256 id_
    ) internal returns (uint256) {
        require(amount_ <= contribution_.totalFundsOffered, "Sodium: amount is bigger than offered");
        require(
            amount_ + loan_.totalLiquidityAdded <= contribution_.liquidityLimit,
            "Sodium: contribution limit exceeded"
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                META_CONTRIBUTION_TYPE_HASH,
                id_,
                contribution_.totalFundsOffered,
                contribution_.APR,
                contribution_.liquidityLimit,
                contribution_.nonce
            )
        );
        bytes32 digest = _hashTypedDataV4(hashStruct);

        address lender = ECDSAUpgradeable.recover(digest, contribution_.v, contribution_.r, contribution_.s);

        // Avoid meta-contribution replay via lender nonce
        require(contribution_.nonce == nonces[id_][lender], "Sodium: nonce is repeated");
        nonces[id_][lender]++;

        loan_.orderTypes.push(0);
        loan_.principals.push(amount_);
        loan_.lenders.push(lender);
        loan_.APRs.push(contribution_.APR);
        loan_.timestamps.push(block.timestamp);
        loan_.totalLiquidityAdded += amount_;

        _transferFromWETH(lender, msg.sender, amount_);

        emit FundsAdded(id_, lender, amount_, contribution_.APR);
        return amount_;
    }

    function _executeLoanRequest(
        PoolRequest[] memory poolRequests_,
        uint256 loanLength_,
        uint256 requestId,
        uint256 tokenId,
        address requester,
        address tokenAddress
    ) internal returns (address) {
        require(!blackList[tokenAddress][tokenId], "Sodium: token is blacklisted");
        address wallet = eoaToWallet[requester];

        if (wallet == address(0)) {
            wallet = sodiumWalletFactory.createWallet(requester);
            eoaToWallet[requester] = wallet;
        }

        emit RequestMade(requestId, requester, tokenAddress, tokenId, loanLength_);

        loans[requestId] = Loan(
            loanLength_,
            0,
            0,
            tokenId,
            0,
            tokenAddress,
            requester,
            0,
            new uint8[](0),
            new address[](0),
            new uint256[](0),
            new uint256[](0),
            new uint256[](0)
        );

        Loan storage loan = loans[requestId];

        if (poolRequests_.length != 0) {
            uint256 end = loan.length + block.timestamp;
            loan.endDate = end;
            loan.auctionEndDate = end + auctionLengthInSeconds;

            uint256 i = 0;
            for (; i < poolRequests_.length; ) {
                _processPoolRequest(requestId, loan, poolRequests_[i]);

                unchecked {
                    ++i;
                }
            }
        }

        return wallet;
    }

    function _preBorrowLogic(Loan storage loan) internal {
        require(msg.sender == loan.borrower, "Sodium: msg.sender is not borrower");

        if (loan.lenders.length == 0) {
            uint256 end = loan.length + block.timestamp;

            loan.endDate = end;
            loan.auctionEndDate = end + auctionLengthInSeconds;
        } else {
            require(block.timestamp < loan.endDate, "Sodium: loan is finished");
        }
    }

    function _checkValidation(MetaContribution[] calldata metaContributions, Validation calldata validation)
        internal
        view
    {
        bytes32 hash = keccak256(abi.encode(validation.deadline, metaContributions));
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), validation.v, validation.r, validation.s);

        require(signer == validator, "Sodium: signer is not validator");
        require(block.timestamp <= validation.deadline, "Sodium: validation deadline exceeded");
    }

    function _auctionCleanup(uint256 auctionId, address winner) internal {
        _transferCollateral(
            loans[auctionId].tokenAddress,
            loans[auctionId].tokenId,
            eoaToWallet[loans[auctionId].borrower],
            winner
        );

        delete auctions[auctionId];
        delete loans[auctionId];
    }

    function _transferCollateral(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to
    ) internal virtual;

    function _transferFromWETH(
        address from,
        address to,
        uint256 amount
    ) internal {
        bool sent = WETH.transferFrom(from, to, amount);
        require(sent, "Sodium: failed to send");
    }

    function _transferWETH(address to, uint256 amount) internal {
        bool sent = WETH.transfer(to, amount);
        require(sent, "Sodium: failed to send");
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {}
}