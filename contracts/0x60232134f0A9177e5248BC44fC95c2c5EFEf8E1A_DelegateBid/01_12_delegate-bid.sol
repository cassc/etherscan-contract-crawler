// SPDX-License-Identifier: BSD-3-Clause

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {NounsDAOStorageV1, INounsDAOLogic} from "../external/nouns/governance/NounsDAOInterfaces.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {Refundable} from "./refundable.sol";

pragma solidity ^0.8.17;

/// @title DelegateBid is a delegated voter which accepts ETH bids in exchange
/// for casting votes on external DAO proposals
contract DelegateBid is IERC1271, ReentrancyGuard, Refundable, Ownable {
    /// Bid is the structure of an offer for the delegate to cast a vote on a
    /// proposal
    struct Bid {
        /// @notice The amount of ETH bid
        uint256 amount;
        /// @notice The block number the external proposal voting period ends
        uint256 endBlock;
        /// @notice the block number the bid was made
        uint256 txBlock;
        /// @notice The address of the bidder
        address bidder;
        /// @notice The support value to cast for vote
        uint8 support;
        /// @notice Whether the vote was cast for this bid
        bool executed;
        /// @notice Whether the bid was refunded
        bool refunded;
    }

    /// @notice An event emitted when a vote has been cast on an external proposal
    /// @param dao The external dao address
    /// @param propId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param amount Amount of ETH bid
    /// @param bidder The address of the bidder
    event VoteCast(address indexed dao, uint256 indexed propId, uint8 support, uint256 amount, address bidder);

    /// @notice Emitted when vote cast gas fee is refunded and bid distributed
    event VoteCastRefundAndDistribute(
        address indexed caller, uint256 refundAmount, uint256 tip, bool refundSent, uint256 fee, bool feeSent
    );

    /// @notice An event emitted when a bid has been placed to cast a vote on an external proposal
    /// @param dao The external dao address
    /// @param propId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param amount Amount of ETH bid
    /// @param bidder The address of the bidder
    /// @param reason The reason given for the vote by the voter
    event BidPlaced(
        address indexed dao, uint256 indexed propId, uint8 support, uint256 amount, address bidder, string reason
    );

    /// @notice Emitted when beneficiary is changed
    event NewBeneficiary(address oldBeneficiary, address newBeneficiary);

    /// @notice Emitted when min bid increment percentage is changed
    event NewMinBidIncrementPercentage(uint8 oldBidIncPercentage, uint8 newBidIncPercentage);

    /// @notice Emitted when min bid is changed
    event NewMinBid(uint256 oldMinBid, uint256 newMinBid);

    /// @notice Emitted when vote cast window is changed
    event NewCastWindow(uint256 oldExecWindow, uint256 newExecWindow);

    /// @notice Emitted when base tip awarted to execute vote cast is changed
    event NewBaseTip(uint256 oldTip, uint256 newTip);

    /// @notice Emitted when ERC1271 the signer is changed
    event SignerChanged(address oldSigner, address newSigner);

    /// @notice Emitted when the prop submitter is changed
    event SubmitterChanged(address oldSubmitter, address newSubmitter);

    // PROPERTIES
    // ----------

    /// @notice The name of this contract
    string public constant name = "Federation Delegate Bid";

    /// @notice The address of the contract beneficiary
    address public beneficiary;

    /// @notice The address of an account approved to sign messages on behalf of
    /// this contract
    address public approvedSigner;

    /// @notice The address of an account approved to submit proposals using the
    /// representation of this contract
    address public approvedSubmitter;

    /// @notice The minimum percent difference between the last bid placed for a
    /// proposal vote and the current one
    uint8 public minBidIncrementPercentage;

    /// @notice The minimum bid accepted to cast a vote
    uint256 public minBid;

    /// @notice The window in blocks where casting a vote is allowed
    uint256 public castWindow;

    /// @notice The default tip configured for casting a vote
    uint256 public baseTip;

    /// @notice The active bid for each proposal in a given DAO
    mapping(address => mapping(uint256 => Bid)) public bids;

    /**
     * @param _castWindow The window in blocks that a vote is elegible to be cast
     * @param _baseTip the default tip awarded for casting an external vote
     * @param _minBid the minimum bid accepted to cast a vote
     * @param _minBidIncrementPercentage % a new bid for a prop must be greater than the last bid
     */
    constructor(uint256 _castWindow, uint256 _baseTip, uint256 _minBid, uint8 _minBidIncrementPercentage) {
        castWindow = _castWindow;
        baseTip = _baseTip;
        minBid = _minBid;
        minBidIncrementPercentage = _minBidIncrementPercentage;

        /// @notice default beneficiary is the owner address
        beneficiary = msg.sender;
    }

    /**
     * @notice Create a bid for a proposal vote
     * @param dao The address of the DAO
     * @param propId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason A string reason for the vote cast.
     * @dev ensure that this delegate has representation for the given DAO address
     * before calling this fn
     */
    function createBid(address dao, uint256 propId, uint8 support, string calldata reason)
        external
        payable
        nonReentrant
    {
        require(dao != address(0), "DAO address is not valid");
        require(_isPendingOrActive(dao, propId), "Proposal is not pending or active");
        require(support <= 2, "Invalid support type");
        require(msg.value >= minBid, "Must send at least minBid amount");

        Bid storage bid = bids[dao][propId];
        uint256 lastAmount = bid.amount;
        address lastBidder = bid.bidder;

        require(
            msg.value >= lastAmount + ((lastAmount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );

        require(!bid.executed, "Vote already cast");

        // get proposal end block
        uint256 propEndBlock;
        try this._proposalEndBlock(dao, propId) returns (uint256 endBlock) {
            propEndBlock = endBlock;
        } catch (bytes memory) {
            revert("Failed getting proposal end block");
        }

        bid.amount = msg.value;
        bid.bidder = msg.sender;
        bid.support = support;
        bid.endBlock = propEndBlock;
        bid.txBlock = block.number;

        emit BidPlaced(dao, propId, support, bid.amount, msg.sender, reason);

        // refund previous bid if there was one
        if (lastBidder != address(0)) {
            SafeTransferLib.forceSafeTransferETH(lastBidder, lastAmount);
        }
    }

    /**
     * @notice Casts a vote on an external proposal. Tip is awarded to the caller
     * @param dao The address of the DAO
     * @param propId The id of the proposal to execute
     * @dev This function ensures that the proposal is within the execution window
     * and that some bid has been offered to cast the vote
     */
    function castExternalVote(address dao, uint256 propId) external nonReentrant {
        uint256 startGas = gasleft();

        require(dao != address(0), "DAO address is not valid");
        require(_isActive(dao, propId), "Voting is closed for this proposal");

        Bid storage bid = bids[address(dao)][propId];

        require(bid.amount > 0 && bid.bidder != address(0), "Bid not offered for this proposal");
        require(block.number >= bid.endBlock - castWindow, "Vote can only be cast during the proposal execution window");
        require(!bid.executed, "Vote already cast");
        require(bid.txBlock < block.number, "Vote cannot be cast in the same block the bid was made");

        bid.executed = true;

        INounsDAOLogic eDAO = INounsDAOLogic(dao);
        eDAO.castVote(propId, bid.support);

        emit VoteCast(dao, propId, bid.support, bid.amount, bid.bidder);

        // refund gas and calculate an incentive for the executer, distribute the
        // rest to the contract beneficiary
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }

            uint256 tip = min(baseTip, bid.amount);
            uint256 basefee = min(block.basefee, MAX_REFUND_BASE_FEE);
            uint256 gasPrice = min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = min(startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
            uint256 refundAmount = min(gasPrice * gasUsed, balance);
            uint256 refundIncludingTip = min(refundAmount + tip, bid.amount);
            (bool refundSent,) = tx.origin.call{value: refundIncludingTip}("");

            uint256 fee = bid.amount - refundIncludingTip;
            (bool feeSent,) = beneficiary.call{value: fee}("");
            emit VoteCastRefundAndDistribute(tx.origin, refundAmount, tip, refundSent, fee, feeSent);
        }
    }

    /**
     * @notice Refunds ETH offered on a cancelled proposal to the last bidder
     * @param dao The address of the DAO
     * @param propId The id of the proposal
     */
    function claimRefund(address dao, uint256 propId) external nonReentrant {
        Bid storage bid = bids[dao][propId];

        require(msg.sender == bid.bidder, "Only the bidder can claim their refund");
        require(!bid.refunded, "Bid already refunded");
        require(!bid.executed, "Vote already cast");
        require(address(this).balance >= bid.amount, "Insufficient balance to refund");

        // if the external proposal voting period has ended and we could not
        // cast the vote allow the bidder to claim a refund
        if (!_isPendingOrActive(dao, propId)) {
            bid.refunded = true;
            SafeTransferLib.forceSafeTransferETH(bid.bidder, bid.amount);
            return;
        }

        revert("Refund cannot be claimed");
    }

    /**
     * @notice Allows an approved submitter to submit a proposal against an external DAO
     */
    function submitProp(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        INounsDAOLogic eDAO
    ) external returns (uint256) {
        require(msg.sender == approvedSubmitter, "Submitter only");
        uint256 propID = eDAO.propose(targets, values, signatures, calldatas, description);
        return propID;
    }

    // MANAGEMENT FUNCTIONS
    // --------------------

    /**
     * @notice Changes the beneficiary address
     * @dev Function for updating beneficiary
     */
    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
        emit NewBeneficiary(beneficiary, _beneficiary);
    }

    /**
     * @notice Changes min bid increment percent
     * @dev function for updating minBidIncrementPercentage
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;
        emit NewMinBidIncrementPercentage(minBidIncrementPercentage, _minBidIncrementPercentage);
    }

    /**
     * @notice Changes min bid
     * @dev function for updating minBid
     */
    function setMinBid(uint256 _minBid) external onlyOwner {
        minBid = _minBid;
        emit NewMinBid(minBid, _minBid);
    }

    /**
     * @notice Changes window for casting an external vote
     * @dev function for updating execWindow
     */
    function setCastWindow(uint256 _castWindow) external onlyOwner {
        castWindow = _castWindow;
        emit NewCastWindow(castWindow, _castWindow);
    }

    /**
     * @notice Sets approved submitter for proposals
     * @dev Function for updating approvedSubmitter
     */
    function setApprovedSubmitter(address _submitter) external onlyOwner {
        approvedSubmitter = _submitter;
        emit SubmitterChanged(approvedSubmitter, _submitter);
    }

    /**
     * @notice Sets approved signer for ERC1271 signatures
     * @dev Function for updating approvedSigner
     */
    function setApprovedSigner(address _signer) external onlyOwner {
        approvedSigner = _signer;
        emit SignerChanged(approvedSigner, _signer);
    }

    // IERC1271 IMPLEMENTATION
    // -----------------------

    bytes4 constant IERC1271_MAGIC_VALUE = 0x1626ba7e;

    /**
     * @notice Handles EOA and smart contract signature verification
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue) {
        require(approvedSigner != address(0), "Approved signer not set");
        if (SignatureChecker.isValidSignatureNow(approvedSigner, hash, signature)) {
            magicValue = IERC1271_MAGIC_VALUE;
        }
    }

    // HELPERS
    // -------

    /**
     * @notice Helper function that determines if a proposal has been opened or the voting period is active
     * @param dao The address of the DAO that the given propId is in
     * @param propId The id of the proposal
     * @return bool True if the proposal is pending or active
     */
    function _isPendingOrActive(address dao, uint256 propId) internal view returns (bool) {
        bool isPending = INounsDAOLogic(dao).state(propId) == INounsDAOLogic.ProposalState.Pending;
        bool isActive = INounsDAOLogic(dao).state(propId) == INounsDAOLogic.ProposalState.Active;
        return isPending || isActive;
    }

    /**
     * @notice Helper function that determines if a proposal voting period is active
     * @param dao The address of the DAO that the given propId is in
     * @param propId The id of the proposal
     * @return bool True if the proposal is pending or active
     */
    function _isActive(address dao, uint256 propId) internal view returns (bool) {
        bool isActive = INounsDAOLogic(dao).state(propId) == INounsDAOLogic.ProposalState.Active;
        return isActive;
    }

    /**
     * @notice Helper function that parses end block from external proposals.
     * @param dao The address of the DAO that the given propId is in
     * @param propId The id of the proposal
     * @return uint256 The voting end block of the external proposal
     */
    function _proposalEndBlock(address dao, uint256 propId) public view returns (uint256) {
        (,,,,,, uint256 endBlock,,,,,,) = NounsDAOStorageV1(dao).proposals(propId);
        return endBlock;
    }

    /**
     * @notice Helper function that compares two integers and returns the larger
     * one
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @notice Helper function that compares two integers and returns the
     * smaller one
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }
}