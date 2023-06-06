// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IBullaClaim.sol';
import './BullaBanker.sol';

uint256 constant MAX_BPS = 10_000;

/// @title FrendLend POC
/// @author @colinnielsen
/// @notice An extension to BullaClaim V1 that allows a creditor to offer capital in exchange for a claim
/// @notice This is experimental software, use at your own risk
contract FrendLend {
    using SafeERC20 for IERC20;

    struct LoanOffer {
        uint24 interestBPS; // can be 0
        uint40 termLength; // cannot be 0
        uint128 loanAmount;
        address creditor;
        address debtor;
        string description;
        address claimToken;
        Multihash attachment;
    }

    /// address of the Bulla Claim contract
    IBullaClaim public bullaClaim;
    /// the admin of the contract
    address public admin;
    /// the fee represented as the wei amount of the network's native token
    uint256 public fee;
    /// the number of loan offers
    uint256 public loanOfferCount;
    /// a mapping of id to the FinanceTerms offered by the creditor
    mapping(uint256 => LoanOffer) public loanOffers;

    event LoanOffered(uint256 indexed loanId, address indexed offeredBy, LoanOffer loanOffer, uint256 blocktime);
    event LoanOfferAccepted(uint256 indexed loanId, uint256 indexed claimId, uint256 blocktime);
    event LoanOfferRejected(uint256 indexed loanId, address indexed rejectedBy, uint256 blocktime);
    event BullaTagUpdated(address indexed bullaManager, uint256 indexed tokenId, address indexed updatedBy, bytes32 tag, uint256 blocktime);

    error INCORRECT_FEE();
    error NOT_CREDITOR();
    error NOT_DEBTOR();
    error NOT_CREDITOR_OR_DEBTOR();
    error NOT_ADMIN();
    error INVALID_TERM_LENGTH();
    error WITHDRAWAL_FAILED();
    error TRANSFER_FAILED();

    constructor(
        IBullaClaim _bullaClaim,
        address _admin,
        uint256 _fee
    ) {
        bullaClaim = _bullaClaim;
        admin = _admin;
        fee = _fee;
    }

    ////// ADMIN FUNCTIONS //////

    /// @notice SPEC:
    ///     allows an admin to withdraw `withdrawableFee` amount of tokens from this contract's balance
    ///     Given the following: `msg.sender == admin`
    function withdrawFee(uint256 _amount) public {
        if (msg.sender != admin) revert NOT_ADMIN();

        (bool success, ) = admin.call{ value: _amount }('');
        if (!success) revert WITHDRAWAL_FAILED();
    }

    ////// USER FUNCTIONS //////

    /// @param offer claim creation params and loan info
    /// @notice SPEC:
    ///     Allows a user to create offer a loan to a potential debtor
    ///     This function will:
    ///         RES1. Increment the loan offer count in storage
    ///         RES2. Store the offer parameters
    ///         RES3. Emit a LoanOffered event with the offer parameters, the offerId, the creator, and the current timestamp
    ///         RETURNS: the offerId
    ///     Given the following:
    ///         P1. `msg.value == fee`
    ///         P2. `msg.sender == offer.creditor`
    ///         P3. `terms.interestBPS < type(uint24).max`
    ///         P4. `terms.termLength < type(uint40).max`
    ///         P5. `terms.termLength > 0`
    function offerLoan(LoanOffer calldata offer) public payable returns (uint256) {
        if (msg.value != fee) revert INCORRECT_FEE();
        if (msg.sender != offer.creditor) revert NOT_CREDITOR();
        if (offer.termLength == 0) revert INVALID_TERM_LENGTH();

        uint256 offerId = ++loanOfferCount;
        loanOffers[offerId] = offer;

        emit LoanOffered(offerId, msg.sender, offer, block.timestamp);

        return offerId;
    }

    /// @param offerId the offerId to reject
    /// @notice SPEC:
    ///     Allows a debtor or a offerrer to reject (or rescind) a loan offer
    ///     This function will:
    ///         RES1. Delete the offer from storage
    ///         RES2. Emit a LoanOfferRejected event with the offerId, the msg.sender, and the current timestamp
    ///     Given the following:
    ///         P1. the current msg.sender is either the creditor or debtor (covers: offer exists)
    function rejectLoanOffer(uint256 offerId) public {
        LoanOffer memory offer = loanOffers[offerId];
        if (msg.sender != offer.creditor && msg.sender != offer.debtor) revert NOT_CREDITOR_OR_DEBTOR();

        delete loanOffers[offerId];

        emit LoanOfferRejected(offerId, msg.sender, block.timestamp);
    }

    /// @param offerId the offerId to acceot
    /// @param tokenURI the tokenURI for the underlying claim
    /// @param tag a bytes32 tag for the frontend
    /// @notice WARNING: will not work with fee on transfer tokens
    /// @notice SPEC:
    ///     Allows a debtor to accept a loan offer, and receive payment
    ///     This function will:
    ///         RES1. Delete the offer from storage
    ///         RES2. Creates a new claim for the loan amount + interest
    ///         RES3. Transfers the offered loan amount from the creditor to the debtor
    ///         RES4. Puts the claim into a non-rejectable repaying state by paying 1 wei
    ///         RES5. Emits a BullaTagUpdated event with the claimId, the debtor address, a tag, and the current timestamp
    ///         RES6. Emits a LoanOfferAccepted event with the offerId, the accepted claimId, and the current timestamp
    ///     Given the following:
    ///         P1. the current msg.sender is the debtor listed on the offer (covers: offer exists)
    function acceptLoan(
        uint256 offerId,
        string calldata tokenURI,
        bytes32 tag
    ) public {
        LoanOffer memory offer = loanOffers[offerId];
        if (msg.sender != offer.debtor) revert NOT_DEBTOR();

        delete loanOffers[offerId];

        uint256 claimAmount = offer.loanAmount + (offer.loanAmount * offer.interestBPS) / MAX_BPS + 1;
        uint256 claimId = bullaClaim.createClaimWithURI(
            offer.creditor,
            offer.debtor,
            offer.description,
            claimAmount,
            block.timestamp + offer.termLength,
            offer.claimToken,
            offer.attachment,
            tokenURI
        );

        // add 1 wei to force repaying status
        IERC20(offer.claimToken).safeTransferFrom(offer.creditor, address(this), offer.loanAmount + 1);
        IERC20(offer.claimToken).approve(address(bullaClaim), 1);
        bullaClaim.payClaim(claimId, 1);

        IERC20(offer.claimToken).safeTransfer(offer.debtor, offer.loanAmount);

        emit BullaTagUpdated(bullaClaim.bullaManager(), claimId, msg.sender, tag, block.timestamp);
        emit LoanOfferAccepted(offerId, claimId, block.timestamp);
    }
}