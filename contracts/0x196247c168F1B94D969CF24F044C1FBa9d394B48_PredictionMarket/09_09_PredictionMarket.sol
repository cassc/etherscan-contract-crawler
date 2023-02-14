// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Prediction Market Contract with ERC20 bets and allows for concurrent
 */
contract PredictionMarket is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token; // Prediction token

    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator

    uint256 public minBetAmount; // minimum betting amount (denominated in wei)
    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed

    uint256 public currentRound; // current epoch for prediction round

    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%

    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public userRounds;

    enum Position {
        Bull,
        Bear
    }

    enum Outcome {
        Up,
        Down,
        Draw
    }

    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool roundClosed;
        Outcome outcome;
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    event StartRound(uint256 indexed round);
    event EndRound(uint256 indexed round, Outcome outcome);
    event BetBear(
        address indexed sender,
        uint256 indexed round,
        uint256 amount
    );
    event BetBull(
        address indexed sender,
        uint256 indexed round,
        uint256 amount
    );
    event Claim(address indexed sender, uint256 indexed round, uint256 amount);

    event NewAdminAddress(address admin);
    event NewMinBetAmount(uint256 indexed round, uint256 minBetAmount);
    event NewTreasuryFee(uint256 indexed round, uint256 treasuryFee);
    event NewOperatorAddress(address operator);

    event RewardsCalculated(
        uint256 indexed round,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );

    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Pause(uint256 indexed round);
    event Unpause(uint256 indexed round);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(
            msg.sender == adminAddress || msg.sender == operatorAddress,
            "Not operator/admin"
        );
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor
     * @param _token: prediction token
     * @param _adminAddress: admin address
     * @param _operatorAddress: operator address
     * @param _minBetAmount: minimum bet amounts (in wei)
     * @param _treasuryFee: treasury fee (1000 = 10%)
     */
    constructor(
        IERC20 _token,
        address _adminAddress,
        address _operatorAddress,
        uint256 _minBetAmount,
        uint256 _treasuryFee
    ) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");

        token = _token;
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        minBetAmount = _minBetAmount;
        treasuryFee = _treasuryFee;
    }

    /**
     * @notice Bet bear position
     * @param epoch: epoch
     */
    function betBear(
        uint256 epoch,
        uint256 _amount
    ) external whenNotPaused nonReentrant notContract {
        //todo update bettable to check that epoch exists and that current timestamp is less than lock timestamp
        require(_bettable(epoch), "Round not bettable");
        require(
            _amount >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[epoch][msg.sender].amount == 0,
            "Can only bet once per round"
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
        // Update round data
        uint256 amount = _amount;
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + amount;
        round.bearAmount = round.bearAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        userRounds[msg.sender].push(epoch);

        emit BetBear(msg.sender, epoch, amount);
    }

    /**
     * @notice Bet bull position
     * @param epoch: epoch
     */
    function betBull(
        uint256 epoch,
        uint256 _amount
    ) external whenNotPaused nonReentrant notContract {
        //todo update bettable to check that epoch exists and that current timestamp is less than lock timestamp,
        require(_bettable(epoch), "Round not bettable");
        require(
            _amount >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[epoch][msg.sender].amount == 0,
            "Can only bet once per round"
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
        // Update round data
        uint256 amount = _amount;
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + amount;
        round.bullAmount = round.bullAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        userRounds[msg.sender].push(epoch);

        emit BetBull(msg.sender, epoch, amount);
    }

    /**
     * @notice Claim reward for an array of epochs
     * @param epochs: array of epochs
     */
    function claim(
        uint256[] calldata epochs
    ) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(
                rounds[epochs[i]].startTimestamp != 0,
                "Round has not started"
            );
            require(
                block.timestamp > rounds[epochs[i]].closeTimestamp,
                "Round has not ended"
            );

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (rounds[epochs[i]].roundClosed) {
                require(
                    claimable(epochs[i], msg.sender),
                    "Not eligible for claim"
                );
                Round memory round = rounds[epochs[i]];
                addedReward =
                    (ledger[epochs[i]][msg.sender].amount *
                        round.rewardAmount) /
                    round.rewardBaseCalAmount;
            }

            ledger[epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }

        if (reward > 0) {
            token.safeTransfer(msg.sender, reward);
        }
    }

    /**
     * @notice Closes round with epoch
     * @param _epochToEnd: the round that is being closed
     * @param _outcome: result of the round
     * @dev Callable by operator
     */
    function closeRound(
        uint256 _epochToEnd,
        Outcome _outcome
    ) external whenNotPaused onlyOperator {
        require(_epochToEnd <= currentRound, "Round does not exist");
        require(
            !rounds[_epochToEnd].roundClosed,
            "Round has already been closed"
        );
        //todo take input for which side won here and send to _safeLockRound or more likely _safeEndRound, since we only have start and finish calls per epoch
        _safeEndRound(_epochToEnd, _outcome);
        _calculateRewards(_epochToEnd);
    }

    /**
     * @notice Start genesis round
     * @dev Callable by admin or operator
     */
    function startNewRound(
        uint256 _lockTimestamp,
        uint256 _closeTimestamp
    ) external whenNotPaused onlyOperator {
        //todo review/remove genesis start booleans
        require(
            _lockTimestamp > block.timestamp,
            "lockTimestamp must be greater than current timestamp"
        );
        require(
            _lockTimestamp < _closeTimestamp,
            "lock timestamp must be less than close timestamp"
        );

        currentRound = currentRound + 1;
        Round storage round = rounds[currentRound];
        round.startTimestamp = block.timestamp;
        round.lockTimestamp = _lockTimestamp;
        round.closeTimestamp = _closeTimestamp;
        round.epoch = currentRound;
        round.totalAmount = 0;

        emit StartRound(currentRound);
    }

    /**
    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyAdminOrOperator {
        _pause();

        emit Pause(currentRound);
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        token.safeTransfer(adminAddress, currentTreasuryAmount);
        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     * @dev Callable by admin or operator
     */
    function unpause() external whenPaused onlyAdminOrOperator {
        _unpause();

        emit Unpause(currentRound);
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     */
    function setMinBetAmount(
        uint256 _minBetAmount
    ) external whenPaused onlyAdmin {
        require(_minBetAmount != 0, "Must be superior to 0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(currentRound, minBetAmount);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(
        uint256 _treasuryFee
    ) external whenPaused onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentRound, treasuryFee);
    }

    /**
     * @notice It allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _amount: token amount
     * @dev Callable by owner
     */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(token), "Cannot be prediction token address");
        IERC20(_token).safeTransfer(address(msg.sender), _amount);

        emit TokenRecovery(_token, _amount);
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    /**
     * @notice Returns round epochs and bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, BetInfo[] memory, uint256) {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            betInfo[i] = ledger[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRounds[user].length;
    }

    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function claimable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        if (round.outcome == Outcome.Draw) {
            return false;
        }
        return
            round.roundClosed &&
            betInfo.amount != 0 &&
            !betInfo.claimed &&
            ((round.outcome == Outcome.Up &&
                betInfo.position == Position.Bull) ||
                (round.outcome == Outcome.Down &&
                    betInfo.position == Position.Bear));
    }

    /**
     * @notice Calculate rewards for round
     * @param epoch: epoch
     */
    function _calculateRewards(uint256 epoch) internal {
        require(
            rounds[epoch].rewardBaseCalAmount == 0 &&
                rounds[epoch].rewardAmount == 0,
            "Rewards calculated"
        );
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        // Bull wins
        //todo adjust these to be values from the outcomes enum
        if (round.outcome == Outcome.Up) {
            rewardBaseCalAmount = round.bullAmount;
            treasuryAmt = (round.totalAmount * treasuryFee) / 10000;
            rewardAmount = round.totalAmount - treasuryAmt;
        }
        // Bear wins
        else if (round.outcome == Outcome.Down) {
            rewardBaseCalAmount = round.bearAmount;
            treasuryAmt = (round.totalAmount * treasuryFee) / 10000;
            rewardAmount = round.totalAmount - treasuryAmt;
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = round.totalAmount;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        // Add to treasury
        treasuryAmount += treasuryAmt;

        emit RewardsCalculated(
            epoch,
            rewardBaseCalAmount,
            rewardAmount,
            treasuryAmt
        );
    }

    /**
     * @notice End round
     * @param epoch: epoch
     * @param _outcome: winning side of the round
     */
    function _safeEndRound(uint256 epoch, Outcome _outcome) internal {
        require(
            block.timestamp >= rounds[epoch].closeTimestamp,
            "Can only end round after closeTimestamp"
        );
        Round storage round = rounds[epoch];
        round.outcome = _outcome;
        round.roundClosed = true;

        emit EndRound(epoch, round.outcome);
    }

    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and not be locked
     * Current timestamp must be within startTimestamp and closeTimestamp
     */
    function _bettable(uint256 epoch) internal view returns (bool) {
        return
            rounds[epoch].startTimestamp != 0 &&
            rounds[epoch].lockTimestamp != 0 &&
            block.timestamp > rounds[epoch].startTimestamp &&
            block.timestamp < rounds[epoch].lockTimestamp;
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}