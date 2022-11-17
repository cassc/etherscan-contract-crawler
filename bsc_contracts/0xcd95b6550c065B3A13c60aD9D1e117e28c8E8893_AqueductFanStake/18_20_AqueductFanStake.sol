// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITreasury.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2Upgradable.sol";

contract AqueductFanStake is
    Initializable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    VRFConsumerBaseV2Upgradable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    address public treasury;
    address public erc20;

    // COUNTERS //
    CountersUpgradeable.Counter private _tokenId;
    CountersUpgradeable.Counter private _sectionId;
    CountersUpgradeable.Counter private _stageId;
    CountersUpgradeable.Counter private _poolId;
    mapping(uint256 => uint256) private _poolIdToStakeId;

    // EVENT //
    Event public CurrentEvent;
    mapping(uint256 => Section) public sections;
    mapping(uint256 => Stage) public stages;
    mapping(uint256 => Pool) public pools;

    // STRUCTS //
    struct Event {
        string name;
        uint256 commission;
    }

    struct Section {
        string sectionName;
        uint256 endDate;
    }

    struct Stage {
        string stageName;
        uint256 startAt;
        uint256 endAt;
        uint256 resultSource;
    }

    struct Pool {
        uint256 sectionId;
        uint256 stageId;
        uint256 stakePrice;
        uint256 silverTicketChance;
        uint256 goldTicketChance;
    }

    struct Stake {
        uint256 goldAmount;
        uint256 silverAmount;
        uint256 amount;
        string stakeOn;
    }

    // STORAGE //
    mapping(uint256 => string[]) private stageToResults;
    mapping(uint256 => mapping(string => uint256)) public poolToResultToAmount;
    mapping(uint256 => uint256) public poolToAssets;
    mapping(uint256 => uint256) public poolToStakesAmount;
    mapping(string => uint256) internal resultToStakesAmount;
    bool public isPaused;

    mapping(uint256 => mapping(uint256 => Stake)) internal poolIdToTokenIdToBet;
    mapping(uint256 => mapping(address => uint256[]))
        internal poolIdToAccountToTokenIds;
    mapping(uint256 => mapping(string => mapping(uint256 => uint256)))
        public poolIdToBetOnToTicketTypeToProfit;

    mapping(uint256 => mapping(string => uint256))
        public poolIdToResultToGoldAmount;
    mapping(uint256 => mapping(string => uint256))
        public poolIdToResultToSilverAmount;

    mapping(uint256 => uint256) public poolToGoldStakesAmount;
    mapping(uint256 => uint256) public poolToSilverStakesAmount;
    mapping(uint256 => uint256) public poolToCommonStakesAmount;
    mapping(uint256 => mapping(string => uint256)) internal poolToResultToPoint;
    mapping(uint256 => uint256) internal betIdToPoolId;
    mapping(uint256 => string) public sectionToWinner;

    mapping(uint256 => mapping(uint256 => uint256))
        internal poolIdToStakesIdToTokenId;
    mapping(uint256 => mapping(uint256 => uint256[]))
        internal poolIdToBetIdToStakes;

    mapping(uint256 => string) tokenToMetadata;

    // MODIFIERS //
    modifier poolShouldExist(uint256 poolId_) {
        require(
            poolId_ < _poolId.current() && poolId_ != 0,
            "Pool doesn't exist"
        );
        _;
    }

    modifier shouldBeUsersToken(uint256 poolId_, uint256 tokenId_) {
        require(
            ifItemInArray(
                poolIdToAccountToTokenIds[poolId_][msg.sender],
                tokenId_
            ),
            "Not your token or token doens't exist"
        );
        _;
    }

    modifier stageShouldBeFinished(uint256 poolId_) {
        require(
            stages[pools[poolId_].stageId].endAt <= block.timestamp,
            "Stage should be finished"
        );
        _;
    }

    modifier stageShouldNotBeFinished(uint256 poolId_) {
        require(
            stages[pools[poolId_].stageId].endAt > block.timestamp,
            "Stage should not be finished"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is on pause");
        _;
    }

    modifier onlyAdmin() {
        require(ITreasury(treasury).isAdmin(msg.sender), "You are not admin");
        _;
    }

    // EVENTS //
    event PoolCreated(
        uint256 indexed poolId,
        uint256 indexed sectionId,
        uint256 indexed stageId,
        uint256 stakePrice,
        uint256 startAt,
        uint256 endAt,
        string[] results
    );

    event StakeCreated(
        address creator,
        string result,
        uint256 amount,
        uint256 stakeId,
        uint256 poolId,
        address referralAddress,
        string metadata
    );

    event StakeWithdrawn(address user, uint256 stakeId, uint256 poolId);

    event SectionCreated(
        string sectionName,
        uint256 sectionId,
        uint256 ednDate
    );

    event TokenTransfered(address from, address to, uint256 tokenId);

    event StageCreated(
        uint256 stageId,
        string stageName,
        uint256 startAt,
        uint256 endAt,
        string[] results
    );

    event RewardClaimed(uint256 tokenId);

    event WinnerSet(uint256 sectionId, string winner);

    event EventCreated(string eventName, uint256 commission);

    // CHAINLINK
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    address vrfCoordinator;

    mapping(uint256 => uint256) requestIdToPoolId;
    mapping(uint256 => uint256) internal requestIdToGoldAmount;
    mapping(uint256 => uint256) internal requestIdToSilverAmount;

    function initialize(address treasury_, uint64 subscriptionId_)
        public
        initializer
    {
        __ERC721_init("Aqueduct Fan Stake", "AFS");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        VRFConsumerBaseV2Upgradable.init(
            0xc587d9053cd1118f25F645F9E08BB98c9712A4EE
        );

        treasury = treasury_;
        erc20 = ITreasury(treasury).getErc20Address();
        s_subscriptionId = subscriptionId_;
        _tokenId.increment();
        _poolId.increment();
        keyHash = 0xba6e730de88d94a5510ae6613898bfb0c3de5d16e609c5b7da808747125506f7;
        callbackGasLimit = 2500000;
        requestConfirmations = 3;
        vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
        COORDINATOR = VRFCoordinatorV2Interface(
            0xc587d9053cd1118f25F645F9E08BB98c9712A4EE
        );
    }

    function changeKeyHash(bytes32 keyHash_) public onlyAdmin {
        keyHash = keyHash_;
    }

    function setChainlinkSubId(uint64 subId_) public onlyAdmin {
        s_subscriptionId = subId_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "Token not exists");
        return string(tokenToMetadata[tokenId]);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override(VRFConsumerBaseV2Upgradable)
    {
        uint256[] memory goldArray = new uint256[](
            requestIdToGoldAmount[requestId]
        );
        uint256[] memory silverArray = new uint256[](
            requestIdToSilverAmount[requestId]
        );

        for (uint256 i = 0; i < requestIdToSilverAmount[requestId]; i++) {
            silverArray[i] =
                randomWords[i] %
                poolToStakesAmount[requestIdToPoolId[requestId]];
        }

        for (
            uint256 i = requestIdToSilverAmount[requestId];
            i <
            requestIdToGoldAmount[requestId] +
                requestIdToSilverAmount[requestId];
            i++
        ) {
            goldArray[i - requestIdToSilverAmount[requestId]] =
                randomWords[i] %
                poolToStakesAmount[requestIdToPoolId[requestId]];
        }

        revealPool(requestIdToPoolId[requestId], goldArray, silverArray);
    }

    function reveal(uint256 poolId_)
        public
        onlyAdmin
        stageShouldBeFinished(poolId_)
        poolShouldExist(poolId_)
    {
        uint256 goldAmount = (poolToStakesAmount[poolId_] *
            pools[poolId_].goldTicketChance) / 10000; // 1
        uint256 silverAmount = (poolToStakesAmount[poolId_] *
            pools[poolId_].silverTicketChance) / 10000; // 3
        uint32 numWords = convert(goldAmount + silverAmount); // 4

        if (numWords > 0) {
            uint256 requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );

            requestIdToPoolId[requestId] = poolId_;
            requestIdToGoldAmount[requestId] = goldAmount;
            requestIdToSilverAmount[requestId] = silverAmount;
        } else {
            revealPool(poolId_, new uint256[](0), new uint256[](0));
        }
    }

    function createEvent(string memory eventName, uint256 commission)
        public
        onlyAdmin
    {
        require(commission <= 10000, "Commission must be between 0 and 100");

        CurrentEvent = Event(eventName, commission);
        emit EventCreated(eventName, commission);
    }

    function createSection(string memory sectionName_, uint256 endDate_)
        public
        onlyAdmin
    {
        require(endDate_ > block.timestamp, "End date can't be in the past");
        sections[_sectionId.current()] = Section(sectionName_, endDate_);

        emit SectionCreated(sectionName_, _sectionId.current(), endDate_);
        _sectionId.increment();
    }

    function createStage(
        string memory stageName_,
        uint256 startAt_,
        uint256 endAt_,
        string[] memory results_
    ) public onlyAdmin {
        require(results_.length > 1, "Should be minimum 2 results");
        require(startAt_ >= block.timestamp, "Start date can't be in the past");
        require(endAt_ > startAt_, "End date should be after start date");

        stages[_stageId.current()] = Stage(stageName_, startAt_, endAt_, 0);
        stageToResults[_stageId.current()] = results_;

        emit StageCreated(
            _stageId.current(),
            stageName_,
            startAt_,
            endAt_,
            results_
        );
        _stageId.increment();
    }

    function createPool(
        uint256 sectionId_,
        uint256 stageId_,
        uint256 stakePrice_,
        uint256 silverTicketChance_,
        uint256 goldTicketChance_
    ) public onlyAdmin {
        require(sectionId_ < _sectionId.current(), "Section doesn't exist");
        require(stageId_ < _stageId.current(), "Stage doesn't exist");
        require(
            silverTicketChance_ + goldTicketChance_ < 9999,
            "Sum of chances should be less then 10000(100%)"
        );

        pools[_poolId.current()] = Pool(
            sectionId_,
            stageId_,
            stakePrice_,
            silverTicketChance_,
            goldTicketChance_
        );
        emit PoolCreated(
            _poolId.current(),
            sectionId_,
            stageId_,
            stakePrice_,
            stages[stageId_].startAt,
            stages[stageId_].endAt,
            stageToResults[stageId_]
        );
        _poolId.increment();
    }

    function createStake(
        uint256 poolId_,
        string memory result_,
        uint256 amount_,
        address referralAddress_,
        string memory metadata_
    )
        public
        whenNotPaused
        stageShouldNotBeFinished(poolId_)
        poolShouldExist(poolId_)
    {
        require(amount_ > 0, "Min amount is 1");
        require(
            stages[pools[poolId_].stageId].startAt <= block.timestamp,
            "This stage is not started yet"
        );

        uint256 tokensSent = pools[poolId_].stakePrice * amount_;
        uint256 toTreasury = (tokensSent * CurrentEvent.commission) / 10000;
        uint256 toContract = tokensSent -
            (tokensSent * CurrentEvent.commission) /
            10000;

        IERC20(erc20).transferFrom(msg.sender, address(this), toContract);
        IERC20(erc20).transferFrom(msg.sender, treasury, toTreasury);

        poolIdToAccountToTokenIds[poolId_][msg.sender].push(_tokenId.current());
        poolIdToTokenIdToBet[poolId_][_tokenId.current()].stakeOn = result_;
        poolIdToTokenIdToBet[poolId_][_tokenId.current()].amount = amount_;
        poolToResultToAmount[poolId_][result_] += amount_;

        resultToStakesAmount[result_] += amount_;
        poolToStakesAmount[poolId_] += amount_;

        betIdToPoolId[_tokenId.current()] = poolId_;

        poolToAssets[poolId_] += toContract;

        tokenToMetadata[_tokenId.current()] = metadata_;

        for (uint256 i = 0; i < amount_; i++) {
            uint256 stakeId = _poolIdToStakeId[poolId_];
            poolIdToStakesIdToTokenId[poolId_][stakeId] = _tokenId.current();
            poolIdToBetIdToStakes[poolId_][_tokenId.current()].push(stakeId);
            _poolIdToStakeId[poolId_]++;
        }

        emit StakeCreated(
            msg.sender,
            result_,
            amount_,
            _tokenId.current(),
            poolId_,
            referralAddress_,
            metadata_
        );
        safeMint(msg.sender);
    }

    function revealPool(
        uint256 poolId_,
        uint256[] memory goldRandomNumbers_,
        uint256[] memory silverRandomNumbers_
    ) internal {
        poolToCommonStakesAmount[poolId_] =
            poolToStakesAmount[poolId_] -
            silverRandomNumbers_.length -
            goldRandomNumbers_.length;
        poolToSilverStakesAmount[poolId_] = silverRandomNumbers_.length;
        poolToGoldStakesAmount[poolId_] = goldRandomNumbers_.length;

        uint256 poolAssets = poolToAssets[poolId_];
        string[] memory results = stageToResults[pools[poolId_].stageId];

        for (uint256 i = 0; i < silverRandomNumbers_.length; i++) {
            uint256 tokenId = poolIdToStakesIdToTokenId[poolId_][
                silverRandomNumbers_[i]
            ];
            Stake memory currentBet = poolIdToTokenIdToBet[poolId_][tokenId];

            if (currentBet.amount != currentBet.silverAmount) {
                poolIdToTokenIdToBet[poolId_][tokenId].silverAmount++;
                poolIdToResultToSilverAmount[poolId_][currentBet.stakeOn]++;
            }
        }

        for (uint256 i = 0; i < goldRandomNumbers_.length; i++) {
            uint256 tokenId = poolIdToStakesIdToTokenId[poolId_][
                goldRandomNumbers_[i]
            ];
            Stake memory currentBet = poolIdToTokenIdToBet[poolId_][tokenId];

            if (
                currentBet.amount ==
                currentBet.goldAmount + currentBet.silverAmount &&
                currentBet.amount != currentBet.goldAmount
            ) {
                poolIdToTokenIdToBet[poolId_][tokenId].goldAmount++;
                poolIdToTokenIdToBet[poolId_][tokenId].silverAmount--;
                poolIdToResultToGoldAmount[poolId_][currentBet.stakeOn]++;
                poolIdToResultToSilverAmount[poolId_][currentBet.stakeOn]--;
            } else {
                poolIdToTokenIdToBet[poolId_][tokenId].goldAmount++;
                poolIdToResultToGoldAmount[poolId_][currentBet.stakeOn]++;
            }
        }

        for (uint256 i = 0; i < results.length; i++) {
            uint256 goldStakesAmount = poolIdToResultToGoldAmount[poolId_][
                results[i]
            ];
            uint256 silverStakesAmount = poolIdToResultToSilverAmount[poolId_][
                results[i]
            ];
            uint256 commonStakesAmount = poolToResultToAmount[poolId_][
                results[i]
            ] -
                goldStakesAmount -
                silverStakesAmount;

            if (
                commonStakesAmount == 0 &&
                silverStakesAmount == 0 &&
                goldStakesAmount == 0
            ) {
                poolToResultToPoint[poolId_][results[i]] = 0;
            } else {
                poolToResultToPoint[poolId_][results[i]] =
                    (poolAssets * (10**18)) /
                    (commonStakesAmount +
                        silverStakesAmount *
                        5 +
                        goldStakesAmount *
                        25);
            }

            poolIdToBetOnToTicketTypeToProfit[poolId_][results[i]][1] =
                poolToResultToPoint[poolId_][results[i]] /
                (10**18);
            poolIdToBetOnToTicketTypeToProfit[poolId_][results[i]][2] =
                (poolToResultToPoint[poolId_][results[i]] * 5) /
                (10**18);
            poolIdToBetOnToTicketTypeToProfit[poolId_][results[i]][3] =
                (poolToResultToPoint[poolId_][results[i]] * 25) /
                (10**18);
        }
    }

    function revealToken(uint256 tokenId_, string memory matadata)
        public
        onlyAdmin
        stageShouldBeFinished(tokenId_)
    {
        require(tokenId_ < _tokenId.current(), "Token doesn't exist");
        tokenToMetadata[tokenId_] = matadata;
    }

    function setWinner(uint256 sectionId_, string memory winner_)
        public
        onlyAdmin
    {
        require(sectionId_ < _sectionId.current(), "Section doesn't exist");
        require(
            sections[sectionId_].endDate <= block.timestamp,
            "Section is not finished"
        );
        sectionToWinner[sectionId_] = winner_;
        emit WinnerSet(sectionId_, winner_);
    }

    function claimReward(uint256 tokenId_)
        public
        shouldBeUsersToken(betIdToPoolId[tokenId_], tokenId_)
    {
        uint256 poolId = betIdToPoolId[tokenId_];
        Stake memory bet_ = poolIdToTokenIdToBet[poolId][tokenId_];
        require(
            ifStringsEqual(
                bet_.stakeOn,
                sectionToWinner[pools[poolId].sectionId]
            ),
            "You are not the winner"
        );
        uint256 commonStakesAmount = bet_.amount -
            bet_.goldAmount -
            bet_.silverAmount;
        uint256 commonStakeProfit = poolIdToBetOnToTicketTypeToProfit[poolId][
            bet_.stakeOn
        ][1];
        uint256 silverStakeProfit = poolIdToBetOnToTicketTypeToProfit[poolId][
            bet_.stakeOn
        ][2];
        uint256 goldStakeProfit = poolIdToBetOnToTicketTypeToProfit[poolId][
            bet_.stakeOn
        ][3];

        uint256 profit = commonStakeProfit *
            commonStakesAmount +
            silverStakeProfit *
            bet_.silverAmount +
            goldStakeProfit *
            bet_.goldAmount;

        burn(tokenId_);
        IERC20(erc20).transfer(msg.sender, profit);

        emit RewardClaimed(tokenId_);
    }

    function getPossibleSectionResults(uint256 sectionId_)
        public
        view
        returns (string[] memory)
    {
        return stageToResults[sectionId_];
    }

    function pause() public onlyAdmin {
        isPaused = true;
    }

    function unpause() public onlyAdmin {
        isPaused = false;
    }

    function safeMint(address to) private {
        uint256 tokenId = _tokenId.current();
        _tokenId.increment();
        _safeMint(to, tokenId);
    }

    function ifStringsEqual(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function ifItemInArray(uint256[] memory array, uint256 item)
        private
        pure
        returns (bool)
    {
        bool result_ = false;

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == item) {
                return result_ = true;
            }
        }

        return result_;
    }

    function convert(uint256 _a) private pure returns (uint32) {
        return uint32(_a);
    }

    function getIndexOfItemInArray(uint256[] memory array, uint256 item)
        private
        pure
        returns (uint256)
    {
        uint256 result_;

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == item) {
                result_ = i;
            }
        }

        return result_;
    }

    function withdraw(address to_, uint256 amount_) public onlyAdmin {
        IERC20(erc20).transfer(to_, amount_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        uint256[] memory tokenIds = poolIdToAccountToTokenIds[
            betIdToPoolId[tokenId]
        ][from];

        if (tokenIds.length > 0) {
            delete tokenIds[getIndexOfItemInArray(tokenIds, tokenId)];
            poolIdToAccountToTokenIds[betIdToPoolId[tokenId]][to].push(tokenId);
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable) {
        emit TokenTransfered(from, to, firstTokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}