// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./PledgeEvent.sol";
import "./MilestoneOwner.sol";
import "../token/IMintableOwnedERC20.sol";
import "../milestone/MilestoneResult.sol";
import "../milestone/Milestone.sol";
import "../milestone/MilestoneApprover.sol";
import "../vault/IVault.sol";
import "../utils/InitializedOnce.sol";
import "./ProjectState.sol";
import "./IProject.sol";
import "./ProjectInitParams.sol";
import "../libs/Sanitizer.sol";


contract Project is IProject, MilestoneOwner, ReentrancyGuard, Pausable, InitializedOnce  {

    using SafeCast for uint;


    uint public constant MAX_NUM_SINGLE_EOA_PLEDGES = 20;

    address public platformAddr;

    address public delegate;

    ProjectState public projectState = ProjectState.IN_PROGRESS;


    uint public projectStartTime; //not here! = block.timestamp;

    uint public projectEndTime;

    uint public minPledgedSum;

    IVault public projectVault;
    IMintableOwnedERC20 public projectToken;

    uint public onChangeExitGracePeriod;
    uint public pledgerGraceExitWaitTime;
    uint public platformCutPromils;

    bytes32 public metadataCID;

    uint public current_endOfGracePeriod;

    mapping (address => PledgeEvent[]) public pledgerAddrToEventMap;

    uint public numPledgersSofar;

    uint public totalNumPledgeEvents;

    OnFailureRefundParams public onFailureRefundParams;

    //---


    struct OnFailureRefundParams {
        bool exists;
        uint totalPTokInVault;
        uint totalAllPledgerPTok;
    }

    modifier openForNewPledges() {
        _requireNotPaused();
        _;
    }

    modifier onlyIfExeedsMinPledgeSum( uint numPaymentTokens_) {
        require( numPaymentTokens_ >= minPledgedSum, "pledge must exceed min token count");
        _;
    }

    modifier onlyIfSenderHasSufficientTokenBalance( uint numPaymentTokens_) {
        uint tokenBalanceOfPledger_ = IERC20( paymentTokenAddress).balanceOf( msg.sender);
        require( tokenBalanceOfPledger_ >= numPaymentTokens_, "pledger has insufficient token balance");
        _;
    }

    modifier onlyIfSufficientTokenAllowance( uint numPaymentTokens_) {
        require( _paymentTokenAllowanceFromSender() >= numPaymentTokens_, "modifier: insufficient allowance");
        _;
    }

    modifier onlyIfProjectFailed() {
        require( projectState == ProjectState.FAILED, "project running");
        require( projectEndTime > 0, "bad end date"); // sanity check
        _;
    }

    modifier onlyIfProjectSucceeded() {
        require( projectState == ProjectState.SUCCEEDED, "project not succeeded");
        require( projectEndTime > 0, "bad end date"); // sanity check
        _;
    }

    modifier projectIsInGracePeriod() {
        if (block.timestamp > current_endOfGracePeriod) {
            revert PledgerGraceExitRefusedOverdue( block.timestamp, current_endOfGracePeriod);
        }
        _;
    }


    modifier onlyIfTeamWallet() { // == onlyOwner
        require(owner == msg.sender, "onlyIfTeamWallet: caller is not the owner");
        _;
    }

    modifier onlyIfProjectCompleted() {
        require( projectState != ProjectState.IN_PROGRESS, "project not completed");
        require( projectEndTime > 0, "bad end date"); // sanity check
        _;
    }

    modifier ownerOrDelegate() { //@gilad
        if (msg.sender != owner && msg.sender != delegate) {
            revert OnlyOwnerOrDelegateCanPerformAction(msg.sender, owner, delegate);
        }
        _;
    }

    modifier onlyIfPledger() {
        require( isActivePledger(msg.sender), "not a pledger");
        _;
    }

    modifier onlyIfPlatform() {
        require( msg.sender == platformAddr, "not platform");
        _;
    }


    /*
     * @title initialize()
     *
     * @dev called by the platform (= owner) to initialize a _new contract proxy instance cloned from the project template
     *
     * @event: none
     */
    function initialize( ProjectInitParams memory params_) external override  onlyIfNotInitialized {
        markAsInitialized( params_.projectTeamWallet);

        require( params_.paymentToken != address(0), "missing payment token");

        platformAddr = msg.sender;

        projectStartTime = block.timestamp;
        projectState = ProjectState.IN_PROGRESS;
        delegate = address(0);
        projectEndTime = 0;
        current_endOfGracePeriod = 0;
        onFailureRefundParams =  OnFailureRefundParams( false, 0, 0);
        paymentTokenAddress = params_.paymentToken;

        // make sure that the template contract does not contain pledges i.e. pledgerAddrToEventMap is empty
        require( numPledgersSofar == 0, "numPledgersSofar == 0");
        require( totalNumPledgeEvents == 0, "totalNumPledgeEvents == 0");

        _updateProject( params_.milestones, params_.minPledgedSum);

        projectVault = params_.vault;
        projectToken = params_.projectToken;
        platformCutPromils = params_.platformCutPromils;
        onChangeExitGracePeriod = params_.onChangeExitGracePeriod;
        pledgerGraceExitWaitTime = params_.pledgerGraceExitWaitTime;
        metadataCID = params_.cid;
    }

    //---------


    event PledgerGraceExitWaitTimeChanged( uint newValue, uint oldValue);

    event NewPledgeEvent(address pledger, uint sum);

    event GracePeriodPledgerRefund( address pledger, uint shouldBeRefunded, uint actuallyRefunded);

    event TransferProjectTokensToPledgerOnProjectSuccess( address pledger, uint numTokens);

    event TeamWalletRenounceOwnership();

    event ProjectFailurePledgerRefund( address pledger, uint shouldBeRefunded, uint actuallyRefunded);

    event TokenOwnershipTransferredToTeamWallet( address indexed projectContract, address indexed teamWallet);

    event ProjectStateChanged( ProjectState newState, ProjectState oldState);

    event ProjectDetailedWereChanged(uint changeTime, uint endOfGracePeriod);

    event MinPledgedSumWasSet(uint newMinPledgedSum, uint oldMinPledgedSum);

    event NewPledger(address indexed addr, uint indexed numPledgersSofar, uint indexed sum_);

    event DelegateChanged(address indexed newDelegate, address indexed oldDelegate);

    event TeamWalletChanged(address newWallet, address oldWallet);

    event OnFinalPTokRefundOfPledger( address indexed pledgerAddr_, uint32 pledgerEnterTime, uint refundSum_);

    event OnProjectSucceeded(address indexed projectAddress, uint endTime);

    event OnProjectFailed( address indexed projectAddress, uint endTime);


    //---------


    error PledgeMustExceedMinValue( uint numPaymentTokens, uint minPledgedSum);

    error MaxMuberOfPedgesPerEOAWasReached( address  pledgerAddr, uint maxNumEOAPledges);

    error MissingPledgrRecord( address  addr);

    error CallerNotAPledger( address caller);

    error BadRewardType( OnSuccessReward rewardType);

    error PledgerAlreadyExist(address addr);

    error OnlyOwnerOrDelegateCanPerformAction(address msgSender, address owner, address delegate);

    error PledgerMinRequirementNotMet(address addr, uint value, uint minValue);

    error OperationCannotBeAppliedToRunningProject(ProjectState projectState);

    error OperationCannotBeAppliedWhileFundsInVault(uint fundsInVault);

    error PledgerGraceExitRefusedOverdue( uint exitRequestTime, uint endOfGracePeriod);

    error PledgerGraceExitRefusedTooSoon( uint exitRequestTime, uint exitAllowedStartTime);

    error MilestoneIsNotOverdue(uint milestoneIndex, uint time);

    //---------

    function getProjectStartTime() external override view returns(uint) {
        return projectStartTime;
    }

/*
 * @title setDelegate()
 *
 * @dev sets a delegate account to be used for some management actions interchangeably with the team wallet account
 *
 * @event: DelegateChanged
 */
    function setDelegate(address newDelegate) external
                                onlyIfTeamWallet onlyIfProjectNotCompleted /* not ownerOrDelegate! */ { //@PUBFUNC
        // possibly address(0)
        address oldDelegate_ = delegate;
        delegate = newDelegate;
        emit DelegateChanged(delegate, oldDelegate_);
    }

/*
 * @title updateProjectDetails()
 *
 * @dev updating project details with milestone list and minPledgedSu, immediately entering pledger-exit grace period
 *
 * @event: ProjectDetailedWereChanged
 */ //@DOC5
    function updateProjectDetails( Milestone[] memory milestones_, uint minPledgedSum_)
                                                        external ownerOrDelegate onlyIfProjectNotCompleted { //@PUBFUNC
        _updateProject(milestones_, minPledgedSum_);

        // TODO > this func must not change history items: pledger list, accomplished milestones,...

        current_endOfGracePeriod = block.timestamp + onChangeExitGracePeriod;
        emit ProjectDetailedWereChanged(block.timestamp, current_endOfGracePeriod);
    }

/*
 * @title setMinPledgedSum()
 *
 * @dev sets the minimal amount of payment-tokens deposit for future pledgers. No effect on existing pledgers
 *
 * @event: MinPledgedSumWasSet
 */
    function setMinPledgedSum(uint newMin) external ownerOrDelegate onlyIfProjectNotCompleted { //@PUBFUNC
        uint oldMin_ = minPledgedSum;
        minPledgedSum = newMin;
        emit MinPledgedSumWasSet(minPledgedSum, oldMin_);
    }

    function getOwner() public view override(IProject,InitializedOnce) returns (address) {
        return InitializedOnce.getOwner();
    }


/*
 * @title setTeamWallet()
 *
 * @dev allow  current project owner a.k.a. team wallet to change its address
 *  Internally handled by contract-ownershiptransfer= transferOwnership()
 *
 * @event: TeamWalletChanged
 */
    function setTeamWallet(address newWallet) external onlyIfTeamWallet onlyIfProjectNotCompleted /* not ownerOrDelegate! */ { //@PUBFUNC
        changeOwnership( newWallet);
    }

    function setPledgerWaitTimeBeforeGraceExit(uint newWaitTime) external onlyIfTeamWallet onlyIfProjectNotCompleted { //@PUBFUNC
        // will only take effect on future projects
        uint oldWaitTime_ = pledgerGraceExitWaitTime;
        pledgerGraceExitWaitTime = newWaitTime;
        emit PledgerGraceExitWaitTimeChanged( pledgerGraceExitWaitTime, oldWaitTime_);
    }

/*
 * @title clearTeamWallet()
 *
 * @dev allow  project owner = team wallet to renounce Ownership on project by setting owner address to null
 *  Can only be applied for a completed project with zero internal funds
 *
 * @event: TeamWalletRenounceOwnership
 */
    function clearTeamWallet() external onlyOwner onlyIfProjectCompleted  { //@PUBFUNC
        if ( !projectIsCompleted()) {
            revert OperationCannotBeAppliedToRunningProject(projectState);
        }

        uint vaultBalance_ = projectVault.vaultBalance();
        if (vaultBalance_ > 0) {
            revert OperationCannotBeAppliedWhileFundsInVault(vaultBalance_);
        }

        // renounce ownership:
        renounceOwnership();

        emit TeamWalletRenounceOwnership();
    }

    /*
     * @title newPledge()
     *
     * @dev allow a _new pledger to enter the project
     *  This method is issued by the pledger with passed payment-token sum >= minPledgedSum
     *  Creates a pledger entry (if first time) and adds a plede event containing payment-token sum and date
     *  All incoming payment-token will be moved to project vault
     *
     *  Note: This function will NOT check for on-chain target completion (num-pledger, pledged-total)
     *         since that will require costly milestone iteration.
     *         Rather, the backend code should externally invoke the relevant onchain-milestone services:
     *           checkIfOnchainTargetWasReached() and onMilestoneOverdue()
     *         Max number of pledger events per single pledger: MAX_NUM_SINGLE_EOA_PLEDGES
     *
     * @precondition: caller (msg.sender) meeds to approve at least numPaymentTokens_ for this function to succeed
     *
     *
     * @event: NewPledger, NewPledgeEvent
     *
     * @CROSS_REENTRY_PROTECTION
     */ //@DOC2
    function newPledge(uint numPaymentTokens_, address paymentTokenAddr_)
                                        external openForAll openForNewPledges
                                        onlyIfExeedsMinPledgeSum( numPaymentTokens_)
                                        onlyIfSenderHasSufficientTokenBalance( numPaymentTokens_)
                                        onlyIfSufficientTokenAllowance( numPaymentTokens_)
                                        onlyIfProjectNotCompleted nonReentrant { //@PUBFUNC //@PTokTransfer //@PLEDGER
        verifyInitialized();

        address newPledgerAddr_ = msg.sender;

        require( paymentTokenAddr_ == paymentTokenAddress, "bad payment token");

        bool pledgerAlreadyExists = isActivePledger( newPledgerAddr_);

        if (pledgerAlreadyExists) {
            verifyMaxNumPledgesNotExceeded( newPledgerAddr_);
        } else {
            emit NewPledger( newPledgerAddr_, numPledgersSofar, numPaymentTokens_);
            numPledgersSofar++;
        }

        _addNewPledgeEvent( newPledgerAddr_, numPaymentTokens_);

        _transferPaymentTokensToVault( numPaymentTokens_);
    }


    function _paymentTokenAllowanceFromSender() view private returns(uint) {
        IERC20 paymentToken_ = IERC20( paymentTokenAddress);
        return paymentToken_.allowance( msg.sender, address(this) );
    }


    function _transferPaymentTokensToVault( uint numPaymentTokens_) private {
        address pledger_ = msg.sender;
        IERC20 paymentToken_ = IERC20( paymentTokenAddress);

        require( _paymentTokenAllowanceFromSender() >= numPaymentTokens_, "insufficient token allowance");

        bool transferred_ = paymentToken_.transferFrom( pledger_, address(projectVault), numPaymentTokens_);
        require( transferred_, "Failed to transfer payment tokens to vault");

        projectVault.increaseBalance( numPaymentTokens_);
    }


    function verifyMaxNumPledgesNotExceeded( address addr) private view {
        if (pledgerAddrToEventMap[addr].length >= MAX_NUM_SINGLE_EOA_PLEDGES) {
            revert MaxMuberOfPedgesPerEOAWasReached( addr, MAX_NUM_SINGLE_EOA_PLEDGES);
        }
    }

    function _addNewPledgeEvent( address existingPledgerAddr_, uint numPaymentTokens_) private {
        uint32 now_ = block.timestamp.toUint32();

        pledgerAddrToEventMap[ existingPledgerAddr_].push( PledgeEvent({ date: now_, sum: numPaymentTokens_ }));

        totalNumPledgeEvents++;

        emit NewPledgeEvent( existingPledgerAddr_, numPaymentTokens_);
    }

    function projectIsCompleted() public view returns(bool) {
        // either with success or failure
        return (projectState != ProjectState.IN_PROGRESS);
    }

/*
 * @title onMilestoneOverdue()
 *
 * @dev Allows 'all' to inform the project on an overdue milestone - either external of onchain,resulting on project failure
 * Project must be not-completed
 *
 * @event: MilestoneIsOverdueEvent
 */ //@DOC4
    function onMilestoneOverdue(uint milestoneIndex_) external openForAll onlyIfProjectNotCompleted  {//@PUBFUNC: also notPaused??
        verifyInitialized();

        uint initial_numCompleted = successfulMilestoneIndexes.length;

        Milestone storage milestone_ = milestoneArr[ milestoneIndex_];

        if ( !_failIfOverdue( milestoneIndex_, milestone_)) {
            revert MilestoneIsNotOverdue( milestoneIndex_, block.timestamp);
        }

        emit MilestoneIsOverdueEvent( milestoneIndex_, milestoneArr[ milestoneIndex_].dueDate, block.timestamp);

        _onProjectFailed();

        require( successfulMilestoneIndexes.length <= initial_numCompleted+1, "single milestone at most");
    }

    enum OnSuccessReward { TOKENS, NFT }

/*
 * @title transferProjectTokensToPledgerOnProjectSuccess()
 *
 * @dev allows a pledger to receive, on project success, to receive his due in erc20 project tokens
 *
 * @event: TransferProjectTokensToPledgerOnProjectSuccess
 * @CROSS_REENTRY_PROTECTION
 */ //@DOC8
    function transferProjectTokensToPledgerOnProjectSuccess() external
                                        onlyIfPledger onlyIfProjectSucceeded nonReentrant { //@PUBFUNC //@PLEDGER
        //@PLEDGERS_CAN_WITHDRAW_PROJECT_TOKENS
        (uint numTokens_, ) = _transferTokensOnSuccess( OnSuccessReward.TOKENS); // @DELETE_PLEDGER
        emit TransferProjectTokensToPledgerOnProjectSuccess( msg.sender, numTokens_);
    }

    function getNumTokensToPledgerOnProjectSuccess(address pledgerAddr_) external view returns(uint) {
        return _calcProjectTokensToPledger( pledgerAddr_);
    }

    /*
     * @title transferProjectTokenOwnershipToTeam()
     *
     * @dev Allows the project team account to regain ownership on the erc20 project token after project is completed
     *  Transfer project token ownership from the project contract (= address(this)) to the team wallet
     *
     * @event: TokenOwnershipTransferredToTeamWallet
     */
    function transferProjectTokenOwnershipToTeam() external
                                            onlyIfTeamWallet onlyIfProjectCompleted { //@PUBFUNC
        address teamWallet_ = getOwner(); // project owner is teamWallet
        address tokenOwner_ = address(this); // token owner is the project contract
        require( projectToken.getOwner() == tokenOwner_, "must be project");

        projectToken.changeOwnership( teamWallet_);

        emit TokenOwnershipTransferredToTeamWallet( tokenOwner_, teamWallet_);
    }


    function _transferTokensOnSuccess( OnSuccessReward rewardType) private
                                            onlyIfPledger onlyIfProjectSucceeded
                                            returns( uint numTokens_, int receiptTokenId_) {
        address pledgerAddr_ = msg.sender;

        numTokens_ = _calcProjectTokensToPledger(pledgerAddr_);

        receiptTokenId_ = -1;

        if (rewardType == OnSuccessReward.TOKENS) {
            _transferTokensToPledger( pledgerAddr_, numTokens_);
        } else {
            revert BadRewardType(rewardType);
        }

        removeActivePledger( pledgerAddr_);

        //@DOS_ATTACK: pledgerAddr_ is assumed to have no motivation for failing trans
    }


    function _transferTokensToPledger( address pledger_, uint numTokens_) private onlyIfProjectSucceeded {
        // TODO mint makes more sense than transfer:

        require( projectToken.getOwner() == address(this), "must be owned by project");

        uint pre_ = projectToken.balanceOf( pledger_);

        projectToken.mint( pledger_, numTokens_);

        uint post_ = projectToken.balanceOf( pledger_);

        require( post_ == pre_ + numTokens_, "minting failed");
    }



    /*
     * @title onProjectFailurePledgerRefund()
     *
     * @dev Refund pledger with its proportion of payment-token from team vault on failed project. Called by pledger
     * @sideeffect: remove pledger record
     *
     * @event: ProjectFailurePledgerRefund
     * @CROSS_REENTRY_PROTECTION
     */ //@DOC7
    function onProjectFailurePledgerRefund() external
                                    onlyIfPledger onlyIfProjectFailed
                                    nonReentrant /*pledgerWasNotRefunded*/ { //@PUBFUNC //@PLEDGER

        //@PLEDGERS_CAN_WITHDRAW_PTOK
        address pledgerAddr_ = msg.sender;

        require( onFailureRefundParams.exists, "onFailureRefundParams not set");
        require( onFailureRefundParams.totalAllPledgerPTok > 0, "no refunds");

        uint pledgerTotalPTok_ = calcPledgerTotalInvestment( pledgerAddrToEventMap[ pledgerAddr_]);


        //@gilad avoid race condition by using precalc onFailureRefundParams.totalPTokInVault
        uint shouldBeRefunded_ = (pledgerTotalPTok_ * onFailureRefundParams.totalPTokInVault) /
                                        onFailureRefundParams.totalAllPledgerPTok;

        uint actuallyRefunded_ = _pTokRefundToPledger( pledgerAddr_, shouldBeRefunded_);

        emit ProjectFailurePledgerRefund( pledgerAddr_, shouldBeRefunded_, actuallyRefunded_);

        removeActivePledger( pledgerAddr_);
    }

    function calcPledgerTotalInvestment( PledgeEvent[] storage events) private view returns(uint) {
        uint total_ = 0 ;
        for (uint i = 0; i < events.length; i++) {
            total_ += events[i].sum;
        }
        return total_;
    }


    /*
     * @title onGracePeriodPledgerRefund()
     *
     * @dev called by pledger to request full payment-token refund during grace period
     *  Will only be allowed if pledger pledgerExitAllowedStartTime matches Tx time
     *  At Tx successful end the pledger record will be removed form project
     *  Note: that this service will not be available if project has completed, even if before end of grace period
     *
     * @event: GracePeriodPledgerRefund
     * @CROSS_REENTRY_PROTECTION
     */ //@DOC6
    function onGracePeriodPledgerRefund() external
                                onlyIfPledger projectIsInGracePeriod onlyIfProjectNotCompleted
                                nonReentrant /*pledgerWasNotRefunded*/ { //@PUBFUNC //@PLEDGER

        address pledgerAddr_ = msg.sender;

        uint pledgerEnterTime_ = getPledgerEnterTime( pledgerAddr_);

        uint pledgerExitAllowedStartTime = pledgerEnterTime_ + pledgerGraceExitWaitTime;

        if (block.timestamp < pledgerExitAllowedStartTime) {
            revert PledgerGraceExitRefusedTooSoon( block.timestamp, pledgerExitAllowedStartTime);
        }

        projectVault.decreaseTotalDepositsOnPledgerGraceExit( pledgerAddrToEventMap[ pledgerAddr_]);

        uint shouldBeRefunded_ = calcOnGracePeriodPTokRefund( pledgerAddr_);

        uint actuallyRefunded_ = _pTokRefundToPledger( pledgerAddr_, shouldBeRefunded_);

        emit GracePeriodPledgerRefund( pledgerAddr_, shouldBeRefunded_, actuallyRefunded_);

        removeActivePledger( pledgerAddr_);
    }

    function removeActivePledger( address pledgerAddr_) private {
        require( isActivePledger( pledgerAddr_), "not an active pledger");
        uint numPledgeEvents = pledgerAddrToEventMap[ pledgerAddr_].length;

        delete pledgerAddrToEventMap[ pledgerAddr_];

        totalNumPledgeEvents -= numPledgeEvents;

        numPledgersSofar--;
    }


    function getNumEventsForPledger( address pledgerAddr_) external view returns(uint) {
        return pledgerAddrToEventMap[ pledgerAddr_].length;
    }

    function getPledgeEvent( address pledgerAddr_, uint eventIndex_) external view returns(uint32, uint) {
        PledgeEvent storage pledge_ = pledgerAddrToEventMap[ pledgerAddr_][eventIndex_];
        return (pledge_.date, pledge_.sum);
    }

    function getPledgerEnterTime( address pledgerAddr_) private view returns(uint32) {
        return pledgerAddrToEventMap[ pledgerAddr_][0].date; // pledger's enter time =  date of first pledge event
    }

    function getPaymentTokenAddress() public override view returns(address) {
        return paymentTokenAddress;
    }

    //@ITeamWalletOwner
    function getTeamWallet() external override view returns(address) {
        //return teamWallet;
        return getOwner();
    }


    function getVaultBalance() external override view returns(uint) {
        return projectVault.vaultBalance();
    }

    function getVaultAddress() external view returns(address) {
        return address(projectVault);
    }

//--------


    function _intToUint(int intVal) private pure returns(uint) {
        require(intVal >= 0, "cannot convert to uint");
        return uint(intVal);
    }

    function _calcProjectTokensToPledger(address pledgerAddr_ ) private view returns(uint) {
        uint numTokens_ = 0;

        PledgeEvent[] storage pledges_ = pledgerAddrToEventMap[ pledgerAddr_];

        for (uint i = 0; i < pledges_.length; i++) {
            numTokens_ += _TODO_numTokensOnProjectSuccessForSinglePledge( pledges_[i]);
        }
        return numTokens_;
    }

    function _TODO_numTokensOnProjectSuccessForSinglePledge( PledgeEvent storage pledge_) private view returns(uint) {
        return pledge_.sum;
    }


    function calcOnGracePeriodPTokRefund( address pledgerAddr_) public view returns(uint) {

        PledgeEvent[] storage pledges_ = pledgerAddrToEventMap[ pledgerAddr_];

        uint pTokRefund_ = 0;
        for (uint i = 0; i < pledges_.length; i++) {
            pTokRefund_ += _TODO_gracePTokRefundForSinglePledge( pledges_[i], pTokRefund_);
        }
        return pTokRefund_;
    }

    function _TODO_gracePTokRefundForSinglePledge( PledgeEvent storage pledge_, uint alreadyRefunded_)
                                                      private view returns(uint) {
        return _simplePTokRefundForSinglePledge( pledge_, alreadyRefunded_);
    }


    function _simplePTokRefundForSinglePledge( PledgeEvent storage pledge_, uint alreadyRefunded_)
                                                private view returns(uint) {

        // hhhh use bonding curve calculation with projectStartTime & projectEndTime params
        //      https://github.com/oed/bonding-curves/blob/master/contracts/EthPolynomialCurvedToken.sol
        //      https://medium.com/hackernoon/more-price-functions-for-token-bonding-curves-d42b325ca14b
        //      https://medium.com/coinmonks/token-bonding-curves-explained-7a9332198e0e

        uint paymentTokenInVault = projectVault.vaultBalance() - alreadyRefunded_;
        require( totalNumPledgeEvents > 0, "bad numActivePledgers");
        return paymentTokenInVault / totalNumPledgeEvents;
    }


    function _pTokRefundToPledger( address pledgerAddr_, uint shouldBeRefunded_) private returns(uint) {
        // due to project failure or grace-period exit
        uint actuallyRefunded_ = projectVault.transferPaymentTokensToPledger( pledgerAddr_, shouldBeRefunded_); //@PTokTransfer

        uint32 pledgerEnterTime_ = getPledgerEnterTime( pledgerAddr_);

        emit OnFinalPTokRefundOfPledger( pledgerAddr_, pledgerEnterTime_, shouldBeRefunded_);

        return actuallyRefunded_;
    }


    function _setProjectState( ProjectState newState_) private onlyIfProjectNotCompleted {
        ProjectState oldState_ = projectState;
        projectState = newState_;
        emit ProjectStateChanged( projectState, oldState_);
    }

    /// -----


    function getProjectTokenAddress() external view returns(address) {
        return address(projectToken);
    }

    function getProjectState() external view override returns(ProjectState) {
        return projectState;
    }

    function getProjectMetadataCID() external view returns(bytes32) {
        return metadataCID;
    }

    function _projectNotCompleted() internal override view returns(bool) {
        return projectState == ProjectState.IN_PROGRESS;
    }

    function _getProjectVault() internal override view returns(IVault) {
        return projectVault;
    }

    function _getPlatformCutPromils() internal override view returns(uint) {
        return platformCutPromils;
    }

    function _getPlatformAddress() internal override view returns(address) {
        return platformAddr;
    }

    function _getNumPledgersSofar() internal override view returns(uint) {
        return numPledgersSofar;
    }
    //------------


    function _onProjectSucceeded() internal override {
        _setProjectState( ProjectState.SUCCEEDED);

        _terminateGracePeriod();

        require( projectEndTime == 0, "end time already set");
        projectEndTime = block.timestamp;

        emit OnProjectSucceeded(address(this), block.timestamp);

        _transferAllVaultFundsToTeamWallet();

        //@PLEDGERS_CAN_WITHDRAW_PROJECT_TOKENS
    }


    function getOnFailureParams() external view returns (bool,uint,uint) {
        return ( onFailureRefundParams.exists,
                 onFailureRefundParams.totalPTokInVault,
                 onFailureRefundParams.totalAllPledgerPTok);
    }


    function _onProjectFailed() internal override {
        _setProjectState( ProjectState.FAILED);

        _terminateGracePeriod();

        uint totalPTokInVault_ = projectVault.vaultBalance();
        uint totalInvestedPTok_ = projectVault.totalAllPledgerDeposits();

        //zzzz create a refund factor that will be constant to all pledgers
        require( !onFailureRefundParams.exists, "onFailureRefundParams already set");
        onFailureRefundParams = OnFailureRefundParams({ exists: true,
                                                        totalPTokInVault: totalPTokInVault_,
                                                        totalAllPledgerPTok: totalInvestedPTok_ });

        require( projectEndTime == 0, "end time already set");
        projectEndTime = block.timestamp;

        emit OnProjectFailed(address(this), block.timestamp);

        //@PLEDGERS_CAN_WITHDRAW_PTOK
    }


    function _terminateGracePeriod() private {
        current_endOfGracePeriod = 0;
    }

    function getEndOfGracePeriod() external view returns(uint) {
        return current_endOfGracePeriod;
    }

    function _transferAllVaultFundsToTeamWallet() private {
        uint vaultBalance_ = projectVault.vaultBalance();

        // pass platform cut to platform;
        uint platformCut_ = _calcPlatformCut( vaultBalance_);

        //projectVault.transferPaymentTokenToTeamWallet( vaultBalance_, platformCut_, _getPlatformAddress());
        _transferPaymentTokenToTeam( vaultBalance_, platformCut_);
    }

 function isActivePledger(address addr) public view returns(bool) {
        return pledgerAddrToEventMap[ addr].length > 0;
    }

    function mintProjectTokens( address to, uint numTokens) external override onlyIfPlatform { //@PUBFUNC
        projectToken.mint( to, numTokens);
    }

    //-------------- 

    function _updateProject( Milestone[] memory newMilestones, uint newMinPledgedSum) private {
        // historical records (pledger list, successfulMilestoneIndexes...) and immuables
        // (projectVault, projectToken, platformCutPromils, onChangeExitGracePeriod, pledgerGraceExitWaitTime)
        // are not to be touched here

        // gilad: avoid min/max NumMilestones validations while in update
        Sanitizer._sanitizeMilestones( newMilestones, block.timestamp, 0, 0);

        _setMilestones( newMilestones);

        delete successfulMilestoneIndexes; //@DETECT_PROJECT_SUCCESS

        minPledgedSum = newMinPledgedSum;

        // //@gilad -- solve problem of correlating successfulMilestoneIndexes with _new milesones list!
    }

}