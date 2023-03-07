pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IMonthlyLottery.sol";
import "./IRandomizer.sol";

contract MonthlyLottery is Initializable, IMonthlyLottery, OwnableUpgradeable {
    uint256 public lotteryCounter;
    IRandomizer randomizer;
    uint8[10] public prizes;
    address public weeklyLottery;
    address public slots;
    address public manager;
    uint256 public nextLotteryTimestamp;
    uint256 public lotteryPeriod;
    uint256 public lastDrawBlock;
    uint256 public uniqueUsersCount;
    uint256 public participantsCount;
    address[] public participants;

    mapping(uint256 => mapping(address => uint256)) public userTikets;
    mapping(uint256 => mapping(address => bool)) public isUserUniqueCheckpoint;
    mapping(address => UserStats) public userStats;
    mapping(address => uint256) public lastDrawBlockForUser;

    struct UserStats {
        uint256 participateAmount;
        uint256 lottereysWins;
        uint256 fundsWin;
    }

    event LotteryDrawn(
        uint256 lotteryId,
        address[10] winners,
        uint256[10] prizes,
        uint256 lastDrawBlock
    );
    event UserWon(address user, uint256 reward, uint256 lastDrawBlock);

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
        lotteryPeriod = 2629743; // 1 month
        nextLotteryTimestamp = block.timestamp + lotteryPeriod;
    }

    function setSlots(address _slots) external onlyOwner {
        require(_slots != address(0), "Lottery:Slots address is zero");
        slots = _slots;
    }

    function setWeeklyLottery(address _weeklyLottery) external onlyOwner {
        require(
            _weeklyLottery != address(0),
            "Lottery::Address must be different than 0"
        );
        weeklyLottery = _weeklyLottery;
    }

    function setManager(address _manager) external onlyOwner {
        require(
            _manager != address(0),
            "Lottery::Address must be different than 0"
        );
        manager = _manager;
    }

    function addParticipant(address _participant)
        external
        override
        returns (bool)
    {
        require(msg.sender == slots, "Lottery:Not slots");
        participants.push(_participant);
        participantsCount++;
        userTikets[lotteryCounter][_participant]++;
        bool isReenter = isUserUniqueCheckpoint[lotteryCounter][_participant];
        if (!isReenter) {
            uniqueUsersCount++;
            isUserUniqueCheckpoint[lotteryCounter][_participant] = true;
        }
        userStats[_participant].participateAmount++;
        return true;
    }

    function startLottery() external {
        require(
            msg.sender == manager || msg.sender == owner(),
            "Lottery:Not manager"
        );
        require(uniqueUsersCount >= 15, "Lottery:Not enough participants");
        require(address(this).balance >= 1000, "Lottery: Not enough funds");
        lotteryCounter++;
        nextLotteryTimestamp = block.timestamp + lotteryPeriod;
        _payProcess(_getWinners());
        uniqueUsersCount = 0;
        lastDrawBlock = block.number;
    }

    function _payProcess(address[10] memory winners) internal {
        uint256 balance = address(this).balance;
        uint256 prize;

        address[10] memory winnersAddresses;
        uint256[10] memory prizesAmounts;

        for (uint256 i = 0; i < 10; ) {
            prize = (balance * prizes[i]) / 100;
            winnersAddresses[i] = winners[i];
            prizesAmounts[i] = prize;
            (bool result, ) = winners[i].call{value: prize}("");
            require(result, "Weekly lottery transfer failed");
            userStats[winners[i]].lottereysWins++;
            userStats[winners[i]].fundsWin += prize;
            emit UserWon(winners[i], prize, lastDrawBlockForUser[winners[i]]);
            lastDrawBlockForUser[winners[i]] = block.number;
            unchecked {
                i++;
            }
        }
        emit LotteryDrawn(
            lotteryCounter,
            winnersAddresses,
            prizesAmounts,
            lastDrawBlock
        );
        delete participants;
    }

    function _findFirstWinner() internal view returns (address) {
        uint256 firstWinnerIndex = randomizer.random(
            lotteryCounter,
            participants.length,
            address(0)
        );
        return participants[firstWinnerIndex];
    }

    function _getWinners() internal view returns (address[10] memory winners) {
        winners[0] = _findFirstWinner();
        address lastWinner = winners[0];
        uint256 cyclesCounter;
        for (uint256 i = 1; i < 10; ) {
            cyclesCounter++;
            uint256 randomIndex = randomizer.random(
                cyclesCounter,
                participants.length,
                lastWinner
            );
            if (_checkWinnerUnique(winners, participants[randomIndex])) {
                winners[i] = participants[randomIndex];
                lastWinner = participants[randomIndex];
            } else {
                i--;
            }
            unchecked {
                i++;
            }
        }
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