pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./lib/IPassport.sol";
import "./IWeeklyLottery.sol";
import "./IMonthlyLottery.sol";
import "./IRandomizer.sol";

contract Slots is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IRandomizer randomizer;
    uint256 public usersCounter;
    uint256 public gamesCounter;
    uint256 public totalBet;
    uint256 public calcFundsState;
    uint256 public LEAVE_COMISSION;
    uint256 public TENTH_USER_COMPENSATION;
    address public comissionsAddress;
    address public mainRefAddress;
    address public weeklyLottery;
    address public monthLottery;
    address public passportsAddress;
    bool public canLeave;

    mapping(address => UserProfile) public userProfiles;
    mapping(address => address) public referrers;
    mapping(address => mapping(uint256 => uint256)) public userStatuses;
    mapping(uint256 => uint256) public lastDrawBlock;
    mapping(string => address) public nicknamesToAddresses;
    mapping(string => bool) public nicknamesUsed;
    mapping(address => uint256) public usersMonthlyCounter;
    mapping(uint256 => Game) public games;
    mapping(uint256 => bool) public accceptedBets;
    mapping(uint256 => mapping(address => uint256)) public lastDrawBlockForUser;
    mapping(address => uint256) public lastRefBlockForUser;

    struct UserProfile {
        string nickname;
        uint256 gamesPlayed;
        uint256 gamesWon;
        uint256 gamesLost;
        uint256 totalBet;
        uint256 totalWon;
        uint256 totalLost;
        uint256 totalRefEarn;
        bool isRegistered;
    }

    struct Game {
        uint256 id;
        uint256 timestamp;
        address[10] players;
    }

    event GameStarted(uint256 gameId, uint256 bet);
    event GameFinished(
        uint256 gameId,
        uint256 bet,
        uint256 reward,
        uint256 lastDrawnBlock,
        address[7] winners,
        address[3] losers
    );
    event UserRegistered(address user, string nickname, address referrer);
    event UserCameIn(address user, uint256 bet, uint256 gameId);
    event UserLeave(address user, uint256 bet, uint256 gameId);
    event UserWon(
        address user,
        uint256 bet,
        uint256 gameId,
        uint256 reward,
        uint256 lastDrawnBlock
    );
    event UserLost(address user, uint256 bet, uint256 gameId);
    event RefPaid(
        address user,
        address referrer,
        uint256 amount,
        uint256 lastRefBlock
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    fallback() external payable {}

    function initialize(
        address _randomizer,
        address _comissionsAddress,
        address _mainReferrer
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        randomizer = IRandomizer(_randomizer);
        comissionsAddress = _comissionsAddress;
        mainRefAddress = _mainReferrer;
        canLeave = true;
        TENTH_USER_COMPENSATION = 0.005 ether;
        LEAVE_COMISSION = 100; // 10000 = 100% 100 = 1%
    }

    function betControl(uint256 _bet, bool _accept) external onlyOwner {
        require(_bet > 0, "Slots::Bet must be greater than 0");
        accceptedBets[_bet] = _accept;
    }

    function leaveControl(bool _canLeave) external onlyOwner {
        canLeave = _canLeave;
    }

    function changeCommissionAddress(address _comissionsAddress)
        external
        onlyOwner
    {
        require(
            _comissionsAddress != address(0),
            "Slots::Address must be different than 0"
        );
        comissionsAddress = _comissionsAddress;
    }

    function changeMainRefAddress(address _mainRefAddress) external onlyOwner {
        require(
            _mainRefAddress != address(0),
            "Slots::Address must be different than 0"
        );
        mainRefAddress = _mainRefAddress;
    }

    function changeWeeklyLottery(address _weeklyLottery) external onlyOwner {
        require(
            _weeklyLottery != address(0),
            "Slots::Address must be different than 0"
        );
        weeklyLottery = _weeklyLottery;
    }

    function changeTenthUserCompensation(uint256 _amount) external onlyOwner {
        TENTH_USER_COMPENSATION = _amount;
    }

    function changeLeaveComission(uint256 _percent) external onlyOwner {
        require(
            _percent <= 10000,
            "Slots::Percent cannot be greater than 100% (10000)"
        );
        LEAVE_COMISSION = _percent;
    }

    function changeMonthLottery(address _month) external onlyOwner {
        require(_month != address(0), "Lottery:Slots address is zero");
        monthLottery = _month;
    }

    function changeRandomizer(address _randomizer) external onlyOwner {
        require(
            _randomizer != address(0),
            "Slots::Address must be different than 0"
        );
        randomizer = IRandomizer(_randomizer);
    }

    function changePassportsAddress(address _passportsAddress)
        external
        onlyOwner
    {
        require(
            _passportsAddress != address(0),
            "Slots::Address must be different than 0"
        );
        passportsAddress = _passportsAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function register(string memory name, address _referrer) external {
        require(msg.sender.code.length == 0, "Slots::Contract not allowed");
        require(tx.origin.code.length == 0, "Slots::Contract not allowed");
        require(!nicknamesUsed[name], "Slots::Nickname already used");
        require(_referrer != msg.sender, "Slots::Cannot refer yourself");
        require(
            userProfiles[msg.sender].isRegistered == false,
            "Slots::Already registered"
        );
        require(
            referrers[msg.sender] == address(0),
            "Slots::Already registered"
        );
        require(
            userProfiles[_referrer].isRegistered == true ||
                _referrer == address(0),
            "Slots::Referrer is not registered"
        );
        nicknamesToAddresses[name] = msg.sender;
        userProfiles[msg.sender].isRegistered = true;
        userProfiles[msg.sender].nickname = name;

        if (_referrer != address(0)) {
            referrers[msg.sender] = _referrer;
        } else {
            referrers[msg.sender] = mainRefAddress;
        }

        nicknamesUsed[name] = true;
        usersCounter++;

        require(IPassport(passportsAddress).mint(msg.sender), "Mint failed");

        emit UserRegistered(msg.sender, name, _referrer);
    }

    function comeIn(uint256 _bet) external payable whenNotPaused nonReentrant {
        require(userProfiles[msg.sender].isRegistered, "Slots::Not registered");
        require(accceptedBets[_bet], "Slots::Bet not accepted");
        require(msg.value == _bet, "Slots::Bet amount is not correct");
        uint8 freePlace = _findFreePlace(_bet);
        if (freePlace != 10 && freePlace != 0) {
            require(
                _reentryCheck(games[_bet].players),
                "Slots::Address already in game"
            );
        }
        if (freePlace == 10 || freePlace == 0) {
            _startAndComeIn(_bet);
            _updateUserStatus(msg.sender, _bet, true);
            emit UserCameIn(msg.sender, _bet, games[_bet].id);
        } else if (freePlace == 9) {
            emit UserCameIn(msg.sender, _bet, games[_bet].id);
            _endGame(_bet);
        } else {
            _comeIn(_bet, freePlace);
            _updateUserStatus(msg.sender, _bet, true);
            emit UserCameIn(msg.sender, _bet, games[_bet].id);
        }

        _updateUserStats(_bet);
        totalBet += _bet;
    }

    function leave(uint256 _bet) external nonReentrant {
        require(canLeave, "Slots::Cannot leave");
        require(accceptedBets[_bet], "Slots::Bet not accepted");
        require(
            !_reentryCheck(games[_bet].players),
            "Slots::Address not in game"
        );
        _leave(_bet);
        _updateUserStatus(msg.sender, _bet, false);

        emit UserLeave(msg.sender, _bet, games[_bet].id);
    }

    function getGame(uint256 _bet) external view returns (Game memory) {
        return games[_bet];
    }

    function getStatuses(address _user, uint256[] memory _bets)
        external
        view
        returns (uint256[] memory)
    {
        uint256 arrLength = _bets.length;
        uint256[] memory statuses = new uint256[](arrLength);
        for (uint256 i = 0; i < arrLength; i++) {
            statuses[i] = userStatuses[_user][_bets[i]];
        }
        return statuses;
    }

    function reentryCheck(uint256 _bet, address _address)
        external
        view
        returns (bool)
    {
        address[10] memory _players = games[_bet].players;
        uint256 arrLength = _players.length;
        for (uint8 i = 0; i < arrLength; ) {
            if (_players[i] == _address) {
                return false;
            }
            unchecked {
                i++;
            }
        }
        return true;
    }

    function getAmountOfPlayers(uint256 _bet)
        external
        view
        returns (uint256 amount)
    {
        address[10] memory _players = games[_bet].players;
        if (_players.length == 0) {
            return 0;
        }
        for (uint8 i = 0; i < 10; ) {
            if (_players[i] != address(0)) {
                amount++;
            }
            unchecked {
                i++;
            }
        }
    }

    function _startAndComeIn(uint256 _bet) internal {
        gamesCounter++;
        games[_bet].id = gamesCounter;
        games[_bet].timestamp = block.timestamp;
        games[_bet].players[0] = msg.sender;
    }

    function _comeIn(uint256 _bet, uint8 _place) internal {
        games[_bet].players[_place] = msg.sender;
    }

    function _endGame(uint256 _bet) internal {
        games[_bet].players[9] = msg.sender;
        _calculateResults(_bet);
        lastDrawBlock[_bet] = block.number;
        delete games[_bet].players;
    }

    function _updateUserStats(uint256 _bet) internal {
        userProfiles[msg.sender].gamesPlayed++;
        userProfiles[msg.sender].totalBet += _bet;
    }

    function _updateUserStatus(
        address _user,
        uint256 _bet,
        bool _isInGame
    ) internal {
        if (_isInGame) {
            userStatuses[_user][_bet] = games[_bet].id;
        } else {
            userStatuses[_user][_bet] = 0;
        }
    }

    function _calculateResults(uint256 _bet) internal {
        address[10] memory _players = _sortPlayers(_bet);
        calcFundsState = _bet * 10;
        _returnBets(_players, _bet);
        _payRewardsAndUpdateStats(_players, _bet);
        _payReferrers(_players, _bet);
        _payWeeklyLottery(_bet);
        _payCompensation();
        _payComission();
    }

    function _returnBets(address[10] memory _players, uint256 _bet) internal {
        for (uint8 i = 0; i < 7; ) {
            if (_players[i] != address(0)) {
                (bool result, ) = _players[i].call{value: _bet}("");
                require(result, "Bet return transfer failed");
                calcFundsState -= _bet;
            }
            unchecked {
                i++;
            }
        }
    }

    function _payRewardsAndUpdateStats(
        address[10] memory _players,
        uint256 _bet
    ) internal {
        uint256 reward = _bet / 7;
        address[7] memory winners;
        address[3] memory losers;
        for (uint256 i = 0; i < 7; ) {
            if (_players[i] != address(0)) {
                 (bool result, ) = _players[i].call{value: reward}("");
                require(result, "Pay reward transfer failed");
                winners[i] = _players[i];
                calcFundsState -= reward;
                userProfiles[_players[i]].gamesWon++;
                userProfiles[_players[i]].totalWon += reward;
                _monthLotteryCheck(_players[i]);
                _updateUserStatus(_players[i], _bet, false);
                emit UserWon(
                    _players[i],
                    _bet,
                    games[_bet].id,
                    reward,
                    lastDrawBlockForUser[_bet][_players[i]]
                );
                lastDrawBlockForUser[_bet][_players[i]] = block.number;
            }
            unchecked {
                i++;
            }
        }
        for (uint256 i = 7; i < 10; ) {
            if (_players[i] != address(0)) {
                require(
                    IWeeklyLottery(weeklyLottery).addParticipant(
                        _bet,
                        _players[i]
                    ),
                    "Weekly lottery add participant failed"
                );
                losers[i - 7] = _players[i];
                userProfiles[_players[i]].gamesLost++;
                userProfiles[_players[i]].totalLost += _bet;
                _monthLotteryCheck(_players[i]);
                _updateUserStatus(_players[i], _bet, false);
                emit UserLost(_players[i], _bet, games[_bet].id);
            }
            unchecked {
                i++;
            }
        }

        emit GameFinished(
            games[_bet].id,
            _bet,
            reward,
            lastDrawBlock[_bet],
            winners,
            losers
        );
    }

    function _payReferrers(address[10] memory _players, uint256 _bet) internal {
        uint256 referrersCount;
        uint256 arrLength = _players.length;
        for (uint256 i = 0; i < arrLength; ) {
            if (referrers[_players[i]] != address(0)) {
                referrersCount++;
            }
            unchecked {
                i++;
            }
        }
        if (referrersCount > 0) {
            uint256 reward = ((_bet * 7) / 10) / referrersCount;
            for (uint256 i = 0; i < arrLength; ) {
                if (referrers[_players[i]] != address(0)) {
                    (bool result, ) = referrers[_players[i]].call{
                        value: reward
                    }("");
                    require(result, "Pay referrer reward transfer failed");
                    emit RefPaid(
                        _players[i],
                        referrers[_players[i]],
                        reward,
                        lastRefBlockForUser[referrers[_players[i]]]
                    );
                    lastRefBlockForUser[referrers[_players[i]]] = block.number;
                    calcFundsState -= reward;
                    userProfiles[referrers[_players[i]]].totalRefEarn += reward;
                }
                unchecked {
                    i++;
                }
            }
        }
    }

    function _payWeeklyLottery(uint256 _bet) internal {
        uint256 weeklyLotterySum = _bet / 2;
       (bool result, ) = weeklyLottery.call{value: weeklyLotterySum}("");
        require(result, "Weekly lottery transfer failed");
        require(
            IWeeklyLottery(weeklyLottery).recordTransfer(
                _bet,
                weeklyLotterySum
            ),
            "Weekly lottery recording failed"
        );
        calcFundsState -= weeklyLotterySum;
    }

    function _payCompensation() internal {
        calcFundsState -= TENTH_USER_COMPENSATION;
        (bool result, ) = payable(msg.sender).call{
            value: TENTH_USER_COMPENSATION
        }("");
        require(result, "Pay tenth user compensation transfer failed");
    }

    function _payComission() internal {
        (bool result, ) = payable(comissionsAddress).call{
            value: calcFundsState
        }("");
        require(result, "Pay comission transfer failed");
    }

    function _monthLotteryCheck(address _user) internal {
        if (usersMonthlyCounter[_user] == 6) {
            usersMonthlyCounter[_user] = 1;
            require(
                IMonthlyLottery(monthLottery).addParticipant(_user),
                "Monthly lottery add participant failed"
            );
        } else if (usersMonthlyCounter[_user] == 0) {
            usersMonthlyCounter[_user] = 2;
        } else {
            usersMonthlyCounter[_user]++;
        }
    }

    function _leave(uint256 _bet) internal {
        address[10] memory addresses = games[_bet].players;
        for (uint8 i = 0; i < 10; i++) {
            if (addresses[i] == msg.sender) {
                addresses[i] = address(0);
                uint256 returnedBet = _bet - (_bet * LEAVE_COMISSION) / 10000;
                (bool result, ) = payable(msg.sender).call{value: returnedBet}(
                    ""
                );
                require(result, "Leave bet returns transfer failed");
                (bool result2, ) = payable(comissionsAddress).call{
                    value: _bet - returnedBet
                }("");
                require(result2, "Leave comission transfer failed");
                userProfiles[msg.sender].gamesPlayed--;
                userProfiles[msg.sender].totalBet -= _bet;
                break;
            }
        }
        uint256 zeroCount = 0;
        for (uint256 i = 0; i < 10; ) {
            if (addresses[i] == address(0)) {
                zeroCount++;
            }
            unchecked {
                i++;
            }
        }
        address[10] memory newAddresses;
        uint256 j = 0;
        for (uint256 i = 0; i < 10; ) {
            if (addresses[i] != address(0)) {
                newAddresses[j] = addresses[i];
                j++;
            }
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < zeroCount; ) {
            newAddresses[j] = address(0);
            j++;
            unchecked {
                i++;
            }
        }
        games[_bet].players = newAddresses;
    }

    function _findFreePlace(uint256 _bet) internal view returns (uint8) {
        if (games[_bet].players.length == 0) {
            return 0;
        }

        address[10] memory players = games[_bet].players;
        for (uint8 i = 0; i < 10; ) {
            if (players[i] == address(0)) {
                return i;
            }
            unchecked {
                i++;
            }
        }
        return 10;
    }

    function _reentryCheck(address[10] memory _players)
        internal
        view
        returns (bool)
    {
        uint256 arrLength = _players.length;
        for (uint8 i = 0; i < arrLength; ) {
            if (_players[i] == msg.sender) {
                return false;
            }
            unchecked {
                i++;
            }
        }
        return true;
    }

    function _sortPlayers(uint256 _bet)
        internal
        view
        returns (address[10] memory sortedPlayers)
    {
        address[10] memory players = games[_bet].players;
        for (uint256 i = 0; i < 10; ) {
            sortedPlayers[i] = players[i];
            unchecked {
                i++;
            }
        }

        uint256 id = games[_bet].id;
        uint256 arrLength = sortedPlayers.length;
        for (uint256 i = arrLength - 1; i > 0; ) {
            uint256 j = randomizer.random(id, i + 1, sortedPlayers[i]);
            (sortedPlayers[i], sortedPlayers[j]) = (
                sortedPlayers[j],
                sortedPlayers[i]
            );
            unchecked {
                i--;
            }
        }
    }
}