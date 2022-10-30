// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "hardhat/console.sol";

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
        // bool isOpen;
        uint8 betNumberLimit;
        uint8 withdrawFeeRate; // 5%
        uint32 withdrawMin; // withdraw mini rate
        uint32 epochInterval;
        // uint32 callbackGasLimit;
        // uint64 subscriptionId;
        // bytes32 keyHash;

        // uint256 betMinBaseFee;
        // uint256 betMaxBaseFee;
        uint256 currentRound;
        uint256 betRateLimit;
        uint256 totalBonusPaid;
    }

    uint32 private callbackGasLimit;
    uint64 private subscriptionId;
    bytes32 private keyHash;

    uint8 private constant TOTAL_REF_RATE = 15;

    struct Addr {
        IERC20 fam;
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
        uint256 baseFee;
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
    struct User {
        uint256 minClaimedIndex;
        uint256 betAmount;
        uint256 betRewarded;
        uint256 refReward;
        uint256 refRewarded;
        address club;
    }

    uint16 constant REQUEST_CONFIRMATIONS = 3;
    Addr public addr;
    Meta public meta;
    GameStatus public gameStatus;

    uint8[5] public refRate;
    mapping(BetType => uint16) public winRate;
    mapping(address => bool) public bankers;
    mapping(uint256 => Round) public rounds;
    mapping(address => User) public userInfo;
    mapping(address => uint256[]) public userRounds; // user => roundIds
    mapping(uint256 => mapping(address => BetInfo[])) public userBets; // roundId => user => predition
    mapping(uint256 => mapping(address => BetStatus)) public userBetStatus; // roundId => user => betStatus

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
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint32 callbackGasLimit_,
        address fam_,
        address refer_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        addr.vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        callbackGasLimit = callbackGasLimit_;

        rounds[meta.currentRound].startTime = block.timestamp;

        meta.betNumberLimit = 20;
        meta.betRateLimit = 50;
        meta.epochInterval = 10 * 60;

        meta.withdrawFeeRate = 5;
        meta.withdrawMin = 100;

        addr.fam = IERC20(fam_);
        addr.refer = IReferralPool(refer_);

        addr.foundation = 0x1A960b5FE56eD32653D4098fDE6bEf7f3f2C083C;
        addr.fee = msg.sender;

        winRate[BetType.ONE] = 500;
        winRate[BetType.TWO] = 80;
        winRate[BetType.THREE] = 50;
        winRate[BetType.FOUR] = 5;
        winRate[BetType.FIVE] = 2;

        refRate[0] = 8;
        refRate[1] = 5;
        refRate[2] = 2;
        refRate[3] = 1;
        refRate[4] = 1;

        // meta.isOpen = true;
    }

    function betBatch(
        uint256 epoch_,
        uint256 baseFee_,
        BetType[] memory positions_,
        uint256[2][] calldata infos_ // betNumbers, betRate
    ) external {
        require(positions_.length == infos_.length, "length not match");
        require(gameStatus == GameStatus.OPEN, "not start");
        // require(baseFee_ >= meta.betMinBaseFee && baseFee_ <= meta.betMaxBaseFee, "baseFee not match");
        require(baseFee_ == 0.5 ether || baseFee_ == 0.1 ether || baseFee_ == 1 ether || baseFee_ == 2 ether || baseFee_ == 5 ether || baseFee_ == 10 ether, "baseFee not support");

        Round memory round = rounds[epoch_];

        require(block.timestamp >= round.startTime, "not open");
        require(block.timestamp < round.closeTime || round.closeTime == 0, "closed");

        // BetInfo storage uBets = userBets[epoch_][msg.sender];
        require(userBets[epoch_][msg.sender].length + infos_.length <= meta.betNumberLimit, "bet limit exceeded");

        if (round.closeTime == 0) {
            rounds[epoch_].startTime = block.timestamp;
            rounds[epoch_].closeTime = block.timestamp + meta.epochInterval;
        }

        // BetStatus storage uBetStatus = userBetStatus[epoch_][msg.sender];
        if (!userBetStatus[epoch_][msg.sender].isBet) {
            userBetStatus[epoch_][msg.sender].isBet = true;
            userRounds[msg.sender].push(epoch_);
        }

        uint256 totalBetAmount;
        for (uint256 i; i < positions_.length; ++i) {
            totalBetAmount += infos_[i][1];
            bet(epoch_, baseFee_, positions_[i], infos_[i][0], infos_[i][1]);
        }

        totalBetAmount *= baseFee_;
        addr.fam.transferFrom(msg.sender, address(this), totalBetAmount);
        // addr.fam.transferFrom(msg.sender, address(this), (totalBetAmount * 51) / 100);
        addr.fam.transfer(addr.foundation, (totalBetAmount * 28) / 100);

        userInfo[msg.sender].betAmount += totalBetAmount;
        _takeInviterReward(totalBetAmount, (totalBetAmount * TOTAL_REF_RATE) / 100); // 15
    }

    function bet(
        uint256 epoch_,
        uint256 baseFee_,
        BetType position_,
        uint256 betNumber_,
        uint256 betRate_
    ) internal {
        if (position_ == BetType.FIVE) {
            require(betNumber_ >= 111 && betNumber_ <= 144, "mode error");
        } else {
            require(betNumber_ >= 1000 && betNumber_ <= 1999, "mode error");
        }

        userBets[epoch_][msg.sender].push(BetInfo({ position: position_, betNumber: betNumber_, betRate: betRate_, baseFee: baseFee_ }));
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
                userInfo[inviter].refReward += reward;
                // addr.fam.transfer(inviter, reward);
            }
            current = inviter;
        }

        if (allowReward < totalRefReward_) {
            userInfo[addr.foundation].refReward += (totalRefReward_ - allowReward);
            // addr.fam.transfer(addr.foundation, totalRefReward_ - allowReward);
        }

        address last;
        while (cludAddr == address(0) && current != address(0)) {
            address inviter = addr.refer.getReferrer(current);
            if (inviter == last) {
                break;
            }
            if (userInfo[inviter].club != address(0)) {
                cludAddr = userInfo[inviter].club;
                break;
            }
            last = current;
            current = inviter;
        }

        if (cludAddr == address(0)) {
            cludAddr = addr.foundation;
        }

        userInfo[cludAddr].refReward += (amount_ * 6) / 100;
        // addr.fam.transfer(cludAddr, (amount_ * 6) / 100);
    }

    function withdrawRefReward() external {
        uint256 reward = userInfo[msg.sender].refReward - userInfo[msg.sender].refRewarded;
        require(reward > 0, "no reward");
        userInfo[msg.sender].refReward = userInfo[msg.sender].refRewarded;
        addr.fam.transfer(msg.sender, reward);
    }

    function _withdraw(uint256 reward_) private {
        meta.totalBonusPaid += reward_;

        if (reward_ >= meta.withdrawMin) {
            uint256 fee = (reward_ * meta.withdrawFeeRate) / 100;
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

    function withdrawAllBonus() external checkSender {
        (uint256 totalReward, uint256[] memory epochs) = queryAllUnPaidBonus(msg.sender);
        require(totalReward > 0, "reward is 0");

        for (uint256 i; i < epochs.length; i++) {
            userBetStatus[epochs[i]][msg.sender].claimed = true;
        }
        userInfo[msg.sender].minClaimedIndex += epochs.length;

        _withdraw(totalReward);
    }

    function requestRandomWords() internal {
        uint256 requestId = addr.vrfCoordinator.requestRandomWords(keyHash, subscriptionId, REQUEST_CONFIRMATIONS, callbackGasLimit, 1);

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

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");

        gameStatus = GameStatus.CALCULATING;
        requestRandomWords();
    }

    /******************************************* view function *******************************************/

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
        // bool isOpen = meta.isO meta.isOpen && (GameStatus.OPEN == gameStatus);
        bool isOpen = GameStatus.OPEN == gameStatus;
        bool timePassed = (round.closeTime > 0 && block.timestamp > round.closeTime);
        upkeepNeeded = isOpen && timePassed;
    }

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

    function isMatch(
        BetType position_,
        uint256 betNumber_,
        uint256 luckNumber_
    ) private pure returns (bool) {
        if (position_ == BetType.ONE) {
            return isMatchModeOne(betNumber_, luckNumber_, 3);
        }
        if (position_ == BetType.TWO) {
            return isMatchModeTwo(betNumber_, luckNumber_);
        }
        if (position_ == BetType.THREE) {
            return isMatchModeOne(betNumber_, luckNumber_, 2);
        }
        if (position_ == BetType.FOUR) {
            return isMatchModeOne(betNumber_, luckNumber_, 1);
        }
        if (position_ == BetType.FIVE) {
            return isMatchModeFive(betNumber_, luckNumber_);
        }
        return false;
    }

    function isWinner(address account_, uint256 epoch_) public view returns (bool) {
        Round memory round = rounds[epoch_];
        if (round.luckNumber == 0) {
            return false;
        }
        uint256 size = userBets[epoch_][account_].length;
        for (uint256 i; i < size; i++) {
            BetInfo memory uBetInfo = userBets[epoch_][account_][i];
            if (isMatch(uBetInfo.position, uBetInfo.betNumber, round.luckNumber)) {
                return true;
            }
        }
        return false;
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

        isWin = isMatch(uBetInfo.position, uBetInfo.betNumber, round.luckNumber);

        if (isWin) {
            reward = uBetInfo.betRate * winRate[uBetInfo.position] * uBetInfo.baseFee;
        }
    }

    function queryAllUnPaidBonus(address account_) public view returns (uint256 totalReward, uint256[] memory epochs) {
        uint256 length = userRounds[account_].length;
        uint256 i = userInfo[account_].minClaimedIndex;

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
    ) external view returns (uint256[] memory, bool[] memory) {
        uint256 length = size_;
        if (length > userRounds[account_].length - cursor_) {
            length = userRounds[account_].length - cursor_;
        }

        uint256[] memory roundIds = new uint256[](length);
        bool[] memory isWinners = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            roundIds[i] = userRounds[account_][cursor_ + i];
            isWinners[i] = isWinner(account_, roundIds[i]);
        }

        return (roundIds, isWinners);
    }

    function check(address account_)
        public
        view
        returns (
            GameStatus status,
            uint256 lastResult,
            uint256[9] memory infos
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

        infos[3] = meta.betNumberLimit;
        infos[4] = meta.betRateLimit;
        infos[5] = meta.epochInterval;

        if (account_ != address(0)) {
            infos[6] = getUserRoundsLength(account_);
        }
        infos[7] = userInfo[account_].refReward - userInfo[account_].refRewarded;
        infos[8] = userInfo[account_].refRewarded;
    }

    function chainlinkInfo()
        external
        view
        returns (
            uint32,
            uint64,
            bytes32
        )
    {
        return (callbackGasLimit, subscriptionId, keyHash);
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

    function setFam(address fam_) external onlyOwner {
        addr.fam = IERC20(fam_);
    }

    function setAddress(
        address refer_,
        address foundation_,
        address fee_
    ) external onlyOwner {
        addr.refer = IReferralPool(refer_);

        addr.foundation = foundation_;
        addr.fee = fee_;
    }

    // function serBetBaseFee(uint256 minBaseFee_, uint256 maxBaseFee_) external onlyOwner {
    //     require(minBaseFee_ <= maxBaseFee_, "minBaseFee_ > maxBaseFee_");
    //     meta.betMinBaseFee = minBaseFee_;
    //     meta.betMaxBaseFee = maxBaseFee_;
    // }

    function setBetInfo(
        uint8 betNumberLimit_,
        uint256 betRateLimit_,
        uint32 epochInterval_
    ) external onlyOwner {
        meta.betNumberLimit = betNumberLimit_;
        meta.betRateLimit = betRateLimit_;
        meta.epochInterval = epochInterval_;
    }

    function testRun(uint256 randomWord_) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");

        gameStatus = GameStatus.CALCULATING;
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomWord_;
        fulfillRandomWords(111, randomWords);
    }

    function setGameStatus(bool isOpen_) external onlyOwner {
        if (isOpen_) {
            gameStatus = GameStatus.OPEN;
        } else {
            gameStatus = GameStatus.FREEZE;
        }
        // meta.isOpen = isOpen_;
    }

    function setBankers(address[] calldata accounts_, bool isAdd_) external onlyOwner {
        for (uint256 i; i < accounts_.length; i++) {
            bankers[accounts_[i]] = isAdd_;
        }
    }

    function setWithdrawFee(uint8 withdrawFeeRate_, uint32 withdrawMin_) external onlyOwner {
        meta.withdrawFeeRate = withdrawFeeRate_;
        meta.withdrawMin = withdrawMin_;
    }

    function setWinnerRate(uint16[] calldata rates_) external onlyOwner {
        for (uint256 i; i < rates_.length; i++) {
            winRate[BetType(i)] = rates_[i];
        }
    }

    function setReferrerRate(uint8[] calldata refRates_) external onlyOwner {
        uint16 totalRate;
        for (uint8 i; i < refRates_.length; i++) {
            refRate[i] = refRates_[i];
            totalRate += refRates_[i];
        }
        require(totalRate == TOTAL_REF_RATE, "wrong rate");
    }

    function setChainLinkInfo(
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint32 callbackGasLimit_
    ) external onlyOwner {
        addr.vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        callbackGasLimit = callbackGasLimit_;
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