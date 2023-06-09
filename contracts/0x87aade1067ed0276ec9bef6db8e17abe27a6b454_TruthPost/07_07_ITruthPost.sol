/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/// @title  The Truth Post: Accurate and Relevant News
/// @author https://github.com/proveuswrong<0xferit, gratestas>
/// @dev    This contract serves as a standard interface among multiple deployments of the Truth Post contracts.
///         You should target this interface contract for interactions, not the concrete contract; otherwise you risk incompatibility across versions.
/// @custom:approvals 0xferit, gratestas
abstract contract ITruthPost {
    string public constant VERSION = "1.2.0";

    enum RulingOptions {
        Tied,
        ChallengeFailed,
        Debunked
    }

    bool isPublishingEnabled = true;
    address payable public TREASURY;
    uint256 public treasuryBalance;
    uint256 public constant NUMBER_OF_RULING_OPTIONS = 2;
    uint256 public constant MULTIPLIER_DENOMINATOR = 1024; // Denominator for multipliers.
    uint256 public LOSER_APPEAL_PERIOD_MULTIPLIER = 512; // Multiplier of the appeal period for losers (any other ruling options) in basis points. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
    uint256 public ARTICLE_WITHDRAWAL_TIMELOCK; // To prevent authors to act fast and escape punishment.
    uint256 public WINNER_STAKE_MULTIPLIER; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points.
    uint256 public LOSER_STAKE_MULTIPLIER; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points.
    uint256 public challengeTaxRate = 16;

    constructor(
        uint256 _articleWithdrawalTimelock,
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        address payable _treasury
    ) {
        ARTICLE_WITHDRAWAL_TIMELOCK = _articleWithdrawalTimelock;
        WINNER_STAKE_MULTIPLIER = _winnerStakeMultiplier;
        LOSER_STAKE_MULTIPLIER = _loserStakeMultiplier;
        TREASURY = _treasury;
    }

    event NewArticle(string articleID, uint8 category, uint256 articleAddress);
    event Debunked(uint256 articleAddress);
    event ArticleWithdrawn(uint256 articleAddress);
    event BalanceUpdate(uint256 articleAddress, uint256 newTotal);
    event TimelockStarted(uint256 articleAddress);
    event Challenge(uint256 indexed articleAddress, address challanger, uint256 disputeID);
    event Contribution(
        uint256 indexed disputeId,
        uint256 indexed round,
        RulingOptions ruling,
        address indexed contributor,
        uint256 amount
    );
    event Withdrawal(
        uint256 indexed disputeId,
        uint256 indexed round,
        RulingOptions ruling,
        address indexed contributor,
        uint256 reward
    );
    event RulingFunded(uint256 indexed disputeId, uint256 indexed round, RulingOptions indexed ruling);
    event OwnershipTransfer(address indexed _newOwner);
    event AdminUpdate(address indexed _newAdmin);
    event WinnerStakeMultiplierUpdate(uint256 indexed _newWinnerStakeMultiplier);
    event LoserStakeMultiplierUpdate(uint256 indexed _newLoserStakeMultiplier);
    event LoserAppealPeriodMultiplierUpdate(uint256 indexed _newLoserAppealPeriodMultiplier);
    event ArticleWithdrawalTimelockUpdate(uint256 indexed _newWithdrawalTimelock);
    event ChallengeTaxRateUpdate(uint256 indexed _newTaxRate);
    event TreasuryUpdate(address indexed _newTreasury);
    event TreasuryBalanceUpdate(uint256 indexed _byAmount);


    /// @notice Submit an evidence.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _evidenceURI IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
    function submitEvidence(uint256 _disputeID, string calldata _evidenceURI) external virtual;

    /// @notice Fund a crowdfunding appeal.
    /// @dev Lets user to contribute funding of an appeal round. Emits Contribution. If fully funded, emits RulingFunded.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _ruling The ruling option to which the caller wants to contribute.
    /// @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
    function fundAppeal(uint256 _disputeID, RulingOptions _ruling) external payable virtual returns (bool fullyFunded);

    /// @notice Publish an article.
    /// @dev    Do not confuse articleID with articleAddress. Emits NewArticle.
    /// @param _articleID Unique identifier of an article in IPFS content identifier format.
    /// @param _category The category code of this new article.
    /// @param _searchPointer Starting point of the search. Find a vacant storage slot before calling this function to minimize gas cost.
    function initializeArticle(
        string calldata _articleID,
        uint8 _category,
        uint80 _searchPointer
    ) external payable virtual;

    /// @notice Increase bounty.
    /// @dev Lets author to increase a bounty of a live article. Emits BalanceUpdate.
    /// @param _articleStorageAddress The address of the article in the storage.
    function increaseBounty(uint80 _articleStorageAddress) external payable virtual;

    /// @notice Initiate unpublishing process.
    /// @dev Lets an author to start unpublishing process. Emits TimelockStarted.
    /// @param _articleStorageAddress The address of the article in the storage.
    function initiateWithdrawal(uint80 _articleStorageAddress) external virtual;

    /// @notice Execute unpublishing.
    /// @dev Executes unpublishing of an article. Emits Withdrew.
    /// @param _articleStorageAddress The address of the article in the storage.
    function withdraw(uint80 _articleStorageAddress) external virtual;

    /// @notice Challenge article.
    /// @dev Challenges the article at the given storage address. Emits Challenge.
    /// @param _articleStorageAddress The address of the article in the storage.
    function challenge(uint80 _articleStorageAddress) external payable virtual;

    /// @notice Transfer ownership of an article.
    /// @dev Lets you to transfer ownership of an article. 
    ///      This is useful when you want to change owner account without withdrawing and resubmitting. 
    ///      Emits OwnershipTransfer.
    /// @param _articleStorageAddress The address of article in the storage.
    /// @param _newOwner The new owner of the article which resides in the storage address, provided by the previous parameter.
    function transferOwnership(uint80 _articleStorageAddress, address payable _newOwner) external virtual;

    /// @notice Update the arbitration cost for the winner.
    /// @dev Sets the multiplier of the arbitration cost that the winner has to pay as fee stake to a new value. 
    ///      Emits WinnerStakeMultiplierUpdate.
    /// @param _newWinnerStakeMultiplier The new value of WINNER_STAKE_MULTIPLIER.
    function changeWinnerStakeMultiplier(uint256 _newWinnerStakeMultiplier) external virtual;

    /// @notice Update the arbitration cost for the loser.
    /// @dev Sets the multiplier of the arbitration cost that the loser has to pay as fee stake to a new value. 
    ///      Emits LoserStakeMultiplierUpdate.
    /// @param _newLoserStakeMultiplier The new value of LOSER_STAKE_MULTIPLIER.
    
    function changeLoserStakeMultiplier(uint256 _newLoserStakeMultiplier) external virtual;

    /// @notice Update the appeal window for the loser.
    /// @dev Sets the multiplier of the appeal window for the loser to a new value. Emits LoserAppealPeriodMultiplierUpdate.
    /// @param _newLoserAppealPeriodMultiplier The new value of LOSER_APPEAL_PERIOD_MULTIPLIER.
    function changeLoserAppealPeriodMultiplier(uint256 _newLoserAppealPeriodMultiplier) external virtual;

    /// @notice Update the timelock for the article withdtrawal.
    /// @dev Sets the timelock before an author can initiate the withdrawal of an article to a new value. 
    ///      Emits ArticleWithdrawalTimelockUpdate.
    /// @param _newArticleWithdrawalTimelock The new value of ARTICLE_WITHDRAWAL_TIMELOCK.
    function changeArticleWithdrawalTimelock(uint256 _newArticleWithdrawalTimelock) external virtual;

    /// @notice Find a vacant storage slot for an article.
    /// @dev Helper function to find a vacant slot for article. Use this function before calling initialize to minimize your gas cost.
    /// @param _searchPointer Starting point of the search. If you do not have a guess, just pass 0.
    function findVacantStorageSlot(uint80 _searchPointer) external view virtual returns (uint256 vacantSlotIndex);

    /// @notice Get required challenge fee.
    /// @dev Returns the total amount needs to be paid to challenge an article, including taxes if any.
    /// @param _articleStorageAddress The address of article in the storage.
    function challengeFee(uint80 _articleStorageAddress) public view virtual returns (uint256 challengeFee);

    /// @notice Get required appeal fee and deposit.
    /// @dev Returns the total amount needs to be paid to appeal a dispute, including fees and stake deposit.
    /// @param _disputeID ID of the dispute as in arbitrator.
    function appealFee(uint256 _disputeID) external view virtual returns (uint256 arbitrationFee);

    /// @notice Withdraw appeal crowdfunding balance.
    /// @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets resolved.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    /// @param _round Number of the round that caller wants to execute withdraw on.
    /// @param _ruling A ruling option that caller wants to execute withdraw on.
    /// @return sum The amount that is going to be transferred to contributor as a result of this function call.
    function withdrawFeesAndRewards(
        uint256 _disputeID,
        address payable _contributor,
        uint256 _round,
        RulingOptions _ruling
    ) external virtual returns (uint256 sum);

    /// @notice Withdraw appeal crowdfunding balance for given ruling option for all rounds.
    /// @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for all rounds at once.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    /// @param _ruling Ruling option that caller wants to execute withdraw on.
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _disputeID,
        address payable _contributor,
        RulingOptions _ruling
    ) external virtual;

    /// @notice Withdraw appeal crowdfunding balance for given ruling option and for given rounds.
    /// @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for given positions at once.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    /// @param positions [rounds][rulings].
    function withdrawFeesAndRewardsForGivenPositions(
        uint256 _disputeID,
        address payable _contributor,
        uint256[][] calldata positions
    ) external virtual;

    /// @notice Withdraw appeal crowdfunding balance for all ruling options and all rounds.
    /// @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for all rounds and all rulings at once.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    function withdrawFeesAndRewardsForAllRoundsAndAllRulings(uint256 _disputeID, address payable _contributor)
        external
        virtual;

    /// @notice Learn the total amount of appeal crowdfunding balance available.
    /// @dev Returns the sum of withdrawable amount and 2D array of positions[round][ruling].
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    /// @return sum The total amount available to withdraw.
    function getTotalWithdrawableAmount(uint256 _disputeID, address payable _contributor)
        external
        view
        virtual
        returns (uint256 sum, uint256[][] memory positions);

    /// @notice Learn about given dispute round.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _round Round ID.
    /// @return hasPaid Whether given ruling option was fully funded.
    /// @return totalPerRuling The total raised per ruling option.
    /// @return totalClaimableAfterExpenses Total amount will be distributed back to winners, after deducting expenses.
    function getRoundInfo(uint256 _disputeID, uint256 _round)
        external
        view
        virtual
        returns (
            bool[NUMBER_OF_RULING_OPTIONS + 1] memory hasPaid,
            uint256[NUMBER_OF_RULING_OPTIONS + 1] memory totalPerRuling,
            uint256 totalClaimableAfterExpenses
        );

    /// @notice Learn about how much more needs to be raised for given ruling option.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _ruling The ruling option to query.
    /// @return Amount needs to be raised
    function getAmountRemainsToBeRaised(uint256 _disputeID, RulingOptions _ruling)
        external
        view
        virtual
        returns (uint256);

    /// @notice Get return of investment ratio.
    /// @dev Purely depends on whether given ruling option is winner and stake multipliers.
    /// @param _ruling The ruling option to query.
    /// @param _lastRoundWinner Winner of the last round.
    /// @return Return of investment ratio, denominated by MULTIPLIER_DENOMINATOR.
    function getReturnOfInvestmentRatio(RulingOptions _ruling, RulingOptions _lastRoundWinner)
        external
        view
        virtual
        returns (uint256);

    /// @notice Get appeal time window.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _ruling The ruling option to query.
    /// @return Start
    /// @return End
    function getAppealPeriod(uint256 _disputeID, RulingOptions _ruling)
        external
        view
        virtual
        returns (uint256, uint256);

    /// @notice Get last round's winner.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @return Winning ruling option.
    function getLastRoundWinner(uint256 _disputeID) public view virtual returns (uint256);

    /// @notice Switches publishing lock.
    /// @dev    Useful when it's no longer safe or secure to use this contract.
    ///         Prevents new articles to be published. Only intended for privileges users.
    function switchPublishingLock() public virtual;
}