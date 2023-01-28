// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//   _  _ _  _ _  _  _  _
//  | || | || | || \| || |
//  n_|||U || U || \\ || |
// \__/|___||___||_|\_||_|

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "closedsea/src/OperatorFilterer.sol";

abstract contract QuestReward {
    // QuestReward contract must implement this function
    // to is used for mint desetination
    // zodiaTokenId is used for pulling zodia metadata
    function claimQuestReward(
        address to,
        uint256 zodiaTokenId
    ) external virtual;
}

struct Quest {
    // Address of reward contract
    address reward;
    // Duration of quest, max value 194 days in seconds
    uint24 duration;
    // Cost to claim quest reward, max value 18.4 Ether
    uint64 claimCost;
    // Whether quest is active
    bool isActive;
    // Address of quest creator
    address creator;
    // Whether quest can be repeated additional times
    bool isRepeatable;
}

struct Journal {
    // Active quest zodia is currently on, 0 means no active quest
    uint64 questId;
    uint64 completedQuestCount;
    uint128 questStartedTimestamp;
}

contract ZodiaV3 is
    ERC721Upgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    OperatorFilterer
{
    using Counters for Counters.Counter;

    error ActiveQuest();
    error AlreadyClaimedReward();
    error BulkOverpaid();
    error QuestStatusUpdate();
    error InvalidDiscoverSource();
    error InvalidOwner();
    error InvalidQuest();
    error InvalidQuestGiverClaim();
    error InvalidQuestTime();
    error NoActiveQuest();
    error NoZodiasSelected();
    error QuestNotActive();
    error QuestNotEnoughEther();
    error QuestNotEnoughTime();
    error UnsupportedMarketplace();
    error WithdrawFailed();

    // 3 days
    uint24 public constant MIN_QUEST_TIME = 259_200;

    Counters.Counter private _questId;
    string private _baseTokenURI;
    address private _grimoireContract;

    bool public operatorFilteringEnabled;

    // Map of _questId to quest
    mapping(uint256 => Quest) public quests;

    // Map of zodiaId to a Journal
    mapping(uint256 => Journal) public journals;

    // Map of quest creator  to reward balance;
    mapping(address => uint256) public questRewardClaimBalance;

    // Maps a `_questId` to a `zodiaId` to a completion, note that this will only be used for non-repeatable quests
    mapping(uint256 => mapping(uint256 => bool)) public completed;

    event QuestAbandoned(
        uint256 zodiaTokenId,
        address zodiaOwner,
        uint256 timestamp
    );
    event QuestAbandonedBulk(
        uint256[] zodiaTokenIds,
        address zodiaOwner,
        uint256 timestamp
    );
    event QuestRewardClaimed(
        address zodiaOwner,
        address rewardAddress,
        uint256 currentTimestamp
    );
    event QuestRewardBulkClaimed(
        address zodiaOwner,
        uint256[] zodiaTokenIds,
        uint256 currentTimestamp
    );
    event QuestStarted(
        uint256 zodiaTokenId,
        address zodiaOwner,
        uint256 questStartedTimestamp
    );
    event QuestStartedBulk(
        uint256[] zodiaTokenIds,
        address zodiaOwner,
        uint256 questStartedTimestamp
    );

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init("Zodia", "ZODIA");

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    /// @notice Mints Zodia token with given id
    /// @param to The address to mint to
    /// @param grimoireId The id to mint
    /// @return The minted id
    function discoverZodia(
        address to,
        uint256 grimoireId
    ) external returns (uint256) {
        if (msg.sender != _grimoireContract) revert InvalidDiscoverSource();

        _mint(to, grimoireId);

        return grimoireId;
    }

    // QUESTING LOGIC

    /// @notice Begins a quest for tokenId and stakes the token
    /// @param tokenId The id of Zodia token
    /// @param questId The quest to go on
    function startQuest(uint256 tokenId, uint256 questId) external {
        _startQuest(tokenId, questId);

        emit QuestStarted(tokenId, msg.sender, block.timestamp);
    }

    function startQuests(
        uint256[] calldata tokenIds,
        uint256 questId
    ) external _validBulkTokenIdsAction(tokenIds) {
        unchecked {
            for (uint256 i; i < tokenIds.length; i++) {
                _startQuest(tokenIds[i], questId);
            }

            emit QuestStartedBulk(tokenIds, msg.sender, block.timestamp);
        }
    }

    /// @notice Abandons a quest for tokenId and un-stakes the token
    /// @param tokenId The id of Zodia token
    function abandonQuest(uint256 tokenId) external {
        _abandonQuest(tokenId);

        emit QuestAbandoned(tokenId, msg.sender, block.timestamp);
    }

    function abandonQuests(
        uint256[] calldata tokenIds
    ) external _validBulkTokenIdsAction(tokenIds) {
        unchecked {
            for (uint256 i; i < tokenIds.length; i++) {
                _abandonQuest(tokenIds[i]);
            }

            emit QuestAbandonedBulk(tokenIds, msg.sender, block.timestamp);
        }
    }

    /// @notice Claims a quest reward and un-stakes the token
    /// @param tokenId The id of Zodia token
    function claimQuestReward(uint256 tokenId) external payable nonReentrant {
        (
            Quest storage quest,
            Journal storage journal
        ) = _getJournalAndQuestForClaim(tokenId);

        uint256 adventureStartedTime = journal.questStartedTimestamp;
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp - adventureStartedTime < quest.duration)
            revert QuestNotEnoughTime();

        if (msg.value != quest.claimCost) {
            revert QuestNotEnoughEther();
        }

        _resolveQuestClaimForToken(tokenId, quest, journal);

        emit QuestRewardClaimed(msg.sender, quest.reward, currentTimestamp);
    }

    function claimQuestRewards(
        uint256[] calldata tokenIds
    ) external payable _validBulkTokenIdsAction(tokenIds) nonReentrant {
        uint256 remainingValue = msg.value;

        unchecked {
            for (uint256 i; i < tokenIds.length; i++) {
                (
                    Quest storage quest,
                    Journal storage journal
                ) = _getJournalAndQuestForClaim(tokenIds[i]);

                uint256 adventureStartedTime = journal.questStartedTimestamp;
                uint256 currentTimestamp = block.timestamp;

                if (currentTimestamp - adventureStartedTime < quest.duration)
                    revert QuestNotEnoughTime();

                if (remainingValue < quest.claimCost) {
                    revert QuestNotEnoughEther();
                }

                remainingValue -= quest.claimCost;

                _resolveQuestClaimForToken(tokenIds[i], quest, journal);
            }
        }

        if (remainingValue != 0) revert BulkOverpaid();

        emit QuestRewardBulkClaimed(msg.sender, tokenIds, block.timestamp);
    }

    function setGrimoireContract(address grimoireContract) external onlyOwner {
        _grimoireContract = grimoireContract;
    }

    /// @notice Registers a new quest
    /// @param questRewardContract The address of the reward contract
    /// @param questTime Quest length in seconds
    /// @param questClaimCost Quest claim cost in wei
    /// @param isRepeatable Whether the quest is repeatable
    function postQuest(
        address questRewardContract,
        uint24 questTime,
        uint64 questClaimCost,
        bool isRepeatable
    ) external onlyOwner {
        if (questTime < MIN_QUEST_TIME) revert InvalidQuestTime();
        _questId.increment();

        quests[_questId.current()] = Quest({
            reward: questRewardContract,
            duration: questTime,
            claimCost: questClaimCost,
            isActive: true,
            creator: msg.sender,
            isRepeatable: isRepeatable
        });
    }

    function getQuestingZodiasByQuest(
        uint256 questId
    ) external view returns (bool[] memory questingZodias) {
        bool[] memory _questingZodias = new bool[](4671);

        unchecked {
            for (uint256 i = 1; i <= 4670; i++) {
                Journal memory journal = journals[i];

                if (
                    journal.questId == questId &&
                    journal.questStartedTimestamp != 0
                ) {
                    _questingZodias[i] = true;
                }
            }
        }

        questingZodias = _questingZodias;
    }

    function getClaimedByQuest(
        uint256 questId
    ) external view returns (uint256 totalUniqueClaimed) {
        uint256 _totalUniqueClaimed = 0;

        unchecked {
            for (uint256 i = 1; i <= 4670; i++) {
                if (completed[questId][i]) {
                    // was completed

                    _totalUniqueClaimed++;
                }
            }
        }

        totalUniqueClaimed = _totalUniqueClaimed;
    }

    /// @notice Toggles quest on/off
    /// @param questId quest identifier
    function toggleQuestActive(uint256 questId) external onlyOwner {
        if (questId == 0 || questId > _questId.current()) revert InvalidQuest();

        quests[questId].isActive = !quests[questId].isActive;
    }

    /// @notice Claim available quest reward balance from pool
    function claimQuestRewardBalance() external nonReentrant {
        uint256 balanceToWithdraw = questRewardClaimBalance[msg.sender];

        // reset remainingBalance to 0 first
        questRewardClaimBalance[msg.sender] = 0;

        (bool transferSuccess, ) = msg.sender.call{value: balanceToWithdraw}(
            ""
        );

        if (!transferSuccess) revert WithdrawFailed();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
        if (journals[tokenId].questId != 0) revert ActiveQuest();
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        if (journals[tokenId].questId != 0) revert ActiveQuest();
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
        if (journals[tokenId].questId != 0) revert ActiveQuest();
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    // Start a quest, locks up NFT from being transferred,
    function _startQuest(
        uint256 tokenId,
        uint256 questId
    ) internal nonReentrant {
        if (msg.sender != ownerOf(tokenId)) revert InvalidOwner();

        Journal storage journal = journals[tokenId];

        if (!quests[questId].isActive) revert QuestNotActive();
        if (journal.questId != 0) revert ActiveQuest();

        Quest storage quest = quests[questId];

        // If zodia already has already complete quest then cannot claim again, skip if repeatable quest
        if (!quest.isRepeatable && completed[questId][tokenId])
            revert AlreadyClaimedReward();

        journals[tokenId] = Journal({
            questStartedTimestamp: uint128(block.timestamp),
            questId: uint64(questId),
            completedQuestCount: journal.completedQuestCount
        });
    }

    // Stops a quest, allow owner of contract to forcefully adandon quests
    function _abandonQuest(uint256 tokenId) internal {
        if (msg.sender != ownerOf(tokenId) && msg.sender != owner())
            revert InvalidOwner();

        Journal storage journal = journals[tokenId];

        if (journal.questId == 0) revert QuestStatusUpdate();

        journals[tokenId] = Journal({
            questStartedTimestamp: 0,
            questId: 0,
            completedQuestCount: journal.completedQuestCount
        });
    }

    function _resolveQuestClaimForToken(
        uint256 tokenId,
        Quest storage quest,
        Journal storage journal
    ) internal {
        // Quest reward claimed
        completed[journal.questId][tokenId] = true;

        // Update balance for quest giver
        questRewardClaimBalance[quest.creator] += quest.claimCost;

        // Receive reward
        QuestReward questReward = QuestReward(quest.reward);
        questReward.claimQuestReward(msg.sender, tokenId);

        // Update completed count
        journals[tokenId] = Journal({
            questId: 0,
            questStartedTimestamp: 0,
            completedQuestCount: ++journal.completedQuestCount
        });
    }

    function _getJournalAndQuestForClaim(
        uint256 tokenId
    ) internal view returns (Quest storage, Journal storage) {
        if (msg.sender != ownerOf(tokenId)) revert InvalidOwner();

        Journal storage journal = journals[tokenId];

        // Don't do quest.isActive check here because as long as they started they should be able to claim it
        if (journal.questId == 0) revert NoActiveQuest();

        Quest storage quest = quests[journal.questId];

        // Skip this check if quest is repeatable
        if (!quest.isRepeatable && completed[journal.questId][tokenId])
            revert AlreadyClaimedReward();

        return (quest, journal);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    modifier _validBulkTokenIdsAction(uint256[] calldata tokenIds) {
        if (tokenIds.length == 0) revert NoZodiasSelected();

        _;
    }
}