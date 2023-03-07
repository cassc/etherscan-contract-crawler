pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IWeeklyLottery.sol";
import "./IRandomizer.sol";

contract WeeklyLottery is Initializable, IWeeklyLottery, OwnableUpgradeable {
    uint256 public lotteryCounter;
    IRandomizer randomizer;
    uint8[10] public prizes;
    uint256 public nextLotteryTimestamps;
    uint256 public lotteryPeriod;
    address public monthLottery;
    address public slots;
    address public manager;

    mapping(uint256 => uint256) public slotsToLotteryCount;
    mapping(uint256 => uint256) public slotsToFunds;
    mapping(uint256 => uint256) public slotsToParticipantsCount;
    mapping(uint256 => address[]) public slotsToParticipants;
    mapping(uint256 => uint256) public lastDrawBlock;
    mapping(uint256 => mapping(address => UserStats)) public slotsToUserStats;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        public slotsToUserTikets;
    mapping(uint256 => uint256) public uniqueUsersCount;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public isUserUniqueCheckpoint;
    mapping(uint256 => mapping(address => uint256)) public lastDrawBlockForUser;

    struct UserStats {
        uint256 participateAmount;
        uint256 lottereysWins;
        uint256 fundsWin;
    }

    event LotteryDrawn(
        uint256 lotteryId,
        uint256 bet,
        address[10] winners,
        uint256[10] prizes,
        uint256 lastDrawBlock
    );
    event UserWon(
        address user,
        uint256 bet,
        uint256 reward,
        uint256 lastDrawBlock
    );
    event UserEnter(address user, uint256 bet);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    fallback() external payable {}

    receive() external payable {}

    function initialize(address _randomizer) external initializer {
        __Ownable_init();
        randomizer = IRandomizer(_randomizer);
        prizes = [20, 15, 12, 10, 8, 7, 7, 7, 7, 7];
        lotteryPeriod = 604800; // 1 week
        nextLotteryTimestamps = block.timestamp + lotteryPeriod;
    }

    function setSlots(address _slots) external onlyOwner {
        require(_slots != address(0), "Lottery:Slots address is zero");
        slots = _slots;
    }

    function setMonthLottery(address payable _month) external onlyOwner {
        require(_month != address(0), "Lottery:Slots address is zero");
        monthLottery = _month;
    }

    function setManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Lottery:Slots address is zero");
        manager = _manager;
    }

    function addParticipant(uint256 _bet, address _participant)
        external
        override
        returns (bool)
    {
        require(msg.sender == slots, "Lottery:Not slots");
        slotsToParticipants[_bet].push(_participant);
        slotsToParticipantsCount[_bet]++;
        uint256 _count = slotsToLotteryCount[_bet];
        slotsToUserTikets[_bet][_count][_participant]++;
        bool isReenter = isUserUniqueCheckpoint[_bet][_count][_participant];
        if (!isReenter) {
            uniqueUsersCount[_bet]++;
            isUserUniqueCheckpoint[_bet][_count][_participant] = true;
        }
        slotsToUserStats[_bet][_participant].participateAmount++;
        emit UserEnter(_participant, _bet);
        return true;
    }

    function recordTransfer(uint256 _bet, uint256 _amount)
        external
        override
        returns (bool)
    {
        require(msg.sender == slots, "Lottery:Not slots");
        slotsToFunds[_bet] += _amount;
        return true;
    }

    function startLottery(uint256[] calldata _bets) external {
        require(
            msg.sender == manager || msg.sender == owner(),
            "Lottery:Not manager"
        );
        require(_bets.length > 0, "Lottery: Array is empty");

        for (uint256 i = 0; i < _bets.length; ) {
            if (
                slotsToParticipants[_bets[i]].length > 0 &&
                slotsToFunds[_bets[i]] >= 1000
            ) {
                _startLottery(_bets[i]);
                lastDrawBlock[_bets[i]] = block.number;
            }
            unchecked {
                i++;
            }
        }

        nextLotteryTimestamps = block.timestamp + lotteryPeriod;
    }

    function _startLottery(uint256 _bet) internal {
        require(
            slotsToParticipants[_bet].length > 0,
            "Lottery:Not enough participants"
        );
        require(slotsToFunds[_bet] >= 1000, "Lottery: Not enough funds");

        _payProcess(_bet, _getWinners(_bet));

        delete slotsToParticipants[_bet];
        uniqueUsersCount[_bet] = 0;
        slotsToFunds[_bet] = 0;
        slotsToLotteryCount[_bet]++;
    }

    function _getWinners(uint256 _bet)
        internal
        returns (address[10] memory winners)
    {
        winners[0] = _findFirstWinner(_bet);
        address lastWinner = winners[0];
        uint256 cyclesCounter;
        uint256 winnersCount;

        if (uniqueUsersCount[_bet] >= 20) {
            winnersCount = 10;
        } else {
            winnersCount = uniqueUsersCount[_bet] / 2;
        }

        for (uint256 i = 1; i < winnersCount; ) {
            cyclesCounter++;
            uint256 randomIndex = randomizer.random(
                cyclesCounter,
                slotsToParticipants[_bet].length,
                lastWinner
            );
            if (
                _checkWinnerUnique(
                    winners,
                    slotsToParticipants[_bet][randomIndex]
                )
            ) {
                winners[i] = slotsToParticipants[_bet][randomIndex];
                lastWinner = slotsToParticipants[_bet][randomIndex];
            } else {
                i--;
            }
            unchecked {
                i++;
            }
        }
        for (uint256 i = winnersCount; i < 10; ) {
            winners[i] = address(0);
            unchecked {
                i++;
            }
        }
    }

    function _findFirstWinner(uint256 _bet) internal returns (address) {
        lotteryCounter++;
        uint256 firstWinnerIndex = randomizer.random(
            lotteryCounter,
            slotsToParticipants[_bet].length,
            address(0)
        );
        return slotsToParticipants[_bet][firstWinnerIndex];
    }

    function _payProcess(uint256 _bet, address[10] memory winners) internal {
        uint256 balance = slotsToFunds[_bet];
        uint256 prize;
        address[10] memory winnersAddresses;
        uint256[10] memory prizesAmounts;

        if (monthLottery != address(0)) {
            uint256 monthShare = (balance * 3) / 10;
            (bool result, ) = monthLottery.call{value: monthShare}("");
            require(result, "Weekly lottery transfer failed");
            balance -= monthShare;
        }

        for (uint256 i = 0; i < 10; ) {
            prize = (balance * prizes[i]) / 100;
            winnersAddresses[i] = winners[i];
            prizesAmounts[i] = prize;
            if (winners[i] != address(0)) {
                (bool result, ) = winners[i].call{value: prize}("");
                require(result, "Weekly lottery transfer failed");
                slotsToUserStats[_bet][winners[i]].lottereysWins++;
                slotsToUserStats[_bet][winners[i]].fundsWin += prize;
                emit UserWon(
                    winners[i],
                    _bet,
                    prize,
                    lastDrawBlockForUser[_bet][winners[i]]
                );
                lastDrawBlockForUser[_bet][winners[i]] = block.number;
            } else {
                (bool result, ) = monthLottery.call{value: prize}("");
                require(result, "Weekly lottery transfer failed");
            }
            unchecked {
                i++;
            }
        }

        emit LotteryDrawn(
            slotsToLotteryCount[_bet],
            _bet,
            winnersAddresses,
            prizesAmounts,
            lastDrawBlock[_bet]
        );
    }

    function _checkWinnerUnique(address[10] memory winners, address winner)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < 10; ) {
            if (winners[i] == winner) {
                return false;
            }
            unchecked {
                i++;
            }
        }
        return true;
    }
}