// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IReferralPool {
    function getReferrer(address account) external view returns (address);
}

contract FamPredition is Ownable, VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum GameStatus {
        OPEN,
        CALCULATING,
        FREEZE
    }

    struct Meta {
        bool isOpen;
        uint8 betLimit;
        uint8 totalRefRate;
        uint8 withdrawFeeRate; // 5%
        uint32 withdrawMin; // withdraw mini rate
        uint32 epochInterval;
        uint32 callbackGasLimit;
        uint64 subscriptionId;
        bytes32 keyHash;
        uint256 currentRound;
        uint256 betRateLimit;
        uint256 totalBonusPaid;
    }

    struct Addr {
        IERC20 fam;
        // IERC20 usdt;
        IReferralPool refer;
        VRFCoordinatorV2Interface vrfCoordinator;
        address foundation;
        address fee;
    }

    enum BetType {
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }
    struct BetInfo {
        BetType position;
        uint256 betNumber;
        uint256 betRate;
    }

    struct Round {
        uint256 startTime;
        uint256 closeTime;
        uint256 luckNumber;
    }

    struct BetStatus {
        bool isBet;
        bool claimed;
    }
    // Ref => Referral
    struct User {
        uint256 minClaimedIndex;
        uint256 betAmount;
        uint256 betRewarded;
        uint256 refRewarded;
        address club;
    }

    Addr public addr;
    Meta public meta;

    GameStatus public gameStatus;

    uint8[5] public refRate;

    uint16 constant REQUEST_CONFIRMATIONS = 3;

    mapping(BetType => uint16) public winRate;

    mapping(address => bool) public bankers;

    mapping(uint256 => Round) public rounds;
    mapping(address => User) public userInfo;
    mapping(address => uint256[]) public userRounds; // user => roundIds
    mapping(uint256 => mapping(address => BetInfo[])) public userBets; // roundId => user => predition
    mapping(uint256 => mapping(address => BetStatus)) public userBetStatus; // roundId => user => betStatus

    // mapping(uint256 => uint256) public reqIdToRoundId;

    modifier checkSender() {
        require(_msgSender() == tx.origin, "forbidden");
        _;
    }

    modifier onlyBanker() {
        require(bankers[_msgSender()], "forbidden");
        _;
    }

    event ReturnedRandomness(uint256 indexed requestId, uint256 indexed lastRoundId, uint256 indexed luckNumber, uint256 randomWord);
    event RequestedRandomness(uint256 indexed requestId);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        address fam_,
        address refer_
    ) VRFConsumerBaseV2(vrfCoordinator) {
        addr.vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        meta.keyHash = keyHash;
        meta.subscriptionId = subscriptionId;
        meta.callbackGasLimit = callbackGasLimit;

        rounds[meta.currentRound].startTime = block.timestamp;

        meta.betLimit = 20;
        meta.betRateLimit = 50;
        meta.epochInterval = 10 * 60;

        meta.withdrawFeeRate = 5;
        meta.withdrawMin = 100;

        meta.totalRefRate = 15;

        addr.fam = IERC20(fam_);
        addr.refer = IReferralPool(refer_);
        addr.fee = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;
        addr.foundation = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;

        winRate[BetType.ONE] = 500;
        winRate[BetType.TWO] = 80;
        winRate[BetType.THREE] = 50;
        winRate[BetType.FOUR] = 5;
        winRate[BetType.FIVE] = 2;

        meta.isOpen = true;
    }

    function setFam(address fam_) external onlyOwner {
        addr.fam = IERC20(fam_);
    }

    function betBatch(
        uint256 epoch_,
        BetType[] memory positions_,
        uint256[2][] calldata infos_ // uint256[] memory betNumbers_, // uint256[] memory betrate_
    ) public {
        require(positions_.length == infos_.length, "length not match");
        require(meta.isOpen && gameStatus == GameStatus.OPEN, "bet is not open");
        Round storage round = rounds[epoch_];

        require(block.timestamp >= round.startTime, "not open");
        require(block.timestamp < round.closeTime || round.closeTime == 0, "closed");

        // BetInfo storage uBets = userBets[epoch_][msg.sender];
        require(userBets[epoch_][msg.sender].length + infos_.length <= meta.betLimit, "bet limit");

        if (rounds[epoch_].closeTime == 0) {
            rounds[epoch_].startTime = block.timestamp;
            rounds[epoch_].closeTime = block.timestamp + meta.epochInterval;
        }

        BetStatus storage uBetStatus = userBetStatus[epoch_][msg.sender];
        if (!uBetStatus.isBet) {
            uBetStatus.isBet = true;
            userRounds[msg.sender].push(epoch_);
        }

        uint256 totalBetAmount;
        for (uint256 i; i < positions_.length; i++) {
            totalBetAmount += infos_[i][1];
            bet(epoch_, positions_[i], infos_[i][0], infos_[i][1]);
        }

        totalBetAmount *= 1 ether;
        addr.fam.transferFrom(msg.sender, address(this), (totalBetAmount * 51) / 100);
        addr.fam.transferFrom(msg.sender, addr.foundation, (totalBetAmount * 28) / 100);

        userInfo[msg.sender].betAmount += totalBetAmount;
        _takeInviterReward(totalBetAmount, (totalBetAmount * meta.totalRefRate) / 100); // 15
    }

    function bet(
        uint256 epoch_,
        BetType position_,
        uint256 betNumber_,
        uint256 betRate_
    ) internal {
        if (position_ == BetType.FIVE) {
            require(betNumber_ >= 111 && betNumber_ <= 144, "mode error");
        } else {
            require(betNumber_ >= 1000 && betNumber_ <= 1999, "mode error");
        }

        userBets[epoch_][msg.sender].push(BetInfo({ position: position_, betNumber: betNumber_, betRate: betRate_ }));
    }

    function _takeInviterReward(uint256 amount_, uint256 totalRefReward_) internal {
        uint256 allowReward;
        address cludAddr;
        address current = msg.sender;
        for (uint8 i; i < 5; i++) {
            address inviter = addr.refer.getReferrer(current);
            if (inviter == address(0)) {
                break;
            }
            if (cludAddr == address(0) && userInfo[inviter].club != address(0)) {
                cludAddr = userInfo[inviter].club;
            }
            uint256 reward = (amount_ * refRate[i]) / 100;
            if (reward > 0) {
                allowReward += reward;
                userInfo[inviter].refRewarded += reward;
                addr.fam.transfer(inviter, reward);
            }
            current = inviter;
        }

        if (allowReward < totalRefReward_) {
            addr.fam.transfer(addr.foundation, totalRefReward_ - allowReward);
        }

        while (cludAddr == address(0) && current != address(0)) {
            address inviter = addr.refer.getReferrer(current);
            if (userInfo[inviter].club != address(0)) {
                cludAddr = userInfo[inviter].club;
                break;
            }
            current = inviter;
        }
        if (cludAddr == address(0)) {
            cludAddr = addr.foundation;
        }
        addr.fam.transfer(cludAddr, (amount_ * 6) / 100);
    }

    function _withdraw(uint256 reward_) private {
        meta.totalBonusPaid += reward_;
        reward_ *= 1 ether;

        if (reward_ >= meta.withdrawMin) {
            uint256 fee = (reward_ * meta.withdrawFeeRate) / 100;
            // userInfo[addr.fee].refRewarded += fee;
            addr.fam.transfer(addr.fee, fee);
            reward_ -= fee;
        }

        userInfo[msg.sender].betRewarded += reward_;
        addr.fam.transfer(msg.sender, reward_);
    }

    function withdrawBonus(uint256 epoch_) public {
        BetStatus storage uBetStatus = userBetStatus[epoch_][msg.sender];
        require(uBetStatus.isBet, "not reward");
        require(!uBetStatus.claimed, "already claim");

        (uint256 reward, , ) = getUserRoundInfo(msg.sender, epoch_);
        require(reward > 0, "reward is 0");

        uBetStatus.claimed = true;

        _withdraw(reward);
    }

    function withdrawAllBonus() public {
        (uint256 totalReward, uint256[] memory epochs) = queryAllUnPaidBonus(msg.sender);
        require(totalReward > 0, "reward is 0");

        // uint256 lastIndex;

        for (uint256 i; i < epochs.length; i++) {
            userBetStatus[epochs[i]][msg.sender].claimed = true;
            // lastIndex = epochs[i];
        }
        userInfo[msg.sender].minClaimedIndex += epochs.length;

        _withdraw(totalReward);
    }

    function requestRandomWords() internal {
        uint256 requestId = addr.vrfCoordinator.requestRandomWords(meta.keyHash, meta.subscriptionId, REQUEST_CONFIRMATIONS, meta.callbackGasLimit, 1);
        // rounds[meta.curRoundId].requestId = requestId;
        // reqIdToRoundId[requestId] = meta.curRoundId;
        // requestIds[rounds[oracleLatestRoundId].requestId] = oracleLatestRoundId;

        emit RequestedRandomness(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        Round storage round = rounds[meta.currentRound];
        uint256 luckNumber = (randomWords[0] % 1000) + 1000;
        round.luckNumber = luckNumber;
        gameStatus = GameStatus.OPEN;

        emit ReturnedRandomness(requestId, meta.currentRound, luckNumber, randomWords[0]);

        meta.currentRound++;
        rounds[meta.currentRound].startTime = block.timestamp;
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        Round memory round = rounds[meta.currentRound];
        bool isOpen = meta.isOpen && (GameStatus.OPEN == gameStatus);
        bool timePassed = (round.closeTime > 0 && block.timestamp > round.closeTime);
        upkeepNeeded = isOpen && timePassed;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");

        gameStatus = GameStatus.CALCULATING;
        requestRandomWords();
    }

    /******************************************* view function *******************************************/
    function getGameResult(uint256[] calldata epochs_) external view returns (uint256[] memory numbers) {
        numbers = new uint256[](epochs_.length);
        for (uint256 i; i < epochs_.length; i++) {
            numbers[i] = rounds[epochs_[i]].luckNumber;
        }
    }

    function getUserRoundsLength(address user) public view returns (uint256) {
        return userRounds[user].length;
    }

    function getUserRoundInfo(address account_, uint256 epoch_)
        public
        view
        returns (
            uint256 totalReward,
            BetInfo[] memory uBetInfo,
            uint256[] memory rewardInfo
        )
    {
        if (!userBetStatus[epoch_][account_].isBet) {
            return (0, uBetInfo, rewardInfo);
        }
        uBetInfo = userBets[epoch_][account_];
        rewardInfo = new uint256[](uBetInfo.length);
        for (uint256 i; i < uBetInfo.length; i++) {
            (, rewardInfo[i]) = coutingUserBetReward(account_, epoch_, i);
            totalReward += rewardInfo[i];
        }
    }

    function coutingUserBetReward(
        address account_,
        uint256 epoch_,
        uint256 index_
    ) public view returns (bool isWin, uint256 reward) {
        BetInfo memory uBetInfo = userBets[epoch_][account_][index_];
        Round memory round = rounds[epoch_];

        if (round.luckNumber == 0) {
            return (false, 0);
        }

        if (uBetInfo.position == BetType.ONE) {
            isWin = isMatchModeOne(uBetInfo.betNumber, round.luckNumber, 3);
        } else if (uBetInfo.position == BetType.TWO) {
            isWin = isMatchModeTwo(uBetInfo.betNumber, round.luckNumber);
        } else if (uBetInfo.position == BetType.THREE) {
            isWin = isMatchModeOne(uBetInfo.betNumber, round.luckNumber, 2);
        } else if (uBetInfo.position == BetType.FOUR) {
            isWin = isMatchModeOne(uBetInfo.betNumber, round.luckNumber, 1);
        } else if (uBetInfo.position == BetType.FIVE) {
            isWin = isMatchModeFive(uBetInfo.betNumber, round.luckNumber);
        } else {
            require(false, "epoch error");
        }

        if (isWin) {
            reward = uBetInfo.betRate * winRate[uBetInfo.position];
        }
    }

    function queryAllUnPaidBonus(address account_) public view returns (uint256 totalReward, uint256[] memory epochs) {
        uint256 length = userRounds[account_].length; // 2
        uint256 i = userInfo[account_].minClaimedIndex; // 1

        if (i >= length) {
            return (0, epochs);
        }

        epochs = new uint256[](length - i);
        uint256 index;
        for (i; i < length; i++) {
            uint256 epoch = userRounds[account_][i];
            if (userBetStatus[epoch][account_].claimed || rounds[epoch].luckNumber == 0) {
                continue;
            }
            epochs[index] = epoch;
            ++index;
            (uint256 reward, , ) = getUserRoundInfo(account_, epoch);
            totalReward += reward;
        }

        return (totalReward, epochs);
    }

    function getUserRounds(
        address account_,
        uint256 cursor_,
        uint256 size_
    ) external view returns (uint256[] memory) {
        uint256 length = size_;
        if (length > userRounds[account_].length - cursor_) {
            length = userRounds[account_].length - cursor_;
        }

        uint256[] memory roundIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            roundIds[i] = userRounds[account_][cursor_ + i];
        }

        return roundIds;
    }

    function check(address account_)
        public
        view
        returns (
            GameStatus status,
            uint256 lastResult,
            uint256[7] memory infos
        )
    {
        status = gameStatus;

        uint256 curRound = meta.currentRound;

        if (curRound >= 1) {
            lastResult = rounds[curRound - 1].luckNumber;
        }

        infos[0] = curRound;

        infos[1] = rounds[curRound].startTime;
        infos[2] = rounds[curRound].closeTime;

        infos[3] = meta.betLimit;
        infos[4] = meta.betRateLimit;
        infos[5] = meta.epochInterval;

        if (account_ != address(0)) {
            infos[6] = getUserRoundsLength(account_);
        }
    }

    function bigOrSmall(uint256 number_, bool isBig_) public pure returns (bool) {
        return isBig_ ? number_ > 4 : number_ < 5;
    }

    function singleOrDouble(uint256 number_, bool isSingle_) public pure returns (bool) {
        return isSingle_ ? number_ % 2 == 1 : number_ % 2 == 0;
    }

    function numberByReverseIndex(uint256 number_, uint256 index_) public pure returns (uint256) {
        for (uint256 i; i < index_; i++) {
            number_ /= 10;
        }
        return number_ % 10;
    }

    function isMatchModeOne(
        uint256 userNumber_,
        uint256 luckNumber_,
        uint256 size_
    ) public pure returns (bool) {
        require(size_ == 1 || size_ == 2 || size_ == 3, "size must be 5 or 6");
        for (uint256 i; i < size_; i++) {
            if (userNumber_ % 10 != luckNumber_ % 10) {
                return false;
            }

            userNumber_ /= 10;
            luckNumber_ /= 10;
        }
        return true;
    }

    function isMatchModeTwo(uint256 userNumber_, uint256 luckNumber_) public pure returns (bool) {
        uint8[10] memory userNumberCount;
        uint8[10] memory luckNumberCount;

        for (uint256 i; i < 3; i++) {
            userNumberCount[userNumber_ % 10]++;
            luckNumberCount[luckNumber_ % 10]++;

            userNumber_ /= 10;
            luckNumber_ /= 10;
        }

        for (uint8 i; i < 10; i++) {
            if (userNumberCount[i] != luckNumberCount[i]) {
                return false;
            }
        }
        return true;
    }

    function isMatchModeFive(uint256 choice_, uint256 luckNumber_) public pure returns (bool) {
        require(choice_ >= 111 && choice_ <= 144, "mode error");
        bool matchResult;
        for (uint256 i; i < 2; i++) {
            uint256 choice = numberByReverseIndex(choice_, i);
            uint256 key = numberByReverseIndex(luckNumber_, i);
            if (choice == 1) {
                matchResult = bigOrSmall(key, false);
            } else if (choice == 2) {
                matchResult = bigOrSmall(key, true);
            } else if (choice == 3) {
                matchResult = singleOrDouble(key, true);
            } else if (choice == 4) {
                matchResult = singleOrDouble(key, false);
            } else {
                revert("mode is not support");
            }
            if (!matchResult) {
                return false;
            }
        }
        return true;
    }

    /******************************************* owner function *******************************************/
    function testRun(uint256 randomWord_) public {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");

        gameStatus = GameStatus.CALCULATING;
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomWord_;
        fulfillRandomWords(111, randomWords);
    }

    function setGameStatus(bool isOpen_) public onlyOwner {
        meta.isOpen = isOpen_;
    }

    function setBankers(address[] calldata accounts_, bool isAdd_) public onlyOwner {
        for (uint256 i; i < accounts_.length; i++) {
            bankers[accounts_[i]] = isAdd_;
        }
    }

    function setBetInfo(
        uint8 betLimit_,
        uint256 betRateLimit_,
        uint32 epochInterval_
    ) public onlyOwner {
        meta.betLimit = betLimit_;
        meta.betRateLimit = betRateLimit_;
        meta.epochInterval = epochInterval_;
    }

    function setWithdrawFee(uint8 withdrawFeeRate_, uint32 withdrawMin_) public onlyOwner {
        meta.withdrawFeeRate = withdrawFeeRate_;
        meta.withdrawMin = withdrawMin_;
    }

    function setWinnerRate(uint16[] calldata rates_) public onlyOwner {
        for (uint256 i; i < rates_.length; i++) {
            winRate[BetType(i)] = rates_[i];
        }
    }

    function setReferrerRate(uint8 totalRefRate_, uint8[] calldata refRates_) public onlyOwner {
        meta.totalRefRate = totalRefRate_;
        uint16 totalRate;
        for (uint8 i; i < refRates_.length; i++) {
            refRate[i] = refRates_[i];
            totalRate += refRates_[i];
        }
        require(totalRate == totalRefRate_, "wrong rate");
    }

    function setChainLinkInfo(
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint32 callbackGasLimit_
    ) public onlyOwner {
        addr.vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        meta.keyHash = keyHash_;
        meta.subscriptionId = subscriptionId_;
        meta.callbackGasLimit = callbackGasLimit_;
    }

    function setAddress(
        address refer_,
        address foundation_,
        address fee_
    ) public onlyOwner {
        addr.refer = IReferralPool(refer_);

        addr.foundation = foundation_;
        addr.fee = fee_;
    }

    function setUserClub(address[] calldata accounts_, address[] calldata clubs_) public onlyBanker {
        require(accounts_.length == clubs_.length, "length not match");
        for (uint256 i; i < clubs_.length; i++) {
            userInfo[accounts_[i]].club = clubs_[i];
        }
    }

    function divest(
        address token_,
        address payee_,
        uint256 value_
    ) external onlyOwner {
        IERC20(token_).transfer(payee_, value_);
    }
}