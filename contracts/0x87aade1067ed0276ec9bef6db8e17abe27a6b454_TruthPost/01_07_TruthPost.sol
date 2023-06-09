/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@kleros/dispute-resolver-interface-contract/contracts/IDisputeResolver.sol";
import "./ITruthPost.sol";

/// @title  The Trust Post
/// @author https://github.com/proveuswrong<0xferit, gratestas>
/// @notice Smart contract for a type of curation, where submitted items are on hold until they are withdrawn and the amount of security deposits are determined by submitters.
/// @dev    You should target ITruthPost interface contract for building on top. Otherwise you risk incompatibility across versions.
///         Articles are not addressed with their identifiers. That enables us to reuse same storage address for another article later.///         Arbitrator is fixed, but subcourts, jury size and metaevidence are not.
///         We prevent articles to get withdrawn immediately. This is to prevent submitter to escape punishment in case someone discovers an argument to debunk the article.
///         Bounty amounts are compressed with a lossy compression method to save on storage cost.
/// @custom:approvals 0xferit, gratestas
contract TruthPost is ITruthPost, IArbitrable, IEvidence {
    IArbitrator public immutable ARBITRATOR;
    uint256 public constant NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE = 32; // To compress bounty amount to gain space in struct. Lossy compression.

    uint8 public categoryCounter = 0;

    address payable public admin = payable(msg.sender);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    struct DisputeData {
        address payable challenger;
        RulingOptions outcome;
        uint8 articleCategory;
        bool resolved; // To remove dependency to disputeStatus function of arbitrator. This function is likely to be removed in Kleros v2.
        uint80 articleStorageAddress; // 2^16 is sufficient. Just using extra available space.
        Round[] rounds; // Tracks each appeal round of a dispute.
    }

    struct Round {
        mapping(address => uint256[NUMBER_OF_RULING_OPTIONS + 1]) contributions;
        bool[NUMBER_OF_RULING_OPTIONS + 1] hasPaid; // True if the fees for this particular answer has been fully paid in the form hasPaid[rulingOutcome].
        uint256[NUMBER_OF_RULING_OPTIONS + 1] totalPerRuling;
        uint256 totalClaimableAfterExpenses;
    }

    struct Article {
        address payable owner;
        uint32 withdrawalPermittedAt; // Overflows in year 2106.
        uint56 bountyAmount; // 32-bits compression. Decompressed size is 88 bits.
        uint8 category;
    }

    bytes[64] public categoryToArbitratorExtraData;

    mapping(uint80 => Article) public articleStorage; // Key: Storage address of article. Articles are not addressed with their identifiers, to enable reusing a storage slot.
    mapping(uint256 => DisputeData) public disputes; // Key: Dispute ID as in arbitrator.

    constructor(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _metaevidenceIpfsUri,
        uint256 _articleWithdrawalTimelock,
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        address payable _treasury
    ) ITruthPost(_articleWithdrawalTimelock, _winnerStakeMultiplier, _loserStakeMultiplier, _treasury) {
        ARBITRATOR = _arbitrator;
        newCategory(_metaevidenceIpfsUri, _arbitratorExtraData);
    }

    /// @inheritdoc ITruthPost
    function initializeArticle(
        string calldata _articleID,
        uint8 _category,
        uint80 _searchPointer
    ) external payable override {
        require(_category < categoryCounter, "This category does not exist");

        Article storage article;
        do {
            article = articleStorage[_searchPointer++];
        } while (article.bountyAmount != 0);

        article.owner = payable(msg.sender);
        article.bountyAmount = uint56(msg.value >> NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE);
        article.category = _category;

        require(article.bountyAmount > 0, "You can't initialize an article without putting a bounty.");

        uint256 articleStorageAddress = _searchPointer - 1;
        emit NewArticle(_articleID, _category, articleStorageAddress);
        emit BalanceUpdate(
            articleStorageAddress,
            uint256(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE
        );
    }

    /// @inheritdoc ITruthPost
    function submitEvidence(uint256 _disputeID, string calldata _evidenceURI) external override {
        emit Evidence(ARBITRATOR, _disputeID, msg.sender, _evidenceURI);
    }

    /// @inheritdoc ITruthPost
    function increaseBounty(uint80 _articleStorageAddress) external payable override {
        Article storage article = articleStorage[_articleStorageAddress];
        require(msg.sender == article.owner, "Only author can increase bounty of an article.");
        // To prevent mistakes.

        article.bountyAmount += uint56(msg.value >> NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE);

        emit BalanceUpdate(
            _articleStorageAddress,
            uint256(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE
        );
    }

    /// @inheritdoc ITruthPost
    function initiateWithdrawal(uint80 _articleStorageAddress) external override {
        Article storage article = articleStorage[_articleStorageAddress];
        require(msg.sender == article.owner, "Only author can withdraw an article.");
        require(article.withdrawalPermittedAt == 0, "Withdrawal already initiated or there is a challenge.");

        article.withdrawalPermittedAt = uint32(block.timestamp + ARTICLE_WITHDRAWAL_TIMELOCK);
        emit TimelockStarted(_articleStorageAddress);
    }

    /// @inheritdoc ITruthPost
    function withdraw(uint80 _articleStorageAddress) external override {
        Article storage article = articleStorage[_articleStorageAddress];

        require(msg.sender == article.owner, "Only author can withdraw an article.");
        require(article.withdrawalPermittedAt != 0, "You need to initiate withdrawal first.");
        require(
            article.withdrawalPermittedAt <= block.timestamp,
            "You need to wait for timelock or wait until the challenge ends."
        );

        uint256 withdrawal = uint96(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE;
        article.bountyAmount = 0;
        // This is critical to reset.
        article.withdrawalPermittedAt = 0;
        // This too, otherwise new article inside the same slot can withdraw instantly.
        payable(msg.sender).transfer(withdrawal);
        emit ArticleWithdrawn(_articleStorageAddress);
    }

    /// @inheritdoc ITruthPost
    function challenge(uint80 _articleStorageAddress) external payable override {
        Article storage article = articleStorage[_articleStorageAddress];
        require(article.bountyAmount > 0, "Nothing to challenge.");
        require(article.withdrawalPermittedAt != type(uint32).max, "There is an ongoing challenge.");
        article.withdrawalPermittedAt = type(uint32).max;
        // Mark as challenged.

        require(msg.value >= challengeFee(_articleStorageAddress), "Insufficient funds to challenge.");

        uint256 taxAmount = ((uint96(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE) *
            challengeTaxRate) / MULTIPLIER_DENOMINATOR;
        treasuryBalance += taxAmount;

        uint256 disputeID = ARBITRATOR.createDispute{value: msg.value - taxAmount}(
            NUMBER_OF_RULING_OPTIONS,
            categoryToArbitratorExtraData[article.category]
        );

        disputes[disputeID].challenger = payable(msg.sender);
        disputes[disputeID].rounds.push();
        disputes[disputeID].articleStorageAddress = uint80(_articleStorageAddress);
        disputes[disputeID].articleCategory = article.category;

        // Evidence group ID is dispute ID.
        emit Dispute(ARBITRATOR, disputeID, article.category, disputeID);
        // This event links the dispute to an article storage address.
        emit Challenge(_articleStorageAddress, msg.sender, disputeID);
    }

    /// @inheritdoc ITruthPost
    function fundAppeal(uint256 _disputeID, RulingOptions _supportedRuling)
        external
        payable
        override
        returns (bool fullyFunded)
    {
        DisputeData storage dispute = disputes[_disputeID];

        RulingOptions currentRuling = RulingOptions(ARBITRATOR.currentRuling(_disputeID));
        uint256 basicCost;
        uint256 totalCost;
        {
            (uint256 appealWindowStart, uint256 appealWindowEnd) = ARBITRATOR.appealPeriod(_disputeID);

            uint256 multiplier;

            if (_supportedRuling == currentRuling) {
                require(block.timestamp < appealWindowEnd, "Funding must be made within the appeal period.");

                multiplier = WINNER_STAKE_MULTIPLIER;
            } else {
                require(
                    block.timestamp <
                        (appealWindowStart +
                            (((appealWindowEnd - appealWindowStart) * LOSER_APPEAL_PERIOD_MULTIPLIER) /
                                MULTIPLIER_DENOMINATOR)),
                    "Funding must be made within the first half appeal period."
                );

                multiplier = LOSER_STAKE_MULTIPLIER;
            }

            basicCost = ARBITRATOR.appealCost(_disputeID, categoryToArbitratorExtraData[dispute.articleCategory]);
            totalCost = basicCost + ((basicCost * (multiplier)) / MULTIPLIER_DENOMINATOR);
        }

        RulingOptions supportedRulingOutcome = RulingOptions(_supportedRuling);

        uint256 lastRoundIndex = dispute.rounds.length - 1;
        Round storage lastRound = dispute.rounds[lastRoundIndex];
        require(!lastRound.hasPaid[uint256(supportedRulingOutcome)], "Appeal fee has already been paid.");

        uint256 contribution;
        {
            uint256 paidSoFar = lastRound.totalPerRuling[uint256(supportedRulingOutcome)];

            if (paidSoFar >= totalCost) {
                contribution = 0;
                // This can happen if arbitration fee gets lowered in between contributions.
            } else {
                contribution = totalCost - paidSoFar > msg.value ? msg.value : totalCost - paidSoFar;
            }
        }

        emit Contribution(_disputeID, lastRoundIndex, _supportedRuling, msg.sender, contribution);

        lastRound.contributions[msg.sender][uint256(supportedRulingOutcome)] += contribution;
        lastRound.totalPerRuling[uint256(supportedRulingOutcome)] += contribution;

        if (lastRound.totalPerRuling[uint256(supportedRulingOutcome)] >= totalCost) {
            lastRound.totalClaimableAfterExpenses += lastRound.totalPerRuling[uint256(supportedRulingOutcome)];
            lastRound.hasPaid[uint256(supportedRulingOutcome)] = true;
            emit RulingFunded(_disputeID, lastRoundIndex, _supportedRuling);
        }

        if (
            lastRound.hasPaid[uint256(RulingOptions.ChallengeFailed)] &&
            lastRound.hasPaid[uint256(RulingOptions.Debunked)]
        ) {
            dispute.rounds.push();
            lastRound.totalClaimableAfterExpenses -= basicCost;
            ARBITRATOR.appeal{value: basicCost}(_disputeID, categoryToArbitratorExtraData[dispute.articleCategory]);
        }

        // Ignoring failure condition deliberately.
        if (msg.value - contribution > 0) payable(msg.sender).send(msg.value - contribution);

        return lastRound.hasPaid[uint256(supportedRulingOutcome)];
    }

    /// @notice Execute a ruling
    /// @dev This is only for arbitrator to use.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _ruling Winning ruling option.
    function rule(uint256 _disputeID, uint256 _ruling) external override {
        require(IArbitrator(msg.sender) == ARBITRATOR);

        DisputeData storage dispute = disputes[_disputeID];
        Round storage lastRound = dispute.rounds[dispute.rounds.length - 1];

        // Appeal overrides arbitrator ruling. If a ruling option was not fully funded and the counter ruling option was funded, funded ruling option wins by default.
        RulingOptions wonByDefault;
        if (lastRound.hasPaid[uint256(RulingOptions.ChallengeFailed)]) {
            wonByDefault = RulingOptions.ChallengeFailed;
        } else if (lastRound.hasPaid[uint256(RulingOptions.ChallengeFailed)]) {
            wonByDefault = RulingOptions.Debunked;
        }

        RulingOptions actualRuling = wonByDefault != RulingOptions.Tied ? wonByDefault : RulingOptions(_ruling);
        dispute.outcome = actualRuling;

        uint80 articleStorageAddress = dispute.articleStorageAddress;

        Article storage article = articleStorage[articleStorageAddress];

        if (actualRuling == RulingOptions.Debunked) {
            uint256 bounty = uint96(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE;
            article.bountyAmount = 0;

            emit Debunked(articleStorageAddress);
            disputes[_disputeID].challenger.send(bounty);
            // Ignoring failure condition deliberately.
        }
        // In case of tie, article stands.
        article.withdrawalPermittedAt = 0;
        // Unmark as challenged.
        dispute.resolved = true;

        emit Ruling(IArbitrator(msg.sender), _disputeID, _ruling);
    }

    /// @inheritdoc ITruthPost
    function withdrawFeesAndRewardsForAllRoundsAndAllRulings(uint256 _disputeID, address payable _contributor)
        external
        override
    {
        DisputeData storage dispute = disputes[_disputeID];
        uint256 noOfRounds = dispute.rounds.length;
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            for (uint256 rulingOption = 0; rulingOption <= NUMBER_OF_RULING_OPTIONS; rulingOption++)
                withdrawFeesAndRewards(_disputeID, _contributor, roundNumber, RulingOptions(rulingOption));
        }
    }

    /// @inheritdoc ITruthPost
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _disputeID,
        address payable _contributor,
        RulingOptions _ruling
    ) external override {
        DisputeData storage dispute = disputes[_disputeID];
        uint256 noOfRounds = dispute.rounds.length;
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            withdrawFeesAndRewards(_disputeID, _contributor, roundNumber, _ruling);
        }
    }

    /// @inheritdoc ITruthPost
    function withdrawFeesAndRewardsForGivenPositions(
        uint256 _disputeID,
        address payable _contributor,
        uint256[][] calldata positions
    ) external override {
        for (uint256 roundNumber = 0; roundNumber < positions.length; roundNumber++) {
            for (uint256 rulingOption = 0; rulingOption < positions[roundNumber].length; rulingOption++) {
                if (positions[roundNumber][rulingOption] > 0) {
                    withdrawFeesAndRewards(_disputeID, _contributor, roundNumber, RulingOptions(rulingOption));
                }
            }
        }
    }

    /// @inheritdoc ITruthPost
    function withdrawFeesAndRewards(
        uint256 _disputeID,
        address payable _contributor,
        uint256 _roundNumber,
        RulingOptions _ruling
    ) public override returns (uint256 amount) {
        DisputeData storage dispute = disputes[_disputeID];
        require(dispute.resolved, "There is no ruling yet.");

        Round storage round = dispute.rounds[_roundNumber];

        amount = getWithdrawableAmount(round, _contributor, _ruling, dispute.outcome);

        if (amount != 0) {
            round.contributions[_contributor][uint256(RulingOptions(_ruling))] = 0;
            _contributor.send(amount);
            // Ignoring failure condition deliberately.
            emit Withdrawal(_disputeID, _roundNumber, _ruling, _contributor, amount);
        }
    }

    /// @notice Updates the challenge tax rate of the contract to a new value.
    /// @dev    The new challenge tax rate must be at most 25% based on MULTIPLIER_DENOMINATOR.
    ///         Only the current administrator can call this function. Emits ChallengeTaxRateUpdate.
    /// @param _newChallengeTaxRate The new challenge tax rate to be set.
    function updateChallengeTaxRate(uint256 _newChallengeTaxRate) external onlyAdmin {
        require(_newChallengeTaxRate <= 256, "The tax rate can only be increased by a maximum of 25%");
        challengeTaxRate = _newChallengeTaxRate;
        emit ChallengeTaxRateUpdate(_newChallengeTaxRate);
    }

    /// @notice Transfers the balance of the contract to the treasury.
    /// @dev    Allows the contract to send its entire balance to the treasury address.
    ///         It is important to ensure that the treasury address is set correctly.
    ///         If the transfer fails, an exception will be raised, and the funds will remain in the contract.
    ///         Emits TreasuryBalanceUpdate.
    function transferBalanceToTreasury() public {
        uint256 amount = treasuryBalance;
        treasuryBalance = 0;
        TREASURY.send(amount);
        emit TreasuryBalanceUpdate(amount);
    }

    /// @inheritdoc ITruthPost
    function switchPublishingLock() public override onlyAdmin {
        isPublishingEnabled = !isPublishingEnabled;
    }

    /// @notice Changes the administrator of the contract to a new address.
    /// @dev    Only the current administrator can call this function. Emits AdminUpdate.
    /// @param  _newAdmin The address of the new administrator.
    function changeAdmin(address payable _newAdmin) external onlyAdmin {
        admin = _newAdmin;
        emit AdminUpdate(_newAdmin);
    }

    /// @notice Changes the treasury address of the contract to a new address.
    /// @dev    Only the current administrator can call this function. Emits TreasuryUpdate.
    /// @param  _newTreasury The address of the new treasury.
    function changeTreasury(address payable _newTreasury) external onlyAdmin {
        TREASURY = _newTreasury;
        emit TreasuryUpdate(_newTreasury);
    }

    /// @inheritdoc ITruthPost
    function changeWinnerStakeMultiplier(uint256 _newWinnerStakeMultiplier) external override onlyAdmin {
        WINNER_STAKE_MULTIPLIER = _newWinnerStakeMultiplier;
        emit WinnerStakeMultiplierUpdate(_newWinnerStakeMultiplier);
    }

    /// @inheritdoc ITruthPost
    function changeLoserStakeMultiplier(uint256 _newLoserStakeMultiplier) external override onlyAdmin {
        LOSER_STAKE_MULTIPLIER = _newLoserStakeMultiplier;
        emit LoserStakeMultiplierUpdate(_newLoserStakeMultiplier);
    }

    /// @inheritdoc ITruthPost
    function changeLoserAppealPeriodMultiplier(uint256 _newLoserAppealPeriodMultiplier) external override onlyAdmin {
        LOSER_APPEAL_PERIOD_MULTIPLIER = _newLoserAppealPeriodMultiplier;
        emit LoserAppealPeriodMultiplierUpdate(_newLoserAppealPeriodMultiplier);
    }
    
    /// @inheritdoc ITruthPost
    function changeArticleWithdrawalTimelock(uint256 _newArticleWithdrawalTimelock) external override onlyAdmin {
        ARTICLE_WITHDRAWAL_TIMELOCK = _newArticleWithdrawalTimelock;
        emit ArticleWithdrawalTimelockUpdate(_newArticleWithdrawalTimelock);
    }


    /// @notice Initialize a category.
    /// @param _metaevidenceIpfsUri IPFS content identifier for metaevidence.
    /// @param _arbitratorExtraData Extra data of Kleros arbitrator, signaling subcourt and jury size selection.
    function newCategory(string memory _metaevidenceIpfsUri, bytes memory _arbitratorExtraData) public {
        require(categoryCounter + 1 != 0, "No space left for a new category");
        emit MetaEvidence(categoryCounter, _metaevidenceIpfsUri);
        categoryToArbitratorExtraData[categoryCounter] = _arbitratorExtraData;

        categoryCounter++;
    }

    /// @inheritdoc ITruthPost
    function transferOwnership(uint80 _articleStorageAddress, address payable _newOwner) external override {
        Article storage article = articleStorage[_articleStorageAddress];
        require(msg.sender == article.owner, "Only author can transfer ownership.");
        article.owner = _newOwner;
        emit OwnershipTransfer(_newOwner);
    }

    /// @inheritdoc ITruthPost
    function challengeFee(uint80 _articleStorageAddress) public view override returns (uint256) {
        Article storage article = articleStorage[_articleStorageAddress];

        uint256 arbitrationFee = ARBITRATOR.arbitrationCost(categoryToArbitratorExtraData[article.category]);
        uint256 challengeTax = ((uint96(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE) *
            challengeTaxRate) / MULTIPLIER_DENOMINATOR;

        return arbitrationFee + challengeTax;
    }

    /// @inheritdoc ITruthPost
    function appealFee(uint256 _disputeID) external view override returns (uint256 arbitrationFee) {
        DisputeData storage dispute = disputes[_disputeID];
        arbitrationFee = ARBITRATOR.appealCost(_disputeID, categoryToArbitratorExtraData[dispute.articleCategory]);
    }

    /// @inheritdoc ITruthPost
    function findVacantStorageSlot(uint80 _searchPointer) external view override returns (uint256 vacantSlotIndex) {
        Article storage article;
        do {
            article = articleStorage[_searchPointer++];
        } while (article.bountyAmount != 0);

        return _searchPointer - 1;
    }

    /// @inheritdoc ITruthPost
    function getTotalWithdrawableAmount(uint256 _disputeID, address payable _contributor)
        external
        view
        override
        returns (uint256 sum, uint256[][] memory amounts)
    {
        DisputeData storage dispute = disputes[_disputeID];
        if (!dispute.resolved) return (uint256(0), amounts);
        uint256 noOfRounds = dispute.rounds.length;
        RulingOptions finalRuling = dispute.outcome;

        amounts = new uint256[][](noOfRounds);
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            amounts[roundNumber] = new uint256[](NUMBER_OF_RULING_OPTIONS + 1);

            Round storage round = dispute.rounds[roundNumber];
            for (uint256 rulingOption = 0; rulingOption <= NUMBER_OF_RULING_OPTIONS; rulingOption++) {
                uint256 currentAmount = getWithdrawableAmount(
                    round,
                    _contributor,
                    RulingOptions(rulingOption),
                    finalRuling
                );
                if (currentAmount > 0) {
                    sum += getWithdrawableAmount(round, _contributor, RulingOptions(rulingOption), finalRuling);
                    amounts[roundNumber][rulingOption] = currentAmount;
                }
            }
        }
    }

    /// @notice Returns withdrawable amount for given parameters.
    function getWithdrawableAmount(
        Round storage _round,
        address _contributor,
        RulingOptions _ruling,
        RulingOptions _finalRuling
    ) internal view returns (uint256 amount) {
        RulingOptions givenRuling = RulingOptions(_ruling);

        if (!_round.hasPaid[uint256(givenRuling)]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            amount = _round.contributions[_contributor][uint256(givenRuling)];
        } else {
            // Funding was successful for this ruling option.
            if (_ruling == _finalRuling) {
                // This ruling option is the ultimate winner.
                amount = _round.totalPerRuling[uint256(givenRuling)] > 0
                    ? (_round.contributions[_contributor][uint256(givenRuling)] * _round.totalClaimableAfterExpenses) /
                        _round.totalPerRuling[uint256(givenRuling)]
                    : 0;
            } else if (!_round.hasPaid[uint256(RulingOptions(_finalRuling))]) {
                // The ultimate winner was not funded in this round. Contributions discounting the appeal fee are reimbursed proportionally.
                amount =
                    (_round.contributions[_contributor][uint256(givenRuling)] * _round.totalClaimableAfterExpenses) /
                    (_round.totalPerRuling[uint256(RulingOptions.ChallengeFailed)] +
                        _round.totalPerRuling[uint256(RulingOptions.Debunked)]);
            }
        }
    }

    /// @inheritdoc ITruthPost
    function getRoundInfo(uint256 _disputeID, uint256 _round)
        external
        view
        override
        returns (
            bool[NUMBER_OF_RULING_OPTIONS + 1] memory hasPaid,
            uint256[NUMBER_OF_RULING_OPTIONS + 1] memory totalPerRuling,
            uint256 totalClaimableAfterExpenses
        )
    {
        Round storage round = disputes[_disputeID].rounds[_round];
        return (round.hasPaid, round.totalPerRuling, round.totalClaimableAfterExpenses);
    }

    /// @inheritdoc ITruthPost
    function getLastRoundWinner(uint256 _disputeID) public view override returns (uint256) {
        return ARBITRATOR.currentRuling(_disputeID);
    }

    /// @inheritdoc ITruthPost
    function getAppealPeriod(uint256 _disputeID, RulingOptions _ruling)
        external
        view
        override
        returns (uint256, uint256)
    {
        (uint256 appealWindowStart, uint256 appealWindowEnd) = ARBITRATOR.appealPeriod(_disputeID);
        uint256 loserAppealWindowEnd = appealWindowStart +
            (((appealWindowEnd - appealWindowStart) * LOSER_APPEAL_PERIOD_MULTIPLIER) / MULTIPLIER_DENOMINATOR);

        bool isWinner = RulingOptions(getLastRoundWinner(_disputeID)) == _ruling;
        return isWinner ? (appealWindowStart, appealWindowEnd) : (appealWindowStart, loserAppealWindowEnd);
    }

    /// @inheritdoc ITruthPost
    function getReturnOfInvestmentRatio(RulingOptions _ruling, RulingOptions _lastRoundWinner)
        external
        view
        override
        returns (uint256)
    {
        bool isWinner = _lastRoundWinner == _ruling;
        uint256 DECIMAL_PRECISION = 1000;
        uint256 multiplier = isWinner ? WINNER_STAKE_MULTIPLIER : LOSER_STAKE_MULTIPLIER;
        return (((WINNER_STAKE_MULTIPLIER + LOSER_STAKE_MULTIPLIER + MULTIPLIER_DENOMINATOR) * DECIMAL_PRECISION) /
            (multiplier + MULTIPLIER_DENOMINATOR));
    }

    /// @inheritdoc ITruthPost
    function getAmountRemainsToBeRaised(uint256 _disputeID, RulingOptions _ruling)
        external
        view
        override
        returns (uint256)
    {
        DisputeData storage dispute = disputes[_disputeID];
        uint256 lastRoundIndex = dispute.rounds.length - 1;
        Round storage lastRound = dispute.rounds[lastRoundIndex];

        bool isWinner = RulingOptions(getLastRoundWinner(_disputeID)) == _ruling;
        uint256 multiplier = isWinner ? WINNER_STAKE_MULTIPLIER : LOSER_STAKE_MULTIPLIER;

        uint256 raisedSoFar = lastRound.totalPerRuling[uint256(_ruling)];
        uint256 basicCost = ARBITRATOR.appealCost(_disputeID, categoryToArbitratorExtraData[dispute.articleCategory]);
        uint256 totalCost = basicCost + ((basicCost * (multiplier)) / MULTIPLIER_DENOMINATOR);

        return totalCost - raisedSoFar;
    }

}