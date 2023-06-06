// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IBullaClaim.sol';
import './BullaBanker.sol';

uint256 constant MAX_BPS = 10_000;

/// @title An extension to BullaClaim V1 that allows creditors to finance invoices
/// @author @colinnielsen
/// @notice Arbitrates loan terms between a creditor and a debtor, managing payments and credit via Bulla Claims
contract BullaFinance {
    using SafeERC20 for IERC20;
    struct FinanceTerms {
        uint24 minDownPaymentBPS;
        uint24 interestBPS;
        uint40 termLength;
    }

    event FinancingOffered(uint256 indexed originatingClaimId, FinanceTerms terms, uint256 blocktime);
    event FinancingAccepted(uint256 indexed originatingClaimId, uint256 indexed financedClaimId, uint256 blocktime);
    event BullaTagUpdated(address indexed bullaManager, uint256 indexed tokenId, address indexed updatedBy, bytes32 tag, uint256 blocktime);
    event FeeReclaimed(uint256 indexed originatingClaimId, uint256 blocktime);

    error INSUFFICIENT_FEE();
    error NOT_CREDITOR();
    error NOT_DEBTOR();
    error NOT_ADMIN();
    error INVALID_MIN_DOWN_PAYMENT();
    error INVALID_TERM_LENGTH();
    error CLAIM_NOT_PENDING();
    error NO_FINANCE_OFFER();
    error UNDER_PAYING();
    error OVER_PAYING();
    error WITHDRAWAL_FAILED();

    /// address of the Bulla Claim contract
    IBullaClaim public bullaClaim;
    /// the admin of the contract
    address public admin;
    /// the fee represented as the wei amount of the network's native token
    uint256 public fee;
    /// a mapping of financiable claimId to the FinanceTerms offered by the creditor
    mapping(uint256 => FinanceTerms) public financeTermsByClaimId;

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

    /// @param _admin the new admin
    /// @notice SPEC:
    ///     allows an admin to change the admin address to `_admin`
    ///     Given the following: `msg.sender == admin`
    // function changeAdmin(address _admin) public virtual;

    /// @param _fee the new fee
    /// @notice SPEC:
    ///     allows an admin to update the fee amount to `_fee`
    ///     Given the following: `msg.sender == admin`
    // function feeChanged(uint256 _fee) public virtual;

    /// @notice SPEC:
    ///     allows an admin to withdraw `withdrawableFee` amount of tokens from this contract's balance
    ///     Given the following: `msg.sender == admin`
    function withdrawFee(uint256 _amount) public {
        if (msg.sender != admin) revert NOT_ADMIN();

        (bool success, ) = admin.call{ value: _amount }('');
        if (!success) revert WITHDRAWAL_FAILED();
    }

    //
    //// CREDITOR FUNCTIONS ////
    //

    /// @param claim claim creation parameters
    /// @param terms financing terms
    /// @notice SPEC:
    ///     Allows a user to create a Bulla Claim with and offer finance terms to the debtor
    ///     This function will:
    ///         RES1. Create a claim on BullaClaim with the specified parameters in calldata
    ///         RES2. Store the loanTerms as indexed by newly created claimId
    ///         RES3. Emit a FinancingOffered event with the newly created claimId, the terms from calldata, and any user tags
    ///         RES4. Emit a BullaTagUpdated event with the user's tag
    ///         RETURNS: the newly created claimId
    ///     Given the following:
    ///         P1. `msg.value == fee`
    ///         P2. `msg.sender == claim.creditor`
    ///         P3. `(terms.minDownPaymentBPS * claim.claimAmount / 10_000) > 0`
    ///         P4. `terms.minDownPaymentBPS < type(uint24).max`
    ///         P5. `terms.interestBPS < type(uint24).max`
    ///         P6. `terms.termLength < type(uint40).max`
    ///         P7. `terms.termLength > 0`
    function createInvoiceWithFinanceOffer(
        BullaBanker.ClaimParams calldata claim,
        string calldata tokenURI,
        FinanceTerms calldata terms,
        bytes32 tag
    ) public payable virtual returns (uint256) {
        if (msg.value != fee) revert INSUFFICIENT_FEE();
        if (msg.sender != claim.creditor) revert NOT_CREDITOR();
        if (((terms.minDownPaymentBPS * claim.claimAmount) / MAX_BPS) == 0) revert INVALID_MIN_DOWN_PAYMENT();
        if (terms.termLength == 0) revert INVALID_TERM_LENGTH();

        uint256 claimId = bullaClaim.createClaimWithURI(
            claim.creditor,
            claim.debtor,
            claim.description,
            claim.claimAmount,
            claim.dueBy,
            claim.claimToken,
            claim.attachment,
            tokenURI
        );

        financeTermsByClaimId[claimId] = terms;

        emit BullaTagUpdated(bullaClaim.bullaManager(), claimId, msg.sender, tag, block.timestamp);
        emit FinancingOffered(claimId, terms, block.timestamp);

        return claimId;
    }

    /// @param claimId the id of the underlying claim
    /// @param terms financing terms
    /// @notice SPEC:
    ///     Allows a creditor to offer financing on an existing pending claim OR update previously offerred financing terms // TODO: should this function be used to rescind a financing offer?
    ///     This function will:
    ///         RES1. Overwrite the `terms` as indexed by the specified `claimId`
    ///         RES2. Emit a FinancingOffered event
    ///     Given the following:
    ///         P1. `claim.status == ClaimStatus.Pending`
    ///         P2. `msg.sender == claim.creditor`
    ///         P3. if terms[claimId].termLength == 0 (implying new terms on an existing claim) ensure msg.value == fee
    ///         P4. `(terms.minDownPaymentBPS * claim.claimAmount / 10_000) > 0`
    ///         P5. `terms.minDownPaymentBPS < type(uint24).max`
    ///         P6. `terms.interestBPS < type(uint24).max`
    ///         P7. `terms.termLength < type(uint40).max`
    ///         P8. `terms.termLength > block.timestamp` TODO: necessary?
    // function offerFinancing(uint256 claimId, FinanceTerms memory terms) public;

    /// @param claimId the id of the underlying claim
    /// @notice SPEC:
    ///     Allows a creditor to reclaim feeAmount of tokens if the underlying claim is no longer pending
    ///     This function will:
    ///         RES1. delete `financeTerms[claimId]`
    ///         RES2. transfer the creditor `fee` amount of tokens
    ///         RES3. Emit a FeeReclaimed event with the underlying claimId
    ///     Given the following:
    ///         P1. `claim.status != ClaimStatus.Pending`
    // function reclaimFee(uint256 claimId) public virtual;

    //
    //// DEBTOR FUNCTIONS ////
    //

    /// @param claimId id of the originating claim
    /// @param downPayment the amount the debtor wishes to contribute
    /// @notice SPEC:
    ///     Allows a debtor to accept a creditor's financing offer and begin payment
    ///     This function will:
    ///         RES1. load the previous claim details and create a new bulla claim specifying `claimAmount` as `originatingClaimAmount + (originatingClaimAmount * terms.interestBPS / 10_000)` and `dueBy` as `term.termLength + block.timestamp`
    ///         RES2. deletes the `financeTerms`
    ///         RES3. pays `downPayment` amount on the newly created claim
    ///         RES4. emits a LoanAccepted event with the `originatingClaimId` and the new claimId as `financedClaimId`
    ///         RETURNS: the newly created claimId
    ///     Given the following:
    ///         P1. msg.sender has approved BullaFinance to spend at least `downPayment` amount of the underlying claim's denominating ERC20 token
    ///         P2. `financingTerms[claimId].termLength != 0` (offer exists)
    ///         P3. `claim.status == ClaimStatus.Pending`
    ///         P4. `msg.sender == claim.debtor`
    ///         P5. `downPayment >= (claimAmount * minDownPaymentBPS / 10_000)` && `downPayment < claimAmount + (claimAmount * interestBPS / 10_000) (not overpaying or underpaying)
    function acceptFinancing(
        uint256 claimId,
        uint256 downPayment,
        string calldata description
    ) public returns (uint256) {
        Claim memory claim = bullaClaim.getClaim(claimId);
        FinanceTerms memory terms = financeTermsByClaimId[claimId];

        if (claim.status != Status.Pending) revert CLAIM_NOT_PENDING();
        if (claim.debtor != msg.sender) revert NOT_DEBTOR();
        if (terms.termLength == 0) revert NO_FINANCE_OFFER();
        if (downPayment < ((claim.claimAmount * terms.minDownPaymentBPS) / MAX_BPS)) revert UNDER_PAYING();
        if (downPayment > claim.claimAmount) revert OVER_PAYING();

        address creditor = IERC721(address(bullaClaim)).ownerOf(claimId);
        string memory tokenURI = ERC721URIStorage(address(bullaClaim)).tokenURI(claimId);

        uint256 newClaimAmount = claim.claimAmount + (((claim.claimAmount - downPayment) * terms.interestBPS) / MAX_BPS);
        uint256 financedClaimId = bullaClaim.createClaimWithURI({
            creditor: creditor,
            debtor: claim.debtor,
            description: description,
            claimAmount: newClaimAmount, // add interest to the new claim
            dueBy: block.timestamp + terms.termLength,
            claimToken: claim.claimToken,
            attachment: claim.attachment,
            _tokenUri: tokenURI
        });

        delete financeTermsByClaimId[claimId];

        IERC20(claim.claimToken).safeTransferFrom(msg.sender, address(this), downPayment);
        IERC20(claim.claimToken).approve(address(bullaClaim), downPayment);
        bullaClaim.payClaim(financedClaimId, downPayment);

        emit FinancingAccepted(claimId, financedClaimId, block.timestamp);

        return financedClaimId;
    }
}