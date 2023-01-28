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
    mapping(uint32 => address) public roundToWinner;
    mapping(uint32 => bool) public roundClaimed; // indicates whether the winner of the round claimed their reward

    address public rewardToken; // an erc20 token that winners can claim
    uint256 public rewardAmount; // amount of the erc20 token that winner can claim

    error LotteryRoundNotOver();
    error LotteryRoundAlreadyOver();
    error NotMuonInterface();
    error AlreadyClaimed();
    error NotWinner();
    error ZeroValue();

    // initializer
    function initialize(
        address _admin,
        address _setter,
        address _rewardToken,
        uint256 _rewardAmount
    ) public initializer {
        __AccessControl_init();
        __DibsLottery_init(_admin, _setter, _rewardToken, _rewardAmount);
    }

    function __DibsLottery_init(
        address _admin,
        address _setter,
        address _rewardToken,
        uint256 _rewardAmount
    ) internal {
        // check none of the addresses are zero
        if (
            _rewardToken == address(0) ||
            _admin == address(0) ||
            _setter == address(0)
        ) {
            revert ZeroValue();
        }

        rewardToken = _rewardToken;
        rewardAmount = _rewardAmount;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SETTER, _setter);

        firstRoundStartTime = 1673481600; // GMT: Thursday, January 12, 2023 12:00:00 AM
        roundDuration = 1 weeks;
    }

    // get active round
    function getActiveLotteryRound() public view returns (uint32) {
        return uint32((block.timestamp - firstRoundStartTime) / roundDuration);
    }

    event RoundWinner(uint32 _round, address _winner);

    /// @notice set the winner of a lottery round
    /// @dev this function is called by the muon interface
    /// @param roundId round number
    /// @param winner address of the winner
    function setRoundWinner(uint32 roundId, address winner)
        external
        onlyMuonInterface
    {
        if (
            block.timestamp <
            firstRoundStartTime + (roundId + 1) * roundDuration
        ) {
            revert LotteryRoundNotOver();
        }

        if (roundToWinner[roundId] != address(0)) {
            revert LotteryRoundAlreadyOver();
        }

        roundToWinner[roundId] = winner;

        emit RoundWinner(roundId, winner);
    }

    // claim reward

    event ClaimReward(
        uint32 _round,
        address _winner,
        address _to,
        address _rewardToken,
        uint256 _rewardAmount
    );

    /// @notice claim reward
    /// @dev this function is called by the winner
    /// @param roundId round number
    /// @param to address to send the reward to
    function claimReward(uint32 roundId, address to) external {
        if (roundToWinner[roundId] != msg.sender) {
            revert NotWinner();
        }

        if (roundClaimed[roundId]) {
            revert AlreadyClaimed();
        }

        roundClaimed[roundId] = true;

        IERC20Upgradeable(rewardToken).safeTransfer(to, rewardAmount);

        emit ClaimReward(roundId, msg.sender, to, rewardToken, rewardAmount);
    }

    // ** =========== SETTERS =========== **

    // set round duration
    event SetRoundDuration(uint32 _old, uint32 _new);

    function setRoundDuration(uint32 _roundDuration) external onlyRole(SETTER) {
        emit SetRoundDuration(roundDuration, _roundDuration);
        roundDuration = _roundDuration;
    }

    // set first round start time
    event SetFirstRoundStartTime(uint32 _old, uint32 _new);

    function setFirstRoundStartTime(uint32 _firstRoundStartTime)
        external
        onlyRole(SETTER)
    {
        emit SetFirstRoundStartTime(firstRoundStartTime, _firstRoundStartTime);
        firstRoundStartTime = _firstRoundStartTime;
    }

    // set reward token
    event SetRewardToken(address _old, address _new);

    function setRewardToken(address _rewardToken) external onlyRole(SETTER) {
        emit SetRewardToken(rewardToken, _rewardToken);
        rewardToken = _rewardToken;
    }

    // set reward amount
    event SetRewardAmount(uint256 _old, uint256 _new);

    function setRewardAmount(uint256 _rewardAmount) external onlyRole(SETTER) {
        emit SetRewardAmount(rewardAmount, _rewardAmount);
        rewardAmount = _rewardAmount;
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

    // ** =========== MODIFIERS =========== **

    modifier onlyMuonInterface() {
        if (msg.sender != muonInterface) revert NotMuonInterface();
        _;
    }
}