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

    // get active round
    function getActiveLotteryRound() public view returns (uint32) {
        return uint32((block.timestamp - firstRoundStartTime) / roundDuration);
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
        if (winners.length > winnersPerRound) {
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
        roundWinnersCount[roundId] = winners.length;

        emit RoundWinner(roundId, winners);
    }

    // claim reward

    event ClaimReward(
        uint32 _round,
        address _winner,
        address _to,
        address[] _rewardTokens,
        uint256[] _rewardAmounts
    );

    /// @notice claim reward
    /// @dev this function is called by the winner
    /// @param roundId round number
    /// @param to address to send the reward to
    function claimReward(uint32 roundId, address to) external {
        // check if user is in the list of winners
        for (uint8 i = 0; i < roundToWinners[roundId].length; i++) {
            if (roundToWinners[roundId][i] == msg.sender) {
                break;
            }
            if (i == roundToWinners[roundId].length - 1) {
                revert NotWinner();
            }
        }

        if (roundClaimed[roundId][msg.sender]) {
            revert AlreadyClaimed();
        }

        roundClaimed[roundId][msg.sender] = true;

        for (uint8 i = 0; i < rewardTokens.length; i++) {
            IERC20Upgradeable(rewardTokens[i]).safeTransfer(
                to,
                rewardAmounts[i]
            );
        }

        emit ClaimReward(roundId, msg.sender, to, rewardTokens, rewardAmounts);
    }

    // ** =========== SETTERS =========== **

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