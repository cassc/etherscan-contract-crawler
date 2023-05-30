pragma solidity 0.8.14;

import "./interface/IProofOfDeveloper.sol";
import "./interface/IProofOfAuditor.sol";
import "./interface/IDeveloperWallet.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @title   Hyacinth Database
/// @notice  Contract that keeps track of pending and completed audits
/// @author  Hyacinth
contract HyacinthDatabase {
    /// EVENTS ///

    /// @notice                 Emitted after audit has been added
    /// @param auditedContract  Address of contract being audited
    /// @param auditedContract  Address of previous contract if roll over
    /// @param developer        Address of developer
    event AuditAdded(address indexed auditedContract, address indexed previous, address developer);

    /// @notice           Emitted after pod has been minted
    /// @param developer  Address of developer
    /// @param id         Id of POD minted
    event PODMinted(address indexed developer, uint256 id);

    /// @notice                 Emitted after audit result has been submitted
    /// @param auditor          Address of auditor of contract
    /// @param developer        Developer of contract
    /// @param auditedContract  Address of contract audit being submitted for
    /// @param result           Result of audit
    event ResultSubmitted(address indexed auditor, address indexed developer, address indexed auditedContract, STATUS result);

    /// @notice                 Emitted after audit has been picked up
    /// @param auditor          Address of auditor of contract
    /// @param auditedContract  Address of contract having audit picked up
    event AuditPickedUp(address indexed auditor, address indexed auditedContract);

    /// @notice                 Emitted after collaboration has been proposed
    /// @param auditedContract  Address of contract collaborator is being proposed for
    /// @param collaborator     Address of proposed collaborator
    /// @param percentOfBounty  Percent of bounty offered for collaboration
    event CollaborationProposed(address indexed auditedContract, address collaborator, uint256 percentOfBounty);

    /// @notice                 Emitted after collaboration has been accepted
    /// @param auditedContract  Address of contract collaboration is being accepted for
    /// @param collaborator     Address of collaborator accepting
    /// @param percentOfBounty  Percent of bounty collaborator is accepting
    event CollaborationAccepted(address indexed auditedContract, address collaborator, uint256 percentOfBounty);

    /// @notice        Emitted after max number of audits for auditor set
    /// @param oldMax  Old max audits for auditor
    /// @param newMax  New max audits for auditor
    event MaxAuditsSet(uint256 oldMax, uint256 newMax);

    /// @notice           Emitted after time to roll over is updated
    /// @param oldPeriod  Old roll over period
    /// @param newPeriod  New roll over period
    event TimeToRollOverSet(uint256 oldPeriod, uint256 newPeriod);

    /// @notice         Emitted after auditor has been added
    /// @param auditor  Address of auditor being added
    event AuditorAdded(address auditor);

    /// @notice         Emitted after auditor has been removed
    /// @param auditor  Address of auditor being removed
    event AuditorRemoved(address auditor);

    /// @notice               Emitted after ownership has been transfered
    /// @param previousOwner  Address of previous owner
    /// @param newOwner       Address of new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// ERRORS ///

    /// @notice Error for if trying to pick up an audit with no bounty
    error NoBountyAdded();
    /// @notice Error for if invalid level
    error InvalidLevel();
    /// @notice Error for if auditor has already been assigned
    error AuditorAssigned();
    /// @notice Error for if audit has not been failed
    error AuditNotFailed();
    /// @notice Error for if audit has been rolled over
    error AuditRolledOver();
    /// @notice Error for if the address is not the owner
    error NotOwner();
    /// @notice Error for if not approved auditor
    error NotApprovedAuditor();
    /// @notice Error for only auditor
    error OnlyAuditor();
    /// @notice Error for only developer
    error OnlyDeveloper();
    /// @notice Error for if contract is not being audited
    error NotBeingAudited();
    /// @notice Error for if audit has not been passed
    error NotPassed();
    /// @notice Error for if feedback has already been given
    error FeedbackGiven();
    /// @notice Error for if contract is already in system
    error AlreadyInSystem();
    /// @notice Error for invalid audit result
    error InvalidResult();
    /// @notice Error for if address is not a contact
    error NotAContract();
    /// @notice Error for if collaboration has already been accepted
    error CollaborationAlreadyAccepted();
    /// @notice Error for if trying to lower collaboration bounty offer
    error CanNotLowerOfferedBounty();
    /// @notice Error for if trying to give away more of bounty than available
    error MoreThanCanGiveAway();
    /// @notice Error for if collaboration proposal has expired
    error OfferExpired();
    /// @notice Error for if address already owns POD NFT
    error AlreadyOwnPOD();
    /// @notice Error for if submitting audit and does not own POD NFT
    error DoesNotOwnPODNFT();
    /// @notice Error for if max amount of audits have already been picked up by auditor
    error MaxAuditsInProgress();
    /// @notice Error for if roll over period is still active
    error RollOverStillActive();
    /// @notice Error for if invalid previous
    error InvalidPrevious();

    /// STRUCTS ///

    enum STATUS {
        NOTAUDITED,
        PENDING,
        PASSED,
        FAILED
    }

    /// @notice                  Details of audited contract
    /// @param auditor           Address of auditor
    /// @param developer         Address of developer
    /// @param status            Status of audit
    /// @param auditDescription  Description of audit results
    /// @param feedback          Bool if feedback has been given to auditor
    struct AuditedContract {
        address auditor;
        address developer;
        STATUS status;
        string auditDescription;
        bool feedback;
    }

    /// @notice                  Details of auditor
    /// @param auditsInProgress  Number of audits in progress
    /// @param positiveFeedback  Number of positive feedback for auditor
    /// @param negativeFeedbac   Number of negative feedback for auditor
    /// @param mintedLevel       Minted level for auditor
    struct Auditor {
        uint256 auditsInProgress;
        uint256 positiveFeedback;
        uint256 negativeFeedback;
        uint256 mintedLevel;
    }

    /// @notice               Details of collaboration
    /// @param bountyPercent  Percent of bounty collaborator will receive
    /// @param expiries       Time collaboration proposal expiries
    /// @param accepted       Bool if collaborator has accepted
    struct Collaboration {
        uint256 bountyPercent;
        uint256 expiries;
        bool accepted;
    }

    /// STATE VARIABLES ///

    /// @notice Fee percent for Hyacinth
    uint256 public constant HYACINTH_FEE = 25;
    /// @notice Fee amount to mint POD NFT
    uint256 public constant POD_MINT_FEE = 100000000;
    /// @notice Max number of audits an auditor can pick up at one time
    uint256 public maxAuditsForAuditor;
    /// @notice Amount of time dev has to roll over audit until auditor can claim bounty
    uint256 public timeToRollOver;

    /// @notice Address of owner
    address public owner;

    /// @notice Address of hyacinth wallet
    address public immutable hyacinthWallet;
    /// @notice Address of USDC
    address public immutable USDC;
    /// @notice Address of proof of developer NFT
    IProofOfDeveloper public immutable proofOfDeveloper;
    /// @notice Address of proof of auditor NFT
    IProofOfAuditor public immutable proofOfAuditor;

    /// @notice Amount of audits completed at each level for auditor
    mapping(address => uint256[4]) internal _levelsCompleted;

    /// @notice Audit details of address
    mapping(address => AuditedContract) public audits;
    /// @notice Auditor details of auditor
    mapping(address => Auditor) public auditors;
    /// @notice Bool if address is an approved auditor
    mapping(address => bool) public approvedAuditor;
    /// @notice Percent of bounty given to collaborators
    mapping(address => uint256) public percentGivenForCollab;
    /// @notice Time rollover of bounty is active till
    mapping(address => uint256) public timeRollOverActive;
    /// @notice Developer wallet contract of developer
    mapping(address => address) public developerWalletContract;
    /// @notice Address failed audit rolled over to
    mapping(address => address) public rolledOverAddress;
    /// @notice Array of collaborators for audited contract
    mapping(address => address[]) public collaborators;
    /// @notice Array of fees collaborators receive
    mapping(address => uint256[]) public collaboratorsPercentOfBounty;
    /// @notice Collaboration details of a contract being audited of a collaborator
    mapping(address => mapping(address => Collaboration)) public collaboration;
    /// @notice Bool if address is an approved auditor for developer
    mapping(address => mapping(address => bool)) public approvedAuditorForDev;

    /// CONSTRUCTOR ///

    /// @param hyacinthWallet_  Address of hyacinth wallet
    /// @param owner_           Address of owner
    /// @param pod_             Address of proof of developer NFT
    /// @param poa_             Address of proof of auditor NFT
    /// @param usdc_            Address of USDC
    constructor(
        address hyacinthWallet_,
        address owner_,
        address pod_,
        address poa_,
        address usdc_
    ) {
        hyacinthWallet = hyacinthWallet_;
        owner = owner_;
        proofOfDeveloper = IProofOfDeveloper(pod_);
        proofOfAuditor = IProofOfAuditor(poa_);
        USDC = usdc_;
    }

    /// AUDIT FUNCTION ///

    /// @notice           Adding contract to audit database
    /// @param previous_  Address of previous contract if audited failed (zero address if not)
    function beingAudited(address previous_) external {
        if (proofOfDeveloper.balanceOf(tx.origin) == 0) revert DoesNotOwnPODNFT();
        AuditedContract memory audit_ = audits[msg.sender];
        if (audit_.status != STATUS.NOTAUDITED) revert AlreadyInSystem();
        if (msg.sender == tx.origin) revert NotAContract();
        if (
            previous_ != address(0) &&
            (timeRollOverActive[previous_] <= block.timestamp || audits[previous_].developer != tx.origin)
        ) revert InvalidPrevious();

        audit_.developer = tx.origin;
        audit_.status = STATUS.PENDING;
        audits[msg.sender] = audit_;

        if (previous_ != address(0)) {
            audits[msg.sender].auditor = audits[previous_].auditor;
            collaborators[msg.sender] = collaborators[previous_];
            collaboratorsPercentOfBounty[msg.sender] = collaboratorsPercentOfBounty[previous_];
            percentGivenForCollab[msg.sender] = percentGivenForCollab[previous_];
            rolledOverAddress[previous_] = msg.sender;
            IDeveloperWallet(developerWalletContract[tx.origin]).rollOverBounty(previous_, msg.sender);
        }

        emit AuditAdded(msg.sender, previous_, tx.origin);
    }

    /// DEVELOPER FUNCTION ///

    /// @notice                   Function that allow address to mint POD NFT
    /// @return id_               POD id minted
    /// @return developerWallet_  Addressof developer wallet contract
    function mintPOD() external returns (uint256 id_, address developerWallet_) {
        IERC20(USDC).transferFrom(msg.sender, hyacinthWallet, POD_MINT_FEE);
        if (proofOfDeveloper.balanceOf(msg.sender) > 0) revert AlreadyOwnPOD();
        else (id_, developerWallet_) = proofOfDeveloper.mint(msg.sender);
        developerWalletContract[msg.sender] = developerWallet_;

        emit PODMinted(msg.sender, id_);
    }

    /// @notice           Function that adds addresses to be approved to audit for a dev
    /// @param auditors_  Array of addresses to add as approved auditor for a dev
    function addApprovedAuditor(address[] calldata auditors_) external {
        if (proofOfDeveloper.balanceOf(msg.sender) == 0) revert DoesNotOwnPODNFT();

        for (uint256 i; i < auditors_.length; ++i) {
            if (!approvedAuditor[auditors_[i]]) revert NotApprovedAuditor();
            approvedAuditorForDev[msg.sender][auditors_[i]] = true;
        }
    }

    /// @notice           Function that removes addresses from being approved to audit for a dev
    /// @param auditors_  Array of addresses to remove as approved auditor for a dev
    function removeApprovedAuditor(address[] calldata auditors_) external {
        if (proofOfDeveloper.balanceOf(msg.sender) == 0) revert DoesNotOwnPODNFT();

        for (uint256 i; i < auditors_.length; ++i) {
            approvedAuditorForDev[msg.sender][auditors_[i]] = false;
        }
    }

    /// @notice           Function that allows developer to give feedback to auditor
    /// @param contract_  Address of contract audit feedback given for
    /// @param positive_  Bool if positive or negative feedback
    function giveAuditorFeedback(address contract_, bool positive_) external {
        AuditedContract memory audit_ = audits[contract_];

        if (audit_.status != STATUS.PASSED) revert NotPassed();
        if (audit_.developer != msg.sender) revert OnlyDeveloper();
        if (audit_.feedback) revert FeedbackGiven();

        audits[contract_].feedback = true;

        if (positive_) ++auditors[audit_.auditor].positiveFeedback;
        else ++auditors[audit_.auditor].negativeFeedback;
    }

    /// AUDITOR FUNCTION ///

    /// @notice           Function that allows approved auditor to pick up audit
    /// @param contract_  Address of contract auditor is picking up audit for
    function pickUpAudit(address contract_) external {
        AuditedContract memory audit_ = audits[contract_];

        if (audit_.auditor != address(0)) revert AuditorAssigned();
        uint256 idHeld_ = proofOfAuditor.idHeld(msg.sender);
        uint256 auditorLevel_ = proofOfAuditor.level(idHeld_);
        (uint256 bountyLevel_, uint256 bounty_) = IDeveloperWallet(developerWalletContract[audit_.developer])
            .currentBountyLevel(contract_);

        if (bounty_ == 0) revert NoBountyAdded();

        if (
            !approvedAuditor[msg.sender] ||
            (!approvedAuditorForDev[audit_.developer][msg.sender] && bountyLevel_ != 0) ||
            auditorLevel_ < bountyLevel_
        ) revert NotApprovedAuditor();
        Auditor memory auditor_ = auditors[msg.sender];
        if (maxAuditsForAuditor <= auditor_.auditsInProgress) revert MaxAuditsInProgress();

        ++auditors[msg.sender].auditsInProgress;
        audits[contract_].auditor = msg.sender;

        emit AuditPickedUp(msg.sender, contract_);
    }

    /// @notice              Auditor submits the `result_` of `contract_`
    /// @param contract_     Address of the contract
    /// @param result_       Result of the audit
    /// @param description_  Desecription of the audit
    function submitResult(
        address contract_,
        STATUS result_,
        string memory description_
    ) external {
        AuditedContract memory audit_ = audits[contract_];
        if (audit_.status != STATUS.PENDING) revert NotBeingAudited();
        if (audit_.auditor != msg.sender) revert OnlyAuditor();
        if (result_ != STATUS.PASSED && result_ != STATUS.FAILED) revert InvalidResult();
        audit_.status = result_;
        audit_.auditDescription = description_;
        audits[contract_] = audit_;

        if (result_ == STATUS.PASSED) {
            uint256 level_ = _payBounty(contract_, developerWalletContract[audit_.developer]);
            ++_levelsCompleted[audit_.auditor][level_];
        } else {
            timeRollOverActive[contract_] = block.timestamp + timeToRollOver;
        }

        emit ResultSubmitted(audit_.auditor, audit_.developer, contract_, result_);
    }

    /// @notice           Function that pays out bounty if roll over has expired
    /// @param contract_  Contract to pay out bounty for
    function rollOverExpired(address contract_) external {
        AuditedContract memory audit_ = audits[contract_];
        if (audit_.status != STATUS.FAILED) revert AuditNotFailed();
        if (audit_.auditor != msg.sender) revert OnlyAuditor();
        if (timeRollOverActive[contract_] > block.timestamp) revert RollOverStillActive();
        if (rolledOverAddress[contract_] != address(0)) revert AuditRolledOver();

        _payBounty(contract_, developerWalletContract[audit_.developer]);
    }

    /// @notice                  Function that allows an auditor of a contract to propose a collaboration
    /// @param contract_         Address of the contract being audited
    /// @param collaborator_     Address of collaborator
    /// @param timeLive_         Time the collaboration proposal will be live for
    /// @param percentOfBounty_  Percent of bounty `collaborator_` will receive
    function proposeCollaboration(
        address contract_,
        address collaborator_,
        uint256 timeLive_,
        uint256 percentOfBounty_
    ) external {
        AuditedContract memory audit_ = audits[contract_];
        if (audit_.status != STATUS.PENDING) revert NotBeingAudited();
        if (audit_.auditor != msg.sender) revert OnlyAuditor();
        if (!approvedAuditor[collaborator_]) revert NotApprovedAuditor();
        if (percentGivenForCollab[contract_] + percentOfBounty_ > 100) revert MoreThanCanGiveAway();

        Collaboration memory collaboration_ = collaboration[contract_][collaborator_];
        if (collaboration_.accepted) revert CollaborationAlreadyAccepted();
        if (collaboration_.bountyPercent > percentOfBounty_ || percentOfBounty_ == 0) revert CanNotLowerOfferedBounty();

        collaboration_.expiries = block.timestamp + timeLive_;
        collaboration_.bountyPercent = percentOfBounty_;

        collaboration[contract_][collaborator_] = collaboration_;

        emit CollaborationProposed(contract_, collaborator_, percentOfBounty_);
    }

    /// @notice           Function that allows a collaborator of a contract to accept a collaboration
    /// @param contract_  Address of the contract collaboration is being audited
    function acceptCollaboration(address contract_) external {
        Collaboration memory colloboration_ = collaboration[contract_][msg.sender];

        if (colloboration_.accepted) revert CollaborationAlreadyAccepted();
        if (colloboration_.expiries < block.timestamp) revert OfferExpired();
        if (percentGivenForCollab[contract_] + colloboration_.bountyPercent > 100) revert MoreThanCanGiveAway();

        collaboration[contract_][msg.sender].accepted = true;
        percentGivenForCollab[contract_] += colloboration_.bountyPercent;
        collaborators[contract_].push(msg.sender);
        collaboratorsPercentOfBounty[contract_].push(colloboration_.bountyPercent);

        emit CollaborationAccepted(contract_, msg.sender, colloboration_.bountyPercent);
    }

    /// OWNER FUNCTION ///

    /// @notice           Transfer ownership of contract
    /// @param newOwner_  Address of the new owner
    function transferOwnership(address newOwner_) external {
        if (msg.sender != owner) revert NotOwner();
        address oldOwner_ = owner;
        owner = newOwner_;

        emit OwnershipTransferred(oldOwner_, newOwner_);
    }

    /// @notice                 Set roll over time for failed audit
    /// @param timeToRollOver_  New roll over time for failed audit
    function setTimeToRollOver(uint256 timeToRollOver_) external {
        if (msg.sender != owner) revert NotOwner();
        uint256 oldPeriod_ = timeToRollOver;
        timeToRollOver = timeToRollOver_;

        emit TimeToRollOverSet(oldPeriod_, timeToRollOver_);
    }

    /// @notice            Set max number of audits
    /// @param maxAudits_  New max number of audits for auditor
    function setMaxAuditsForAuditor(uint256 maxAudits_) external {
        if (msg.sender != owner) revert NotOwner();
        uint256 oldMax_ = maxAuditsForAuditor;
        maxAuditsForAuditor = maxAudits_;

        emit MaxAuditsSet(oldMax_, maxAudits_);
    }

    /// @notice           Add auditor
    /// @param auditor_   Address to add as auditor
    /// @param baseLevel_  Base level to give `auditor_`
    /// @return id_       Id of POA for `auditor_`
    function addAuditor(address auditor_, uint256 baseLevel_) external returns (uint256 id_) {
        if (msg.sender != owner) revert NotOwner();
        if (baseLevel_ > 3) revert InvalidLevel();

        if (proofOfAuditor.balanceOf(auditor_) == 0) {
            id_ = proofOfAuditor.mint(auditor_);
        } else id_ = proofOfAuditor.idHeld(auditor_);

        auditors[auditor_].mintedLevel = baseLevel_;
        approvedAuditor[auditor_] = true;

        emit AuditorAdded(auditor_);
    }

    /// @notice          Remove auditor
    /// @param auditor_  Address to remove as auditor
    function removeAuditor(address auditor_) external {
        if (msg.sender != owner) revert NotOwner();
        approvedAuditor[auditor_] = false;

        emit AuditorRemoved(auditor_);
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice                  Internal function that pays out bounty
    /// @param contract_         Contract to pay bounty for
    /// @param developerWallet_  Developer wallet contract
    function _payBounty(address contract_, address developerWallet_) internal returns (uint256 level_) {
        address[] memory collaborators_ = collaborators[contract_];
        uint256[] memory percentsOfBounty_ = collaboratorsPercentOfBounty[contract_];

        level_ = IDeveloperWallet(developerWallet_).payOutBounty(contract_, collaborators_, percentsOfBounty_);

        --auditors[msg.sender].auditsInProgress;
    }

    /// EXTERNAL VIEW FUNCTIONS ///

    /// @notice                   Returns amount of audits completed at each level for `auditorAdderss_`
    /// @param auditorAddress_    Address of auditor
    /// @return levelsCompleted_  Array of levels of audits completed for `auditorAddress_`
    function levelsCompleted(address auditorAddress_) external view returns (uint256[4] memory levelsCompleted_) {
        return (_levelsCompleted[auditorAddress_]);
    }
}