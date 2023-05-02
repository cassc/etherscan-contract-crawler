// SPDX-License-Identifier: BSL 1.1 - Blend (c) Non Fungible Trading Ltd.
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import "./CalculationHelpers.sol";
import "./lib/Structs.sol";
import "./OfferController.sol";
import "./interfaces/IBlend.sol";
import "./interfaces/IBlurPool.sol";

interface IExchange {
    function execute(Input calldata sell, Input calldata buy) external payable;
}

contract Blend is IBlend, OfferController, UUPSUpgradeable {
    uint256 private constant _BASIS_POINTS = 10_000;
    uint256 private constant _MAX_AUCTION_DURATION = 432_000;
    IBlurPool private immutable pool;
    uint256 private _nextLienId;

    mapping(uint256 => bytes32) public liens;
    mapping(bytes32 => uint256) public amountTaken;

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    constructor(IBlurPool _pool) {
        pool = _pool;
        _disableInitializers();
    }

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    /*//////////////////////////////////////////////////
                    BORROW FLOWS
    //////////////////////////////////////////////////*/

    /**
     * @notice Verifies and takes loan offer; then transfers loan and collateral assets
     * @param offer Loan offer
     * @param signature Lender offer signature
     * @param loanAmount Loan amount in ETH
     * @param collateralTokenId Token id to provide as collateral
     * @return lienId New lien id
     */
    function borrow(
        LoanOffer calldata offer,
        bytes calldata signature,
        uint256 loanAmount,
        uint256 collateralTokenId
    ) external returns (uint256 lienId) {
        lienId = _borrow(offer, signature, loanAmount, collateralTokenId);

        /* Lock collateral token. */
        offer.collection.safeTransferFrom(msg.sender, address(this), collateralTokenId);

        /* Transfer loan to borrower. */
        pool.transferFrom(offer.lender, msg.sender, loanAmount);
    }

    /**
     * @notice Repays loan and retrieves collateral
     * @param lien Lien preimage
     * @param lienId Lien id
     */
    function repay(
        Lien calldata lien,
        uint256 lienId
    ) external validateLien(lien, lienId) lienIsActive(lien) {
        uint256 debt = _repay(lien, lienId);

        /* Return NFT to borrower. */
        lien.collection.safeTransferFrom(address(this), lien.borrower, lien.tokenId);

        /* Repay loan to lender. */
        pool.transferFrom(msg.sender, lien.lender, debt);
    }

    /**
     * @notice Verifies and takes loan offer; creates new lien
     * @param offer Loan offer
     * @param signature Lender offer signature
     * @param loanAmount Loan amount in ETH
     * @param collateralTokenId Token id to provide as collateral
     * @return lienId New lien id
     */
    function _borrow(
        LoanOffer calldata offer,
        bytes calldata signature,
        uint256 loanAmount,
        uint256 collateralTokenId
    ) internal returns (uint256 lienId) {
        if (offer.auctionDuration > _MAX_AUCTION_DURATION) {
            revert InvalidAuctionDuration();
        }

        Lien memory lien = Lien({
            lender: offer.lender,
            borrower: msg.sender,
            collection: offer.collection,
            tokenId: collateralTokenId,
            amount: loanAmount,
            startTime: block.timestamp,
            rate: offer.rate,
            auctionStartBlock: 0,
            auctionDuration: offer.auctionDuration
        });

        /* Create lien. */
        unchecked {
            liens[lienId = _nextLienId++] = keccak256(abi.encode(lien));
        }

        /* Take the loan offer. */
        _takeLoanOffer(offer, signature, lien, lienId);
    }

    /**
     * @notice Computes the current debt repayment and burns the lien
     * @dev Does not transfer assets
     * @param lien Lien preimage
     * @param lienId Lien id
     * @return debt Current amount of debt owed on the lien
     */
    function _repay(Lien calldata lien, uint256 lienId) internal returns (uint256 debt) {
        debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        delete liens[lienId];

        emit Repay(lienId, address(lien.collection));
    }

    /**
     * @notice Verifies and takes loan offer
     * @dev Does not transfer loan and collateral assets; does not update lien hash
     * @param offer Loan offer
     * @param signature Lender offer signature
     * @param lien Lien preimage
     * @param lienId Lien id
     */
    function _takeLoanOffer(
        LoanOffer calldata offer,
        bytes calldata signature,
        Lien memory lien,
        uint256 lienId
    ) internal {
        bytes32 hash = _hashOffer(offer);

        _validateOffer(
            hash,
            offer.lender,
            offer.oracle,
            signature,
            offer.expirationTime,
            offer.salt
        );

        if (offer.rate > _LIQUIDATION_THRESHOLD) {
            revert RateTooHigh();
        }
        if (lien.amount > offer.maxAmount || lien.amount < offer.minAmount) {
            revert InvalidLoan();
        }
        uint256 _amountTaken = amountTaken[hash];
        if (offer.totalAmount - _amountTaken < lien.amount) {
            revert InsufficientOffer();
        }

        unchecked {
            amountTaken[hash] = _amountTaken + lien.amount;
        }

        emit LoanOfferTaken(
            hash,
            lienId,
            address(offer.collection),
            lien.lender,
            lien.borrower,
            lien.amount,
            lien.rate,
            lien.tokenId,
            lien.auctionDuration
        );
    }

    /*//////////////////////////////////////////////////
                    REFINANCING FLOWS
    //////////////////////////////////////////////////*/

    /**
     * @notice Starts Dutch Auction on lien ownership
     * @dev Must be called by lien owner
     * @param lienId Lien token id
     */
    function startAuction(Lien calldata lien, uint256 lienId) external validateLien(lien, lienId) {
        if (msg.sender != lien.lender) {
            revert Unauthorized();
        }

        /* Cannot start if auction has already started. */
        if (lien.auctionStartBlock != 0) {
            revert AuctionIsActive();
        }

        /* Add auction start block to lien. */
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: lien.borrower,
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    amount: lien.amount,
                    startTime: lien.startTime,
                    rate: lien.rate,
                    auctionStartBlock: block.number,
                    auctionDuration: lien.auctionDuration
                })
            )
        );

        emit StartAuction(lienId, address(lien.collection));
    }

    /**
     * @notice Seizes collateral from defaulted lien, skipping liens that are not defaulted
     * @param lienPointers List of lien, lienId pairs
     */
    function seize(LienPointer[] calldata lienPointers) external {
        uint256 length = lienPointers.length;
        for (uint256 i; i < length; ) {
            Lien calldata lien = lienPointers[i].lien;
            uint256 lienId = lienPointers[i].lienId;

            if (msg.sender != lien.lender) {
                revert Unauthorized();
            }
            if (!_validateLien(lien, lienId)) {
                revert InvalidLien();
            }

            /* Check that the auction has ended and lien is defaulted. */
            if (_lienIsDefaulted(lien)) {
                delete liens[lienId];

                /* Seize collateral to lender. */
                lien.collection.safeTransferFrom(address(this), lien.lender, lien.tokenId);

                emit Seize(lienId, address(lien.collection));
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Refinances to different loan amount and repays previous loan
     * @dev Must be called by lender; previous loan must be repaid with interest
     * @param lien Lien struct
     * @param lienId Lien id
     * @param offer Loan offer
     * @param signature Offer signatures
     */
    function refinance(
        Lien calldata lien,
        uint256 lienId,
        LoanOffer calldata offer,
        bytes calldata signature
    ) external validateLien(lien, lienId) lienIsActive(lien) {
        if (msg.sender != lien.lender) {
            revert Unauthorized();
        }

        /* Interest rate must be at least as good as current. */
        if (offer.rate > lien.rate || offer.auctionDuration != lien.auctionDuration) {
            revert InvalidRefinance();
        }

        uint256 debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        _refinance(lien, lienId, debt, offer, signature);

        /* Repay initial loan. */
        pool.transferFrom(offer.lender, lien.lender, debt);
    }

    /**
     * @notice Refinance lien in auction at the current debt amount where the interest rate ceiling increases over time
     * @dev Interest rate must be lower than the interest rate ceiling
     * @param lien Lien struct
     * @param lienId Lien token id
     * @param rate Interest rate (in bips)
     * @dev Formula: https://www.desmos.com/calculator/urasr71dhb
     */
    function refinanceAuction(
        Lien calldata lien,
        uint256 lienId,
        uint256 rate
    ) external validateLien(lien, lienId) auctionIsActive(lien) {
        /* Rate must be below current rate limit. */
        uint256 rateLimit = CalculationHelpers.calcRefinancingAuctionRate(
            lien.auctionStartBlock,
            lien.auctionDuration,
            lien.rate
        );
        if (rate > rateLimit) {
            revert RateTooHigh();
        }

        uint256 debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        /* Reset the lien with the new lender and interest rate. */
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: msg.sender, // set new lender
                    borrower: lien.borrower,
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    amount: debt, // new loan begins with previous debt
                    startTime: block.timestamp,
                    rate: rate,
                    auctionStartBlock: 0, // close the auction
                    auctionDuration: lien.auctionDuration
                })
            )
        );

        emit Refinance(
            lienId,
            address(lien.collection),
            msg.sender,
            debt,
            rate,
            lien.auctionDuration
        );

        /* Repay the initial loan. */
        pool.transferFrom(msg.sender, lien.lender, debt);
    }

    /**
     * @notice Refinances to different loan amount and repays previous loan
     * @param lien Lien struct
     * @param lienId Lien id
     * @param offer Loan offer
     * @param signature Offer signatures
     */
    function refinanceAuctionByOther(
        Lien calldata lien,
        uint256 lienId,
        LoanOffer calldata offer,
        bytes calldata signature
    ) external validateLien(lien, lienId) auctionIsActive(lien) {
        /* Rate must be below current rate limit and auction duration must be the same. */
        uint256 rateLimit = CalculationHelpers.calcRefinancingAuctionRate(
            lien.auctionStartBlock,
            lien.auctionDuration,
            lien.rate
        );
        if (offer.rate > rateLimit || offer.auctionDuration != lien.auctionDuration) {
            revert InvalidRefinance();
        }

        uint256 debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        _refinance(lien, lienId, debt, offer, signature);

        /* Repay initial loan. */
        pool.transferFrom(offer.lender, lien.lender, debt);
    }

    /**
     * @notice Refinances to different loan amount and repays previous loan
     * @dev Must be called by borrower; previous loan must be repaid with interest
     * @param lien Lien struct
     * @param lienId Lien id
     * @param loanAmount New loan amount
     * @param offer Loan offer
     * @param signature Offer signatures
     */
    function borrowerRefinance(
        Lien calldata lien,
        uint256 lienId,
        uint256 loanAmount,
        LoanOffer calldata offer,
        bytes calldata signature
    ) external validateLien(lien, lienId) lienIsActive(lien) {
        if (msg.sender != lien.borrower) {
            revert Unauthorized();
        }
        if (offer.auctionDuration > _MAX_AUCTION_DURATION) {
            revert InvalidAuctionDuration();
        }

        _refinance(lien, lienId, loanAmount, offer, signature);

        uint256 debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        if (loanAmount >= debt) {
            /* If new loan is more than the previous, repay the initial loan and send the remaining to the borrower. */
            pool.transferFrom(offer.lender, lien.lender, debt);
            unchecked {
                pool.transferFrom(offer.lender, lien.borrower, loanAmount - debt);
            }
        } else {
            /* If new loan is less than the previous, borrower must supply the difference to repay the initial loan. */
            pool.transferFrom(offer.lender, lien.lender, loanAmount);
            unchecked {
                pool.transferFrom(lien.borrower, lien.lender, debt - loanAmount);
            }
        }
    }

    function _refinance(
        Lien calldata lien,
        uint256 lienId,
        uint256 loanAmount,
        LoanOffer calldata offer,
        bytes calldata signature
    ) internal {
        if (lien.collection != offer.collection) {
            revert CollectionsDoNotMatch();
        }

        /* Update lien with new loan details. */
        Lien memory newLien = Lien({
            lender: offer.lender, // set new lender
            borrower: lien.borrower,
            collection: lien.collection,
            tokenId: lien.tokenId,
            amount: loanAmount,
            startTime: block.timestamp,
            rate: offer.rate,
            auctionStartBlock: 0, // close the auction
            auctionDuration: offer.auctionDuration
        });
        liens[lienId] = keccak256(abi.encode(newLien));

        /* Take the loan offer. */
        _takeLoanOffer(offer, signature, newLien, lienId);

        emit Refinance(
            lienId,
            address(offer.collection),
            offer.lender,
            loanAmount,
            offer.rate,
            offer.auctionDuration
        );
    }

    /*/////////////////////////////////////////////////////////////
                          MARKETPLACE FLOWS
    /////////////////////////////////////////////////////////////*/

    IExchange private constant _EXCHANGE = IExchange(0x000000000000Ad05Ccc4F10045630fb830B95127);
    address private constant _SELL_MATCHING_POLICY = 0x0000000000daB4A563819e8fd93dbA3b25BC3495;
    address private constant _BID_MATCHING_POLICY = 0x0000000000b92D5d043FaF7CECf7E2EE6aaeD232;
    address private constant _DELEGATE = 0x00000000000111AbE46ff893f3B2fdF1F759a8A8;

    /**
     * @notice Purchase an NFT and use as collateral for a loan
     * @param offer Loan offer to take
     * @param signature Lender offer signature
     * @param loanAmount Loan amount in ETH
     * @param execution Marketplace execution data
     * @return lienId Lien id
     */
    function buyToBorrow(
        LoanOffer calldata offer,
        bytes calldata signature,
        uint256 loanAmount,
        Execution calldata execution
    ) public returns (uint256 lienId) {
        if (execution.makerOrder.order.trader == address(this)) {
            revert Unauthorized();
        }
        if (offer.auctionDuration > _MAX_AUCTION_DURATION) {
            revert InvalidAuctionDuration();
        }

        uint256 collateralTokenId = execution.makerOrder.order.tokenId;
        uint256 price = execution.makerOrder.order.price;

        /* Create lien. */
        Lien memory lien = Lien({
            lender: offer.lender,
            borrower: msg.sender,
            collection: offer.collection,
            tokenId: collateralTokenId,
            amount: loanAmount,
            startTime: block.timestamp,
            rate: offer.rate,
            auctionStartBlock: 0,
            auctionDuration: offer.auctionDuration
        });
        unchecked {
            liens[lienId = _nextLienId++] = keccak256(abi.encode(lien));
        }

        /* Take the loan offer. */
        _takeLoanOffer(offer, signature, lien, lienId);

        /* Transfer funds. */
        /* Need to retrieve the ETH to funds the marketplace execution. */
        if (loanAmount < price) {
            /* Take funds from lender. */
            pool.withdrawFrom(offer.lender, address(this), loanAmount);

            /* Supplement difference from borrower. */
            unchecked {
                pool.withdrawFrom(msg.sender, address(this), price - loanAmount);
            }
        } else {
            /* Take funds from lender. */
            pool.withdrawFrom(offer.lender, address(this), price);

            /* Send surplus to borrower. */
            unchecked {
                pool.transferFrom(offer.lender, msg.sender, loanAmount - price);
            }
        }

        /* Create the buy side order coming from Blend. */
        Order memory buyOrder = Order({
            trader: address(this),
            side: Side.Buy,
            matchingPolicy: _SELL_MATCHING_POLICY,
            collection: address(offer.collection),
            tokenId: collateralTokenId,
            amount: 1,
            paymentToken: address(0),
            price: price,
            listingTime: execution.makerOrder.order.listingTime + 1, // listingTime determines maker/taker
            expirationTime: type(uint256).max,
            fees: new Fee[](0),
            salt: uint160(execution.makerOrder.order.trader), // prevent reused order hash
            extraParams: "\x01" // require oracle signature
        });
        Input memory buy = Input({
            order: buyOrder,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            extraSignature: execution.extraSignature,
            signatureVersion: SignatureVersion.Single,
            blockNumber: execution.blockNumber
        });

        /* Execute order using ETH currently in contract. */
        _EXCHANGE.execute{ value: price }(execution.makerOrder, buy);
    }

    /**
     * @notice Purchase a locked NFT; repay the initial loan; lock the token as collateral for a new loan
     * @param lien Lien preimage struct
     * @param sellInput Sell offer and signature
     * @param loanInput Loan offer and signature
     * @return lienId Lien id
     */
    function buyToBorrowLocked(
        Lien calldata lien,
        SellInput calldata sellInput,
        LoanInput calldata loanInput,
        uint256 loanAmount
    )
        public
        validateLien(lien, sellInput.offer.lienId)
        lienIsActive(lien)
        returns (uint256 lienId)
    {
        if (lien.collection != loanInput.offer.collection) {
            revert CollectionsDoNotMatch();
        }

        (uint256 priceAfterFees, uint256 debt) = _buyLocked(
            lien,
            sellInput.offer,
            sellInput.signature
        );

        lienId = _borrow(loanInput.offer, loanInput.signature, loanAmount, lien.tokenId);

        /* Transfer funds. */
        /* Need to repay the original loan and payout any surplus from the sell or loan funds. */
        if (loanAmount < debt) {
            /* loanAmount < debt < priceAfterFees */

            /* Repay loan with funds from new lender to old lender. */
            pool.transferFrom(loanInput.offer.lender, lien.lender, loanAmount); // doesn't cover debt

            unchecked {
                /* Supplement difference from new borrower. */
                pool.transferFrom(msg.sender, lien.lender, debt - loanAmount); // cover rest of debt

                /* Send rest of sell funds to borrower. */
                pool.transferFrom(msg.sender, sellInput.offer.borrower, priceAfterFees - debt);
            }
        } else if (loanAmount < priceAfterFees) {
            /* debt < loanAmount < priceAfterFees */

            /* Repay loan with funds from new lender to old lender. */
            pool.transferFrom(loanInput.offer.lender, lien.lender, debt);

            unchecked {
                /* Send rest of loan from new lender to old borrower. */
                pool.transferFrom(
                    loanInput.offer.lender,
                    sellInput.offer.borrower,
                    loanAmount - debt
                );

                /* Send rest of sell funds from new borrower to old borrower. */
                pool.transferFrom(
                    msg.sender,
                    sellInput.offer.borrower,
                    priceAfterFees - loanAmount
                );
            }
        } else {
            /* debt < priceAfterFees < loanAmount */

            /* Repay loan with funds from new lender to old lender. */
            pool.transferFrom(loanInput.offer.lender, lien.lender, debt);

            unchecked {
                /* Send rest of sell funds from new lender to old borrower. */
                pool.transferFrom(
                    loanInput.offer.lender,
                    sellInput.offer.borrower,
                    priceAfterFees - debt
                );

                /* Send rest of loan from new lender to new borrower. */
                pool.transferFrom(loanInput.offer.lender, msg.sender, loanAmount - priceAfterFees);
            }
        }
    }

    /**
     * @notice Purchases a locked NFT and uses the funds to repay the loan
     * @param lien Lien preimage
     * @param offer Sell offer
     * @param signature Lender offer signature
     */
    function buyLocked(
        Lien calldata lien,
        SellOffer calldata offer,
        bytes calldata signature
    ) public validateLien(lien, offer.lienId) lienIsActive(lien) {
        (uint256 priceAfterFees, uint256 debt) = _buyLocked(lien, offer, signature);

        /* Send token to buyer. */
        lien.collection.safeTransferFrom(address(this), msg.sender, lien.tokenId);

        /* Repay lender. */
        pool.transferFrom(msg.sender, lien.lender, debt);

        /* Send surplus to borrower. */
        unchecked {
            pool.transferFrom(msg.sender, lien.borrower, priceAfterFees - debt);
        }
    }

    /**
     * @notice Takes a bid on a locked NFT and use the funds to repay the lien
     * @dev Must be called by the borrower
     * @param lien Lien preimage
     * @param lienId Lien id
     * @param execution Marketplace execution data
     */
    function takeBid(
        Lien calldata lien,
        uint256 lienId,
        Execution calldata execution
    ) external validateLien(lien, lienId) lienIsActive(lien) {
        if (execution.makerOrder.order.trader == address(this) || msg.sender != lien.borrower) {
            revert Unauthorized();
        }

        /* Repay loan with funds received from the sale. */
        uint256 debt = _repay(lien, lienId);

        /* Create sell side order from Blend. */
        Order memory sellOrder = Order({
            trader: address(this),
            side: Side.Sell,
            matchingPolicy: _BID_MATCHING_POLICY,
            collection: address(lien.collection),
            tokenId: lien.tokenId,
            amount: 1,
            paymentToken: address(pool),
            price: execution.makerOrder.order.price,
            listingTime: execution.makerOrder.order.listingTime + 1, // listingTime determines maker/taker
            expirationTime: type(uint256).max,
            fees: new Fee[](0),
            salt: lienId, // prevent reused order hash
            extraParams: "\x01" // require oracle signature
        });
        Input memory sell = Input({
            order: sellOrder,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            extraSignature: execution.extraSignature,
            signatureVersion: SignatureVersion.Single,
            blockNumber: execution.blockNumber
        });

        /* Execute marketplace order. */
        uint256 balanceBefore = pool.balanceOf(address(this));
        lien.collection.approve(_DELEGATE, lien.tokenId);
        _EXCHANGE.execute(sell, execution.makerOrder);

        /* Determine the funds received from the sale (after fees). */
        uint256 amountReceivedFromSale = pool.balanceOf(address(this)) - balanceBefore;
        if (amountReceivedFromSale < debt) {
            revert InvalidRepayment();
        }

        /* Repay lender. */
        pool.transferFrom(address(this), lien.lender, debt);

        /* Send surplus to borrower. */
        unchecked {
            pool.transferFrom(address(this), lien.borrower, amountReceivedFromSale - debt);
        }
    }

    /**
     * @notice Verify and take sell offer for token locked in lien; use the funds to repay the debt on the lien
     * @dev Does not transfer assets
     * @param lien Lien preimage
     * @param offer Loan offer
     * @param signature Loan offer signature
     * @return priceAfterFees Price of the token (after fees), debt Current debt amount
     */
    function _buyLocked(
        Lien calldata lien,
        SellOffer calldata offer,
        bytes calldata signature
    ) internal returns (uint256 priceAfterFees, uint256 debt) {
        if (lien.borrower != offer.borrower) {
            revert Unauthorized();
        }

        priceAfterFees = _takeSellOffer(offer, signature);

        /* Repay loan with funds received from the sale. */
        debt = _repay(lien, offer.lienId);
        if (priceAfterFees < debt) {
            revert InvalidRepayment();
        }

        emit BuyLocked(
            offer.lienId,
            address(lien.collection),
            msg.sender,
            lien.borrower,
            lien.tokenId
        );
    }

    /**
     * @notice Validates, fulfills, and transfers fees on sell offer
     * @param sellOffer Sell offer
     * @param sellSignature Sell offer signature
     */
    function _takeSellOffer(
        SellOffer calldata sellOffer,
        bytes calldata sellSignature
    ) internal returns (uint256 priceAfterFees) {
        _validateOffer(
            _hashSellOffer(sellOffer),
            sellOffer.borrower,
            sellOffer.oracle,
            sellSignature,
            sellOffer.expirationTime,
            sellOffer.salt
        );

        /* Mark the sell offer as fulfilled. */
        cancelledOrFulfilled[sellOffer.borrower][sellOffer.salt] = 1;

        /* Transfer fees. */
        uint256 totalFees = _transferFees(sellOffer.fees, msg.sender, sellOffer.price);
        unchecked {
            priceAfterFees = sellOffer.price - totalFees;
        }
    }

    function _transferFees(
        Fee[] calldata fees,
        address from,
        uint256 price
    ) internal returns (uint256 totalFee) {
        uint256 feesLength = fees.length;
        for (uint256 i = 0; i < feesLength; ) {
            uint256 fee = (price * fees[i].rate) / _BASIS_POINTS;
            pool.transferFrom(from, fees[i].recipient, fee);
            totalFee += fee;
            unchecked {
                ++i;
            }
        }
        if (totalFee > price) {
            revert FeesTooHigh();
        }
    }

    receive() external payable {
        if (msg.sender != address(pool)) {
            revert Unauthorized();
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*/////////////////////////////////////////////////////////////
                          CALCULATION HELPERS
    /////////////////////////////////////////////////////////////*/

    int256 private constant _YEAR_WAD = 365 days * 1e18;
    uint256 private constant _LIQUIDATION_THRESHOLD = 100_000;

    /*/////////////////////////////////////////////////////////////
                        PAYABLE WRAPPERS
    /////////////////////////////////////////////////////////////*/

    /**
     * @notice buyToBorrow wrapper that deposits ETH to pool
     */
    function buyToBorrowETH(
        LoanOffer calldata offer,
        bytes calldata signature,
        uint256 loanAmount,
        Execution calldata execution
    ) external payable returns (uint256 lienId) {
        pool.deposit{ value: msg.value }(msg.sender);
        return buyToBorrow(offer, signature, loanAmount, execution);
    }

    /**
     * @notice buyToBorrowLocked wrapper that deposits ETH to pool
     */
    function buyToBorrowLockedETH(
        Lien calldata lien,
        SellInput calldata sellInput,
        LoanInput calldata loanInput,
        uint256 loanAmount
    ) external payable returns (uint256 lienId) {
        pool.deposit{ value: msg.value }(msg.sender);
        return buyToBorrowLocked(lien, sellInput, loanInput, loanAmount);
    }

    /**
     * @notice buyLocked wrapper that deposits ETH to pool
     */
    function buyLockedETH(
        Lien calldata lien,
        SellOffer calldata offer,
        bytes calldata signature
    ) external payable {
        pool.deposit{ value: msg.value }(msg.sender);
        return buyLocked(lien, offer, signature);
    }

    /*/////////////////////////////////////////////////////////////
                        VALIDATION MODIFIERS
    /////////////////////////////////////////////////////////////*/

    modifier validateLien(Lien calldata lien, uint256 lienId) {
        if (!_validateLien(lien, lienId)) {
            revert InvalidLien();
        }

        _;
    }

    modifier lienIsActive(Lien calldata lien) {
        if (_lienIsDefaulted(lien)) {
            revert LienIsDefaulted();
        }

        _;
    }

    modifier auctionIsActive(Lien calldata lien) {
        if (!_auctionIsActive(lien)) {
            revert AuctionIsNotActive();
        }

        _;
    }

    function _validateLien(Lien calldata lien, uint256 lienId) internal view returns (bool) {
        return liens[lienId] == keccak256(abi.encode(lien));
    }

    function _lienIsDefaulted(Lien calldata lien) internal view returns (bool) {
        return
            lien.auctionStartBlock != 0 &&
            lien.auctionStartBlock + lien.auctionDuration < block.number;
    }

    function _auctionIsActive(Lien calldata lien) internal view returns (bool) {
        return
            lien.auctionStartBlock != 0 &&
            lien.auctionStartBlock + lien.auctionDuration >= block.number;
    }
}