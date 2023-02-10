// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract DibsLottery is AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant SETTER = keccak256("SETTER");

    address muonInterface; // this address can set the winner

    uint32 public firstRoundStartTime;
    uint32 public roundDuration;

    uint8 public winnersPerRound; // number of winner per round

    mapping(uint32 => address[]) public roundToWinners;
    mapping(uint32 => uint256) public roundWinnersCount;

    mapping(uint32 => mapping(address => bool)) public roundClaimed; // indicates whether the winner of the round claimed their reward

    address[] public rewardTokens; // an erc20 token that winners can claim
    uint256[] public rewardAmounts; // amount of the erc20 token that winner can claim

    mapping(address => mapping(address => uint256)) public balanceOf; // (user => (token => balance))
    mapping(address => address[]) public userTokens; // tokens that the user has been rewarded (user => tokens)
    mapping(address => mapping(address => bool)) public hasToken; // (user => (token => bool))

    error LotteryRoundNotOver();
    error LotteryRoundAlreadyOver();
    error NotMuonInterface();
    error TooManyWinners();
    error AlreadyClaimed();
    error NotWinner();
    error ZeroValue();

    // initializer
    function initialize(
        uint32 _firstRoundStartTime,
        uint32 _roundDuration,
        uint8 _winnersPerRound,
        address _admin,
        address _setter
    ) public initializer {
        __AccessControl_init();
        __DibsLottery_init(
            _firstRoundStartTime,
            _roundDuration,
            _winnersPerRound,
            _admin,
            _setter
        );
    }

    function __DibsLottery_init(
        uint32 _firstRoundStartTime,
        uint32 _roundDuration,
        uint8 _winnersPerRound,
        address _admin,
        address _setter
    ) internal onlyInitializing {
        // check none of the addresses are zero
        if (_admin == address(0) || _setter == address(0)) {
            revert ZeroValue();
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SETTER, _setter);

        firstRoundStartTime = _firstRoundStartTime;
        roundDuration = _roundDuration;
        winnersPerRound = _winnersPerRound;
    }

    /// @notice get the current round number
    /// @return current round number
    function getActiveLotteryRound() public view returns (uint32) {
        return uint32((block.timestamp - firstRoundStartTime) / roundDuration);
    }

    /// @notice get the array of winners of the given round
    /// @param roundId round number
    /// @return array of winners
    function getRoundWinners(uint32 roundId)
        public
        view
        returns (address[] memory)
    {
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
    function getUserTokensAndBalance(address user)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory tokens = userTokens[user];
        uint256[] memory balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = balanceOf[user][tokens[i]];
        }

        return (tokens, balances);
    }

    event RoundWinner(uint32 _round, address[] _winners);

    /// @notice set the winner of a lottery round
    /// @dev this function is called by the muon interface
    /// @param roundId round number
    /// @param winners address of the winner
    function setRoundWinners(uint32 roundId, address[] memory winners)
        external
        onlyMuonInterface
    {
        uint256 winnersCount = winners.length;

        if (winnersCount > winnersPerRound) {
            revert TooManyWinners();
        }

        if (
            block.timestamp <
            firstRoundStartTime + (roundId + 1) * roundDuration
        ) {
            revert LotteryRoundNotOver();
        }

        if (roundToWinners[roundId].length != 0) {
            revert LotteryRoundAlreadyOver();
        }

        roundToWinners[roundId] = winners;
        roundWinnersCount[roundId] = winnersCount;

        // deposit rewards to winners
        for (uint8 i = 0; i < winnersCount; i++) {
            for (uint8 j = 0; j < rewardTokens.length; j++) {
                address _winner = winners[i];
                address _token = rewardTokens[j];

                balanceOf[_winner][_token] += rewardAmounts[j];

                if (!hasToken[_winner][_token]) {
                    userTokens[_winner].push(_token);
                    hasToken[_winner][_token] = true;
                }
            }
        }

        emit RoundWinner(roundId, winners);
    }

    // claim reward

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
                balanceOf[msg.sender][_tokens[i]] = 0;
                IERC20Upgradeable(_tokens[i]).safeTransfer(to, _amount);
            }
        }

        emit ClaimReward(msg.sender, to, _tokens, _amounts);
    }

    // ** =========== SETTERS =========== **

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

    // set reward token
    event SetRewardToken(address[] _old, address[] _new);

    function setRewardTokens(address[] memory _rewardToken)
        external
        onlyRole(SETTER)
    {
        emit SetRewardToken(rewardTokens, _rewardToken);
        rewardTokens = _rewardToken;
    }

    // set reward amount
    event SetRewardAmount(uint256[] _old, uint256[] _new);

    function setRewardAmount(uint256[] memory _rewardAmount)
        external
        onlyRole(SETTER)
    {
        emit SetRewardAmount(rewardAmounts, _rewardAmount);
        rewardAmounts = _rewardAmount;
    }

    // set muon interface
    event SetMuonInterface(address _old, address _new);

    function setMuonInterface(address _muonInterface)
        external
        onlyRole(SETTER)
    {
        emit SetMuonInterface(muonInterface, _muonInterface);
        muonInterface = _muonInterface;
    }

    // set winners per round
    event SetWinnersPerRound(uint8 _old, uint8 _new);

    function setWinnersPerRound(uint8 _winnersPerRound)
        external
        onlyRole(SETTER)
    {
        emit SetWinnersPerRound(winnersPerRound, _winnersPerRound);
        winnersPerRound = _winnersPerRound;
    }

    // ** =========== MODIFIERS =========== **

    modifier onlyMuonInterface() {
        if (msg.sender != muonInterface) revert NotMuonInterface();
        _;
    }
}