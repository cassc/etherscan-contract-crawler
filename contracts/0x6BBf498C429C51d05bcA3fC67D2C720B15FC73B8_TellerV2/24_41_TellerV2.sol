pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// Contracts
import "./ProtocolFee.sol";
import "./TellerV2Storage.sol";
import "./TellerV2Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

// Interfaces
import "./interfaces/IMarketRegistry.sol";
import "./interfaces/IReputationManager.sol";
import "./interfaces/ITellerV2.sol";
import { Collateral } from "./interfaces/escrow/ICollateralEscrowV1.sol";

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/NumbersLib.sol";
import { BokkyPooBahsDateTimeLibrary as BPBDTL } from "./libraries/DateTimeLib.sol";
import { V2Calculations, PaymentCycleType } from "./libraries/V2Calculations.sol";

/* Errors */
/**
 * @notice This error is reverted when the action isn't allowed
 * @param bidId The id of the bid.
 * @param action The action string (i.e: 'repayLoan', 'cancelBid', 'etc)
 * @param message The message string to return to the user explaining why the tx was reverted
 */
error ActionNotAllowed(uint256 bidId, string action, string message);

/**
 * @notice This error is reverted when repayment amount is less than the required minimum
 * @param bidId The id of the bid the borrower is attempting to repay.
 * @param payment The payment made by the borrower
 * @param minimumOwed The minimum owed value
 */
error PaymentNotMinimum(uint256 bidId, uint256 payment, uint256 minimumOwed);

contract TellerV2 is
    ITellerV2,
    OwnableUpgradeable,
    ProtocolFee,
    PausableUpgradeable,
    TellerV2Storage,
    TellerV2Context
{
    using Address for address;
    using SafeERC20 for ERC20;
    using NumbersLib for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /** Events */

    /**
     * @notice This event is emitted when a new bid is submitted.
     * @param bidId The id of the bid submitted.
     * @param borrower The address of the bid borrower.
     * @param metadataURI URI for additional bid information as part of loan bid.
     */
    event SubmittedBid(
        uint256 indexed bidId,
        address indexed borrower,
        address receiver,
        bytes32 indexed metadataURI
    );

    /**
     * @notice This event is emitted when a bid has been accepted by a lender.
     * @param bidId The id of the bid accepted.
     * @param lender The address of the accepted bid lender.
     */
    event AcceptedBid(uint256 indexed bidId, address indexed lender);

    /**
     * @notice This event is emitted when a previously submitted bid has been cancelled.
     * @param bidId The id of the cancelled bid.
     */
    event CancelledBid(uint256 indexed bidId);

    /**
     * @notice This event is emitted when market owner has cancelled a pending bid in their market.
     * @param bidId The id of the bid funded.
     *
     * Note: The `CancelledBid` event will also be emitted.
     */
    event MarketOwnerCancelledBid(uint256 indexed bidId);

    /**
     * @notice This event is emitted when a payment is made towards an active loan.
     * @param bidId The id of the bid/loan to which the payment was made.
     */
    event LoanRepayment(uint256 indexed bidId);

    /**
     * @notice This event is emitted when a loan has been fully repaid.
     * @param bidId The id of the bid/loan which was repaid.
     */
    event LoanRepaid(uint256 indexed bidId);

    /**
     * @notice This event is emitted when a loan has been fully repaid.
     * @param bidId The id of the bid/loan which was repaid.
     */
    event LoanLiquidated(uint256 indexed bidId, address indexed liquidator);

    /**
     * @notice This event is emitted when a fee has been paid related to a bid.
     * @param bidId The id of the bid.
     * @param feeType The name of the fee being paid.
     * @param amount The amount of the fee being paid.
     */
    event FeePaid(
        uint256 indexed bidId,
        string indexed feeType,
        uint256 indexed amount
    );

    /** Modifiers */

    /**
     * @notice This modifier is used to check if the state of a bid is pending, before running an action.
     * @param _bidId The id of the bid to check the state for.
     * @param _action The desired action to run on the bid.
     */
    modifier pendingBid(uint256 _bidId, string memory _action) {
        if (bids[_bidId].state != BidState.PENDING) {
            revert ActionNotAllowed(_bidId, _action, "Bid must be pending");
        }

        _;
    }

    /**
     * @notice This modifier is used to check if the state of a loan has been accepted, before running an action.
     * @param _bidId The id of the bid to check the state for.
     * @param _action The desired action to run on the bid.
     */
    modifier acceptedLoan(uint256 _bidId, string memory _action) {
        if (bids[_bidId].state != BidState.ACCEPTED) {
            revert ActionNotAllowed(_bidId, _action, "Loan must be accepted");
        }

        _;
    }

    /** Constant Variables **/

    uint8 public constant CURRENT_CODE_VERSION = 9;

    uint32 public constant LIQUIDATION_DELAY = 86400; //ONE DAY IN SECONDS

    /** Constructor **/

    constructor(address trustedForwarder) TellerV2Context(trustedForwarder) {}

    /** External Functions **/

    /**
     * @notice Initializes the proxy.
     * @param _protocolFee The fee collected by the protocol for loan processing.
     * @param _marketRegistry The address of the market registry contract for the protocol.
     * @param _reputationManager The address of the reputation manager contract.
     * @param _lenderCommitmentForwarder The address of the lender commitment forwarder contract.
     * @param _collateralManager The address of the collateral manager contracts.
     * @param _lenderManager The address of the lender manager contract for loans on the protocol.
     */
    function initialize(
        uint16 _protocolFee,
        address _marketRegistry,
        address _reputationManager,
        address _lenderCommitmentForwarder,
        address _collateralManager,
        address _lenderManager
    ) external initializer {
        __ProtocolFee_init(_protocolFee);

        __Pausable_init();

        require(
            _lenderCommitmentForwarder.isContract(),
            "LenderCommitmentForwarder must be a contract"
        );
        lenderCommitmentForwarder = _lenderCommitmentForwarder;

        require(
            _marketRegistry.isContract(),
            "MarketRegistry must be a contract"
        );
        marketRegistry = IMarketRegistry(_marketRegistry);

        require(
            _reputationManager.isContract(),
            "ReputationManager must be a contract"
        );
        reputationManager = IReputationManager(_reputationManager);

        require(
            _collateralManager.isContract(),
            "CollateralManager must be a contract"
        );
        collateralManager = ICollateralManager(_collateralManager);

        _setLenderManager(_lenderManager);
    }

    function setLenderManager(address _lenderManager)
        external
        reinitializer(8)
        onlyOwner
    {
        _setLenderManager(_lenderManager);
    }

    function _setLenderManager(address _lenderManager)
        internal
        onlyInitializing
    {
        require(
            _lenderManager.isContract(),
            "LenderManager must be a contract"
        );
        lenderManager = ILenderManager(_lenderManager);
    }

    /**
     * @notice Gets the metadataURI for a bidId.
     * @param _bidId The id of the bid to return the metadataURI for
     * @return metadataURI_ The metadataURI for the bid, as a string.
     */
    function getMetadataURI(uint256 _bidId)
        public
        view
        returns (string memory metadataURI_)
    {
        // Check uri mapping first
        metadataURI_ = uris[_bidId];
        // If the URI is not present in the mapping
        if (
            keccak256(abi.encodePacked(metadataURI_)) ==
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 // hardcoded constant of keccak256('')
        ) {
            // Return deprecated bytes32 uri as a string
            uint256 convertedURI = uint256(bids[_bidId]._metadataURI);
            metadataURI_ = StringsUpgradeable.toHexString(convertedURI, 32);
        }
    }

    /**
     * @notice Lets the DAO/owner of the protocol to set a new reputation manager contract.
     * @param _reputationManager The new contract address.
     */
    function setReputationManager(address _reputationManager) public onlyOwner {
        reputationManager = IReputationManager(_reputationManager);
    }

    /**
     * @notice Function for a borrower to create a bid for a loan without Collateral.
     * @param _lendingToken The lending token asset requested to be borrowed.
     * @param _marketplaceId The unique id of the marketplace for the bid.
     * @param _principal The principal amount of the loan bid.
     * @param _duration The recurrent length of time before which a payment is due.
     * @param _APR The proposed interest rate for the loan bid.
     * @param _metadataURI The URI for additional borrower loan information as part of loan bid.
     * @param _receiver The address where the loan amount will be sent to.
     */
    function submitBid(
        address _lendingToken,
        uint256 _marketplaceId,
        uint256 _principal,
        uint32 _duration,
        uint16 _APR,
        string calldata _metadataURI,
        address _receiver
    ) public override whenNotPaused returns (uint256 bidId_) {
        bidId_ = _submitBid(
            _lendingToken,
            _marketplaceId,
            _principal,
            _duration,
            _APR,
            _metadataURI,
            _receiver
        );
    }

    /**
     * @notice Function for a borrower to create a bid for a loan with Collateral.
     * @param _lendingToken The lending token asset requested to be borrowed.
     * @param _marketplaceId The unique id of the marketplace for the bid.
     * @param _principal The principal amount of the loan bid.
     * @param _duration The recurrent length of time before which a payment is due.
     * @param _APR The proposed interest rate for the loan bid.
     * @param _metadataURI The URI for additional borrower loan information as part of loan bid.
     * @param _receiver The address where the loan amount will be sent to.
     * @param _collateralInfo Additional information about the collateral asset.
     */
    function submitBid(
        address _lendingToken,
        uint256 _marketplaceId,
        uint256 _principal,
        uint32 _duration,
        uint16 _APR,
        string calldata _metadataURI,
        address _receiver,
        Collateral[] calldata _collateralInfo
    ) public override whenNotPaused returns (uint256 bidId_) {
        bidId_ = _submitBid(
            _lendingToken,
            _marketplaceId,
            _principal,
            _duration,
            _APR,
            _metadataURI,
            _receiver
        );

        bool validation = collateralManager.commitCollateral(
            bidId_,
            _collateralInfo
        );

        require(
            validation == true,
            "Collateral balance could not be validated"
        );
    }

    function _submitBid(
        address _lendingToken,
        uint256 _marketplaceId,
        uint256 _principal,
        uint32 _duration,
        uint16 _APR,
        string calldata _metadataURI,
        address _receiver
    ) internal virtual returns (uint256 bidId_) {
        address sender = _msgSenderForMarket(_marketplaceId);

        (bool isVerified, ) = marketRegistry.isVerifiedBorrower(
            _marketplaceId,
            sender
        );

        require(isVerified, "Not verified borrower");

        require(
            !marketRegistry.isMarketClosed(_marketplaceId),
            "Market is closed"
        );

        // Set response bid ID.
        bidId_ = bidId;

        // Create and store our bid into the mapping
        Bid storage bid = bids[bidId];
        bid.borrower = sender;
        bid.receiver = _receiver != address(0) ? _receiver : bid.borrower;
        bid.marketplaceId = _marketplaceId;
        bid.loanDetails.lendingToken = ERC20(_lendingToken);
        bid.loanDetails.principal = _principal;
        bid.loanDetails.loanDuration = _duration;
        bid.loanDetails.timestamp = uint32(block.timestamp);

        // Set payment cycle type based on market setting (custom or monthly)
        (bid.terms.paymentCycle, bidPaymentCycleType[bidId]) = marketRegistry
            .getPaymentCycle(_marketplaceId);

        bid.terms.APR = _APR;

        bidDefaultDuration[bidId] = marketRegistry.getPaymentDefaultDuration(
            _marketplaceId
        );

        bidExpirationTime[bidId] = marketRegistry.getBidExpirationTime(
            _marketplaceId
        );

        bid.paymentType = marketRegistry.getPaymentType(_marketplaceId);

        bid.terms.paymentCycleAmount = V2Calculations
            .calculatePaymentCycleAmount(
                bid.paymentType,
                bidPaymentCycleType[bidId],
                _principal,
                _duration,
                bid.terms.paymentCycle,
                _APR
            );

        uris[bidId] = _metadataURI;
        bid.state = BidState.PENDING;

        emit SubmittedBid(
            bidId,
            bid.borrower,
            bid.receiver,
            keccak256(abi.encodePacked(_metadataURI))
        );

        // Store bid inside borrower bids mapping
        borrowerBids[bid.borrower].push(bidId);

        // Increment bid id counter
        bidId++;
    }

    /**
     * @notice Function for a borrower to cancel their pending bid.
     * @param _bidId The id of the bid to cancel.
     */
    function cancelBid(uint256 _bidId) external {
        if (
            _msgSenderForMarket(bids[_bidId].marketplaceId) !=
            bids[_bidId].borrower
        ) {
            revert ActionNotAllowed({
                bidId: _bidId,
                action: "cancelBid",
                message: "Only the bid owner can cancel!"
            });
        }
        _cancelBid(_bidId);
    }

    /**
     * @notice Function for a market owner to cancel a bid in the market.
     * @param _bidId The id of the bid to cancel.
     */
    function marketOwnerCancelBid(uint256 _bidId) external {
        if (
            _msgSender() !=
            marketRegistry.getMarketOwner(bids[_bidId].marketplaceId)
        ) {
            revert ActionNotAllowed({
                bidId: _bidId,
                action: "marketOwnerCancelBid",
                message: "Only the market owner can cancel!"
            });
        }
        _cancelBid(_bidId);
        emit MarketOwnerCancelledBid(_bidId);
    }

    /**
     * @notice Function for users to cancel a bid.
     * @param _bidId The id of the bid to be cancelled.
     */
    function _cancelBid(uint256 _bidId)
        internal
        virtual
        pendingBid(_bidId, "cancelBid")
    {
        // Set the bid state to CANCELLED
        bids[_bidId].state = BidState.CANCELLED;

        // Emit CancelledBid event
        emit CancelledBid(_bidId);
    }

    /**
     * @notice Function for a lender to accept a proposed loan bid.
     * @param _bidId The id of the loan bid to accept.
     */
    function lenderAcceptBid(uint256 _bidId)
        external
        override
        pendingBid(_bidId, "lenderAcceptBid")
        whenNotPaused
        returns (
            uint256 amountToProtocol,
            uint256 amountToMarketplace,
            uint256 amountToBorrower
        )
    {
        // Retrieve bid
        Bid storage bid = bids[_bidId];

        address sender = _msgSenderForMarket(bid.marketplaceId);

        (bool isVerified, ) = marketRegistry.isVerifiedLender(
            bid.marketplaceId,
            sender
        );
        require(isVerified, "Not verified lender");

        require(
            !marketRegistry.isMarketClosed(bid.marketplaceId),
            "Market is closed"
        );

        require(!isLoanExpired(_bidId), "Bid has expired");

        // Set timestamp
        bid.loanDetails.acceptedTimestamp = uint32(block.timestamp);
        bid.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        // Mark borrower's request as accepted
        bid.state = BidState.ACCEPTED;

        // Declare the bid acceptor as the lender of the bid
        bid.lender = sender;

        // Tell the collateral manager to deploy the escrow and pull funds from the borrower if applicable
        collateralManager.deployAndDeposit(_bidId);

        // Transfer funds to borrower from the lender
        amountToProtocol = bid.loanDetails.principal.percent(protocolFee());
        amountToMarketplace = bid.loanDetails.principal.percent(
            marketRegistry.getMarketplaceFee(bid.marketplaceId)
        );
        amountToBorrower =
            bid.loanDetails.principal -
            amountToProtocol -
            amountToMarketplace;
        //transfer fee to protocol
        bid.loanDetails.lendingToken.safeTransferFrom(
            sender,
            owner(),
            amountToProtocol
        );

        //transfer fee to marketplace
        bid.loanDetails.lendingToken.safeTransferFrom(
            sender,
            marketRegistry.getMarketFeeRecipient(bid.marketplaceId),
            amountToMarketplace
        );

        //transfer funds to borrower
        bid.loanDetails.lendingToken.safeTransferFrom(
            sender,
            bid.receiver,
            amountToBorrower
        );

        // Record volume filled by lenders
        lenderVolumeFilled[address(bid.loanDetails.lendingToken)][sender] += bid
            .loanDetails
            .principal;
        totalVolumeFilled[address(bid.loanDetails.lendingToken)] += bid
            .loanDetails
            .principal;

        // Add borrower's active bid
        _borrowerBidsActive[bid.borrower].add(_bidId);

        // Emit AcceptedBid
        emit AcceptedBid(_bidId, sender);

        emit FeePaid(_bidId, "protocol", amountToProtocol);
        emit FeePaid(_bidId, "marketplace", amountToMarketplace);
    }

    function claimLoanNFT(uint256 _bidId)
        external
        acceptedLoan(_bidId, "claimLoanNFT")
        whenNotPaused
    {
        // Retrieve bid
        Bid storage bid = bids[_bidId];

        address sender = _msgSenderForMarket(bid.marketplaceId);
        require(sender == bid.lender, "only lender can claim NFT");
        // mint an NFT with the lender manager
        lenderManager.registerLoan(_bidId, sender);
        // set lender address to the lender manager so we know to check the owner of the NFT for the true lender
        bid.lender = address(lenderManager);
    }

    /**
     * @notice Function for users to make the minimum amount due for an active loan.
     * @param _bidId The id of the loan to make the payment towards.
     */
    function repayLoanMinimum(uint256 _bidId)
        external
        acceptedLoan(_bidId, "repayLoan")
    {
        (
            uint256 owedPrincipal,
            uint256 duePrincipal,
            uint256 interest
        ) = V2Calculations.calculateAmountOwed(
                bids[_bidId],
                block.timestamp,
                bidPaymentCycleType[_bidId]
            );
        _repayLoan(
            _bidId,
            Payment({ principal: duePrincipal, interest: interest }),
            owedPrincipal + interest,
            true
        );
    }

    /**
     * @notice Function for users to repay an active loan in full.
     * @param _bidId The id of the loan to make the payment towards.
     */
    function repayLoanFull(uint256 _bidId)
        external
        acceptedLoan(_bidId, "repayLoan")
    {
        (uint256 owedPrincipal, , uint256 interest) = V2Calculations
            .calculateAmountOwed(
                bids[_bidId],
                block.timestamp,
                bidPaymentCycleType[_bidId]
            );
        _repayLoan(
            _bidId,
            Payment({ principal: owedPrincipal, interest: interest }),
            owedPrincipal + interest,
            true
        );
    }

    // function that the borrower (ideally) sends to repay the loan
    /**
     * @notice Function for users to make a payment towards an active loan.
     * @param _bidId The id of the loan to make the payment towards.
     * @param _amount The amount of the payment.
     */
    function repayLoan(uint256 _bidId, uint256 _amount)
        external
        acceptedLoan(_bidId, "repayLoan")
    {
        (
            uint256 owedPrincipal,
            uint256 duePrincipal,
            uint256 interest
        ) = V2Calculations.calculateAmountOwed(
                bids[_bidId],
                block.timestamp,
                bidPaymentCycleType[_bidId]
            );
        uint256 minimumOwed = duePrincipal + interest;

        // If amount is less than minimumOwed, we revert
        if (_amount < minimumOwed) {
            revert PaymentNotMinimum(_bidId, _amount, minimumOwed);
        }

        _repayLoan(
            _bidId,
            Payment({ principal: _amount - interest, interest: interest }),
            owedPrincipal + interest,
            true
        );
    }

    /**
     * @notice Lets the DAO/owner of the protocol implement an emergency stop mechanism.
     */
    function pauseProtocol() public virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Lets the DAO/owner of the protocol undo a previously implemented emergency stop.
     */
    function unpauseProtocol() public virtual onlyOwner whenPaused {
        _unpause();
    }

    //TODO: add an incentive for liquidator
    /**
     * @notice Function for users to liquidate a defaulted loan.
     * @param _bidId The id of the loan to make the payment towards.
     */
    function liquidateLoanFull(uint256 _bidId)
        external
        acceptedLoan(_bidId, "liquidateLoan")
    {
        require(isLoanLiquidateable(_bidId), "Loan must be liquidateable.");

        Bid storage bid = bids[_bidId];

        (uint256 owedPrincipal, , uint256 interest) = V2Calculations
            .calculateAmountOwed(
                bid,
                block.timestamp,
                bidPaymentCycleType[_bidId]
            );
        _repayLoan(
            _bidId,
            Payment({ principal: owedPrincipal, interest: interest }),
            owedPrincipal + interest,
            false
        );

        bid.state = BidState.LIQUIDATED;

        // If loan is backed by collateral, withdraw and send to the liquidator
        address liquidator = _msgSenderForMarket(bid.marketplaceId);
        collateralManager.liquidateCollateral(_bidId, liquidator);

        emit LoanLiquidated(_bidId, liquidator);
    }

    /**
     * @notice Internal function to make a loan payment.
     * @param _bidId The id of the loan to make the payment towards.
     * @param _payment The Payment struct with payments amounts towards principal and interest respectively.
     * @param _owedAmount The total amount owed on the loan.
     */
    function _repayLoan(
        uint256 _bidId,
        Payment memory _payment,
        uint256 _owedAmount,
        bool _shouldWithdrawCollateral
    ) internal virtual {
        Bid storage bid = bids[_bidId];
        uint256 paymentAmount = _payment.principal + _payment.interest;

        RepMark mark = reputationManager.updateAccountReputation(
            bid.borrower,
            _bidId
        );

        // Check if we are sending a payment or amount remaining
        if (paymentAmount >= _owedAmount) {
            paymentAmount = _owedAmount;
            bid.state = BidState.PAID;

            // Remove borrower's active bid
            _borrowerBidsActive[bid.borrower].remove(_bidId);

            // If loan is is being liquidated and backed by collateral, withdraw and send to borrower
            if (_shouldWithdrawCollateral) {
                collateralManager.withdraw(_bidId);
            }

            emit LoanRepaid(_bidId);
        } else {
            emit LoanRepayment(_bidId);
        }

        address lender = getLoanLender(_bidId);

        // Send payment to the lender
        bid.loanDetails.lendingToken.safeTransferFrom(
            _msgSenderForMarket(bid.marketplaceId),
            lender,
            paymentAmount
        );

        // update our mappings
        bid.loanDetails.totalRepaid.principal += _payment.principal;
        bid.loanDetails.totalRepaid.interest += _payment.interest;
        bid.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        // If the loan is paid in full and has a mark, we should update the current reputation
        if (mark != RepMark.Good) {
            reputationManager.updateAccountReputation(bid.borrower, _bidId);
        }
    }

    /**
     * @notice Calculates the total amount owed for a bid.
     * @param _bidId The id of the loan bid to calculate the owed amount for.
     */
    function calculateAmountOwed(uint256 _bidId)
        public
        view
        returns (Payment memory owed)
    {
        if (bids[_bidId].state != BidState.ACCEPTED) return owed;

        (uint256 owedPrincipal, , uint256 interest) = V2Calculations
            .calculateAmountOwed(
                bids[_bidId],
                block.timestamp,
                bidPaymentCycleType[_bidId]
            );
        owed.principal = owedPrincipal;
        owed.interest = interest;
    }

    /**
     * @notice Calculates the total amount owed for a loan bid at a specific timestamp.
     * @param _bidId The id of the loan bid to calculate the owed amount for.
     * @param _timestamp The timestamp at which to calculate the loan owed amount at.
     */
    function calculateAmountOwed(uint256 _bidId, uint256 _timestamp)
        public
        view
        returns (Payment memory owed)
    {
        Bid storage bid = bids[_bidId];
        if (
            bid.state != BidState.ACCEPTED ||
            bid.loanDetails.acceptedTimestamp >= _timestamp
        ) return owed;

        (uint256 owedPrincipal, , uint256 interest) = V2Calculations
            .calculateAmountOwed(bid, _timestamp, bidPaymentCycleType[_bidId]);
        owed.principal = owedPrincipal;
        owed.interest = interest;
    }

    /**
     * @notice Calculates the minimum payment amount due for a loan.
     * @param _bidId The id of the loan bid to get the payment amount for.
     */
    function calculateAmountDue(uint256 _bidId)
        public
        view
        returns (Payment memory due)
    {
        if (bids[_bidId].state != BidState.ACCEPTED) return due;

        (, uint256 duePrincipal, uint256 interest) = V2Calculations
            .calculateAmountOwed(
                bids[_bidId],
                block.timestamp,
                bidPaymentCycleType[_bidId]
            );
        due.principal = duePrincipal;
        due.interest = interest;
    }

    /**
     * @notice Calculates the minimum payment amount due for a loan at a specific timestamp.
     * @param _bidId The id of the loan bid to get the payment amount for.
     * @param _timestamp The timestamp at which to get the due payment at.
     */
    function calculateAmountDue(uint256 _bidId, uint256 _timestamp)
        public
        view
        returns (Payment memory due)
    {
        Bid storage bid = bids[_bidId];
        if (
            bids[_bidId].state != BidState.ACCEPTED ||
            bid.loanDetails.acceptedTimestamp >= _timestamp
        ) return due;

        (, uint256 duePrincipal, uint256 interest) = V2Calculations
            .calculateAmountOwed(bid, _timestamp, bidPaymentCycleType[_bidId]);
        due.principal = duePrincipal;
        due.interest = interest;
    }

    /**
     * @notice Returns the next due date for a loan payment.
     * @param _bidId The id of the loan bid.
     */
    function calculateNextDueDate(uint256 _bidId)
        public
        view
        returns (uint32 dueDate_)
    {
        Bid storage bid = bids[_bidId];
        if (bids[_bidId].state != BidState.ACCEPTED) return dueDate_;

        uint32 lastRepaidTimestamp = lastRepaidTimestamp(_bidId);

        // Calculate due date if payment cycle is set to monthly
        if (bidPaymentCycleType[_bidId] == PaymentCycleType.Monthly) {
            // Calculate the cycle number the last repayment was made
            uint256 lastPaymentCycle = BPBDTL.diffMonths(
                bid.loanDetails.acceptedTimestamp,
                lastRepaidTimestamp
            );
            if (
                BPBDTL.getDay(lastRepaidTimestamp) >
                BPBDTL.getDay(bid.loanDetails.acceptedTimestamp)
            ) {
                lastPaymentCycle += 2;
            } else {
                lastPaymentCycle += 1;
            }

            dueDate_ = uint32(
                BPBDTL.addMonths(
                    bid.loanDetails.acceptedTimestamp,
                    lastPaymentCycle
                )
            );
        } else if (bidPaymentCycleType[_bidId] == PaymentCycleType.Seconds) {
            // Start with the original due date being 1 payment cycle since bid was accepted
            dueDate_ =
                bid.loanDetails.acceptedTimestamp +
                bid.terms.paymentCycle;
            // Calculate the cycle number the last repayment was made
            uint32 delta = lastRepaidTimestamp -
                bid.loanDetails.acceptedTimestamp;
            if (delta > 0) {
                uint32 repaymentCycle = uint32(
                    Math.ceilDiv(delta, bid.terms.paymentCycle)
                );
                dueDate_ += (repaymentCycle * bid.terms.paymentCycle);
            }
        }

        uint32 endOfLoan = bid.loanDetails.acceptedTimestamp +
            bid.loanDetails.loanDuration;
        //if we are in the last payment cycle, the next due date is the end of loan duration
        if (dueDate_ > endOfLoan) {
            dueDate_ = endOfLoan;
        }
    }

    /**
     * @notice Checks to see if a borrower is delinquent.
     * @param _bidId The id of the loan bid to check for.
     */
    function isPaymentLate(uint256 _bidId) public view override returns (bool) {
        if (bids[_bidId].state != BidState.ACCEPTED) return false;
        return uint32(block.timestamp) > calculateNextDueDate(_bidId);
    }

    /**
     * @notice Checks to see if a borrower is delinquent.
     * @param _bidId The id of the loan bid to check for.
     * @return bool True if the loan is defaulted.
     */
    function isLoanDefaulted(uint256 _bidId)
        public
        view
        override
        returns (bool)
    {
        return _canLiquidateLoan(_bidId, 0);
    }

    /**
     * @notice Checks to see if a loan was delinquent for longer than liquidation delay.
     * @param _bidId The id of the loan bid to check for.
     * @return bool True if the loan is liquidateable.
     */
    function isLoanLiquidateable(uint256 _bidId)
        public
        view
        override
        returns (bool)
    {
        return _canLiquidateLoan(_bidId, LIQUIDATION_DELAY);
    }

    /**
     * @notice Checks to see if a borrower is delinquent.
     * @param _bidId The id of the loan bid to check for.
     * @param _liquidationDelay Amount of additional seconds after a loan defaulted to allow a liquidation.
     * @return bool True if the loan is liquidateable.
     */
    function _canLiquidateLoan(uint256 _bidId, uint32 _liquidationDelay)
        internal
        view
        returns (bool)
    {
        Bid storage bid = bids[_bidId];

        // Make sure loan cannot be liquidated if it is not active
        if (bid.state != BidState.ACCEPTED) return false;

        if (bidDefaultDuration[_bidId] == 0) return false;

        return (uint32(block.timestamp) -
            _liquidationDelay -
            lastRepaidTimestamp(_bidId) >
            bidDefaultDuration[_bidId]);
    }

    function getBidState(uint256 _bidId)
        external
        view
        override
        returns (BidState)
    {
        return bids[_bidId].state;
    }

    function getBorrowerActiveLoanIds(address _borrower)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _borrowerBidsActive[_borrower].values();
    }

    function getBorrowerLoanIds(address _borrower)
        external
        view
        returns (uint256[] memory)
    {
        return borrowerBids[_borrower];
    }

    /**
     * @notice Checks to see if a pending loan has expired so it is no longer able to be accepted.
     * @param _bidId The id of the loan bid to check for.
     */
    function isLoanExpired(uint256 _bidId) public view returns (bool) {
        Bid storage bid = bids[_bidId];

        if (bid.state != BidState.PENDING) return false;
        if (bidExpirationTime[_bidId] == 0) return false;

        return (uint32(block.timestamp) >
            bid.loanDetails.timestamp + bidExpirationTime[_bidId]);
    }

    /**
     * @notice Returns the last repaid timestamp for a loan.
     * @param _bidId The id of the loan bid to get the timestamp for.
     */
    function lastRepaidTimestamp(uint256 _bidId) public view returns (uint32) {
        return V2Calculations.lastRepaidTimestamp(bids[_bidId]);
    }

    /**
     * @notice Returns the borrower address for a given bid.
     * @param _bidId The id of the bid/loan to get the borrower for.
     * @return borrower_ The address of the borrower associated with the bid.
     */
    function getLoanBorrower(uint256 _bidId)
        public
        view
        returns (address borrower_)
    {
        borrower_ = bids[_bidId].borrower;
    }

    /**
     * @notice Returns the lender address for a given bid. If the stored lender address is the `LenderManager` NFT address, return the `ownerOf` for the bid ID.
     * @param _bidId The id of the bid/loan to get the lender for.
     * @return lender_ The address of the lender associated with the bid.
     */
    function getLoanLender(uint256 _bidId)
        public
        view
        returns (address lender_)
    {
        lender_ = bids[_bidId].lender;

        if (lender_ == address(lenderManager)) {
            return lenderManager.ownerOf(_bidId);
        }
    }

    function getLoanLendingToken(uint256 _bidId)
        external
        view
        returns (address token_)
    {
        token_ = address(bids[_bidId].loanDetails.lendingToken);
    }

    function getLoanMarketId(uint256 _bidId)
        external
        view
        returns (uint256 _marketId)
    {
        _marketId = bids[_bidId].marketplaceId;
    }

    function getLoanSummary(uint256 _bidId)
        external
        view
        returns (
            address borrower,
            address lender,
            uint256 marketId,
            address principalTokenAddress,
            uint256 principalAmount,
            uint32 acceptedTimestamp,
            uint32 lastRepaidTimestamp,
            BidState bidState
        )
    {
        Bid storage bid = bids[_bidId];

        borrower = bid.borrower;
        lender = bid.lender;
        marketId = bid.marketplaceId;
        principalTokenAddress = address(bid.loanDetails.lendingToken);
        principalAmount = bid.loanDetails.principal;
        acceptedTimestamp = bid.loanDetails.acceptedTimestamp;
        lastRepaidTimestamp = V2Calculations.lastRepaidTimestamp(bids[_bidId]);
        bidState = bid.state;
    }

    /** OpenZeppelin Override Functions **/

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address sender)
    {
        sender = ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}