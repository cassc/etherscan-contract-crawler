// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IDibs.sol";

import "hardhat/console.sol";

struct LeaderBoard {
    uint32 lastUpdatedDay; // day from start of the round that the leaderBoard data was last updated
    uint8 count; // number of users in the leaderBoard
    address[] rewardTokens;
    uint256[][] rankRewardAmount; // (tokenPosition => (rank => reward amount))
}

contract DibsLottery is AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant SETTER = keccak256("SETTER");

    address dibs; // dibs contract

    uint8 public winnersPerRound; // number of winner per round

    mapping(uint32 => address[]) public roundToWinners;
    mapping(uint32 => uint256) public roundWinnersCount;

    mapping(uint32 => mapping(address => bool)) public roundClaimed; // indicates whether the winner of the round claimed their reward

    address[] public rewardTokens; // an erc20 token that winners can claim
    uint256[] public rewardAmounts; // amount of the erc20 token that winner can claim

    mapping(address => mapping(address => uint256)) public balanceOf; // (user => (token => balance))
    mapping(address => address[]) public userTokens; // tokens that the user has been rewarded (user => tokens)
    mapping(address => mapping(address => bool)) public hasToken; // (user => (token => bool))

    LeaderBoard[] public leaderBoards;
    mapping(uint32 => address[]) public topReferrers; // top referrers of the day
    mapping(address => uint32[]) public winningDays; // days that the user has been in the referrer ranking

    uint32 public lastRefDay;

    error LotteryRoundNotOver();
    error LotteryRoundAlreadyOver();
    error NotMuonInterface();
    error TooManyWinners();
    error AlreadyClaimed();
    error NotWinner();
    error ZeroValue();
    error NoLeaderBoardData();
    error DayNotOver();
    error TopReferrersAlreadySet();
    error DayMustBeGreaterThanLastUpdatedDay();
    error InvalidInput();

    // initializer
    function initialize(address _admin, address _setter) public initializer {
        __AccessControl_init();
        __DibsLottery_init(_admin, _setter);
    }

    function __DibsLottery_init(
        address _admin,
        address _setter
    ) internal onlyInitializing {
        // check none of the addresses are zero
        if (_admin == address(0) || _setter == address(0)) {
            revert ZeroValue();
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SETTER, _setter);
    }

    /// @notice get the current round number
    /// @return current round number
    function getActiveLotteryRound() public view returns (uint32) {
        return
            uint32(
                (block.timestamp - IDibs(dibs).firstRoundStartTime()) /
                    IDibs(dibs).roundDuration()
            );
    }

    /// @notice get active day
    /// @return active day
    function getActiveDay() public view returns (uint32) {
        return
            uint32(
                (block.timestamp - IDibs(dibs).firstRoundStartTime()) / 1 days
            );
    }

    /// @notice get the array of winners of the given round
    /// @param roundId round number
    /// @return array of winners
    function getRoundWinners(
        uint32 roundId
    ) public view returns (address[] memory) {
        return roundToWinners[roundId];
    }

    /// @notice get the reward tokens and amounts
    /// @return reward tokens and amounts
    function getRewardTokensAndAmounts()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (rewardTokens, rewardAmounts);
    }

    /// @notice get the number of reward tokens
    /// @return number of reward tokens
    function getRewardTokensCount() public view returns (uint256) {
        return rewardTokens.length;
    }

    /// @notice get list of tokens that user has been rewarded with and the balance of each token
    /// @param user address of the user
    /// @return list of tokens and the balance of each token
    function getUserTokensAndBalance(
        address user
    ) public view returns (address[] memory, uint256[] memory) {
        address[] memory tokens = userTokens[user];
        uint256[] memory balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = balanceOf[user][tokens[i]];
        }

        return (tokens, balances);
    }

    /// @notice gets the length of the leaderBoards array,
    /// which includes all leaderBoard reward data
    /// @return length of the leaderBoards array
    function getLeaderBoardsLength() public view returns (uint256) {
        return leaderBoards.length;
    }

    /// @notice gets the latest leaderBoard data
    /// @return latest leaderBoard data
    function getLatestLeaderBoard() public view returns (LeaderBoard memory) {
        return leaderBoards[leaderBoards.length - 1];
    }

    /// @notice gets the list of top referrers of the given day
    /// @param day day number, from firstRoundStartTime
    /// @return list of top referrers
    function getTopReferrers(
        uint32 day
    ) public view returns (address[] memory) {
        return topReferrers[day];
    }

    /// @notice gets the number of days that the user has been in the referrer ranking
    /// @param user address of the user
    /// @return number of days that the user has been in the referrer ranking
    function getWinningDaysCount(address user) public view returns (uint256) {
        return winningDays[user].length;
    }

    /// @notice gets the days that the user has been in the referrer ranking (list is not sorted)
    /// @param user address of the user
    /// @return days that the user has been in the referrer ranking
    function getWinningDays(
        address user
    ) public view returns (uint32[] memory) {
        return winningDays[user];
    }

    event RoundWinner(uint32 _round, address[] _winners);

    /// @notice set the winner of a lottery round
    /// @dev this function is called by the muon interface
    /// @param roundId round number
    /// @param winners address of the winner
    function setRoundWinners(
        uint32 roundId,
        address[] memory winners
    ) external onlyMuonInterface {
        uint256 winnersCount = winners.length;

        if (winnersCount > winnersPerRound) {
            revert TooManyWinners();
        }

        if (getActiveLotteryRound() <= roundId) {
            revert LotteryRoundNotOver();
        }

        if (roundToWinners[roundId].length != 0) {
            revert LotteryRoundAlreadyOver();
        }

        roundToWinners[roundId] = winners;
        roundWinnersCount[roundId] = winnersCount;

        // _deposit rewards to winners
        for (uint8 i = 0; i < winnersCount; i++) {
            for (uint8 j = 0; j < rewardTokens.length; j++) {
                address _winner = winners[i];
                address _token = rewardTokens[j];
                _deposit(_winner, _token, rewardAmounts[j]);
            }
        }

        emit RoundWinner(roundId, winners);
    }

    /// @notice set the top referrers of a day
    /// @dev this function is called by the muon interface
    /// @param _day day number, from firstRoundStartTime
    /// @param _referrers list of top referrers
    function setTopReferrers(
        uint32 _day,
        address[] memory _referrers
    ) external onlyMuonInterface {
        if (_day >= getActiveDay()) revert DayNotOver();
        if (topReferrers[_day].length != 0) revert TopReferrersAlreadySet();

        lastRefDay = _day;

        // find the index of the LeaderBoard data that was active at the given day
        uint256 _leaderBoardIndex = findLeaderBoardIndex(_day);

        // get the LeaderBoard data
        LeaderBoard memory _leaderBoard = leaderBoards[_leaderBoardIndex];

        uint256 _referrersCount = _referrers.length;

        if (_referrersCount > _leaderBoard.count) {
            revert TooManyWinners();
        }

        topReferrers[_day] = _referrers;

        // _deposit rewards to referrers
        // i is the rank of the referrer
        // j is the index of the reward token
        for (uint8 i = 0; i < _referrersCount; i++) {
            for (uint8 j = 0; j < _leaderBoard.rewardTokens.length; j++) {
                address _referrer = _referrers[i];
                address _token = _leaderBoard.rewardTokens[j];
                uint256 _rewardAmount = _leaderBoard.rankRewardAmount[j][i];
                _deposit(_referrer, _token, _rewardAmount);
            }
        }

        // add the day to the winningDays array for each user
        for (uint8 i = 0; i < _referrersCount; i++) {
            winningDays[_referrers[i]].push(_day);
        }
    }

    /// @notice gets the index of the LeaderBoard data that was active at the given day
    /// @param _day day number, from firstRoundStartTime
    /// @return index of the LeaderBoard data: todo: return the LeaderBoard object
    function findLeaderBoardIndex(uint32 _day) public view returns (uint256) {
        uint256 _leaderBoardsCount = leaderBoards.length;

        if (_leaderBoardsCount == 0) {
            revert NoLeaderBoardData();
        }

        uint256 _start = 0;
        uint256 _end = _leaderBoardsCount - 1;

        while (_start <= _end) {
            uint256 _mid = _start + (_end - _start) / 2;

            if (
                _mid == _leaderBoardsCount - 1 &&
                leaderBoards[_mid].lastUpdatedDay <= _day
            ) {
                // if _mid is the last index and
                // the lastUpdatedDay is less than or equal to the given day
                return _mid;
            } else if (
                leaderBoards[_mid].lastUpdatedDay <= _day &&
                leaderBoards[_mid + 1].lastUpdatedDay > _day
            ) {
                // if the lastUpdatedDay is less than or equal to the given day and
                // the next lastUpdatedDay is greater than the given day
                return _mid;
            } else if (leaderBoards[_mid].lastUpdatedDay > _day) {
                if (_mid == 0) {
                    revert NoLeaderBoardData();
                }
                _end = _mid - 1;
            } else {
                _start = _mid + 1;
            }
        }

        revert NoLeaderBoardData();
    }

    event ClaimReward(
        address _winner,
        address _to,
        address[] _rewardTokens,
        uint256[] _rewardAmounts
    );

    /// @notice claim reward
    /// @dev this function is called by the winner
    /// @param to address to send the reward to
    function claimReward(address to) external {
        (
            address[] memory _tokens,
            uint256[] memory _amounts
        ) = getUserTokensAndBalance(msg.sender);

        for (uint8 i = 0; i < _tokens.length; i++) {
            uint256 _amount = _amounts[i];
            if (_amount != 0) {
                _withdraw(msg.sender, _tokens[i], _amount, to);
            }
        }

        emit ClaimReward(msg.sender, to, _tokens, _amounts);
    }

    // ** =========== SETTERS =========== **

    /// @notice batch set balance of users [( user, token, balance )]
    /// @dev this function is called by the setter
    /// @param users list of users
    /// @param token list of tokens with respect to list of users
    /// @param amount list of amounts with respect to list of tokens
    function setBalanceOf(
        address[] memory users,
        address[] memory token,
        uint256[] memory amount
    ) external onlyRole(SETTER) {
        for (uint8 i = 0; i < users.length; i++) {
            address _user = users[i];
            address _token = token[i];
            balanceOf[_user][_token] = amount[i];
            if (!hasToken[_user][_token]) {
                userTokens[_user].push(_token);
                hasToken[_user][_token] = true;
            }
        }
    }

    event SetLotteryRewards(address[] _rewardTokens, uint256[] _rewardAmounts);

    /// @notice set reward tokens and amounts for lottery winners
    /// @dev this function is called by the setter
    /// @param _rewardTokens list of reward tokens
    /// @param _rewardAmounts list of reward amounts with respect to reward tokens
    function setLotteryRewards(
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts
    ) external onlyRole(SETTER) {
        if (_rewardTokens.length != _rewardAmounts.length)
            revert InvalidInput();

        emit SetLotteryRewards(_rewardTokens, _rewardAmounts);
        rewardTokens = _rewardTokens;
        rewardAmounts = _rewardAmounts;
    }

    event SetRewardToken(address[] _old, address[] _new);

    /// @notice set reward tokens for lottery winners
    /// @dev this function is called by the setter
    /// @param _rewardTokens list of reward tokens
    function setRewardTokens(
        address[] memory _rewardTokens
    ) external onlyRole(SETTER) {
        if (_rewardTokens.length != rewardAmounts.length) revert InvalidInput();

        emit SetRewardToken(rewardTokens, _rewardTokens);
        rewardTokens = _rewardTokens;
    }

    event SetRewardAmount(uint256[] _old, uint256[] _new);

    /// @notice set reward amounts with respect to reward tokens for lottery winners
    /// @dev this function is called by the setter
    /// @param _rewardAmounts list of reward amounts
    function setRewardAmount(
        uint256[] memory _rewardAmounts
    ) external onlyRole(SETTER) {
        if (_rewardAmounts.length != rewardTokens.length) revert InvalidInput();

        emit SetRewardAmount(rewardAmounts, _rewardAmounts);
        rewardAmounts = _rewardAmounts;
    }

    event SetWinnersPerRound(uint8 _old, uint8 _new);

    /// @notice set number of winners per round
    /// @dev this function is called by the setter
    /// @param _winnersPerRound number of winners per round
    function setWinnersPerRound(
        uint8 _winnersPerRound
    ) external onlyRole(SETTER) {
        emit SetWinnersPerRound(winnersPerRound, _winnersPerRound);
        winnersPerRound = _winnersPerRound;
    }

    event UpdateLeaderBoardData(
        uint8 _day,
        uint8 _count,
        address[] _rewardTokens,
        uint256[][] _rankReward
    );

    /// @notice update leader board data
    /// @dev this function is called by the setter
    /// @param _day day number, from firstRoundStartTime
    /// @param _count number of users to be shown in the leader board
    /// @param _rewardTokens list of reward tokens
    /// @param _rankReward list of reward amounts with respect to reward tokens
    function updateLeaderBoardData(
        uint8 _day,
        uint8 _count,
        address[] memory _rewardTokens,
        uint256[][] memory _rankReward
    ) external onlyRole(SETTER) {
        if (leaderBoards.length > 0) {
            if (
                _day <= leaderBoards[leaderBoards.length - 1].lastUpdatedDay ||
                _day <= lastRefDay
            ) revert DayMustBeGreaterThanLastUpdatedDay();
        }
        leaderBoards.push(
            LeaderBoard({
                lastUpdatedDay: _day,
                count: _count,
                rewardTokens: _rewardTokens,
                rankRewardAmount: _rankReward
            })
        );

        emit UpdateLeaderBoardData(_day, _count, _rewardTokens, _rankReward);
    }

    event SetDibs(address _old, address _new);

    /// @notice sets the dibs
    /// @param dibs_ address of dibs contract
    function setDibs(address dibs_) external onlyRole(SETTER) {
        emit SetDibs(dibs, dibs_);
        dibs = dibs_;
    }

    event RecoverERC20(address _token, address _to, uint256 _amount);

    /// @notice recover erc20 tokens
    /// @param token erc20 token address
    /// @param to recipient address
    /// @param amount amount to be recovered
    function recoverERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(token).safeTransfer(to, amount);
        emit RecoverERC20(token, to, amount);
    }

    // ** =========== INTERNAL FUNCTIONS =========== **

    function _deposit(address _user, address _token, uint256 _amount) internal {
        balanceOf[_user][_token] += _amount;

        if (!hasToken[_user][_token]) {
            userTokens[_user].push(_token);
            hasToken[_user][_token] = true;
        }
    }

    function _withdraw(
        address _user,
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        balanceOf[_user][_token] -= _amount;
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    // ** =========== MODIFIERS =========== **

    modifier onlyMuonInterface() {
        if (msg.sender != IDibs(dibs).muonInterface())
            revert NotMuonInterface();
        _;
    }
}