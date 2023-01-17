// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./SafeMathX.sol";

contract BullOrBearV2 is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathX for uint256;
    using SafeMathUpgradeable for uint256;

    /// STATE
    AggregatorV3Interface public oracle;

    uint256 public betSeconds; // Time of bet phase
    uint256 public lockSeconds; // Time of lock phase
    uint256 public bufferSeconds; // Time of buffer

    address public operator; // Address of operator
    address public admin; // Address of admin

    uint256 public treasuryFee; // Fee service in basis points. 5% -> 500/10_000
    uint256 public treasuryAmount; // treasury amount that was not claimed

    uint256 public currentEpoch; // Current round

    bool public genesisStartOnce;

    uint256 public oracleLatestRoundId;

    /**
    One invariant we need to ensure is that the latest epoch must use the latest price of the oracle to guarantee fairness for players. 
    If the epoch timestamp and the price timestamp from the oracle mismatch, 
        this means either the round is in the past but it tries to get the current price, 
        or the price from oracle cannot keep up with current epoch timestamp which is invalid. 
    To decide if they are mismatched, we use oracleUpdateAllowance to form a timestamp range and compare using the range instead of comparing two exact timestamps.
    */
    uint256 public oracleUpdateAllowance;

    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(uint256 => RoundInfo) public rounds;
    mapping(address => uint256[]) public userRounds;
    uint256 public ticketPrice;
    uint256 public maxTicketAmount;

    /// CONSTANTs
    uint256 public constant MAX_TREASURY_FEE = 10_000;

    uint256 public initTicketAmount;

    uint256 public autoBetTicketAmount; // Lượng ticket được contract auto bet

    enum Position {
        Bull,
        Bear
    }

    struct RoundInfo {
        uint256 epoch;
        uint256 startTimestamp; // Timestamp round bắt đầu
        uint256 lockTimestamp; // Timestamp round bị lock, users không thể sửa đổi position
        uint256 closeTimestamp; // Timestamp round kết thúc
        int256 lockPrice;
        int256 closePrice;
        uint256 lockOracleId; // Oracle Round Id của lock price
        uint256 closeOracleId; // Oracle Round Id của close price
        uint256 ticketPrice; // Giá của 1 ticket trong round
        uint256 bullCounter; // Tổng bet ticket của bên bull
        uint256 bearCounter; // Tổng bet ticket của bên bear
        uint256 rewardBaseCalAmount; // Reward gốc (chưa tính fee dịch vụ) cho bên thắng
        uint256 rewardAmount; // Reward (đã trừ fee dịch vụ) cho bên thắng
        bool oracleCalled; // Flag để xác định round này có corrupted hay không
    }

    struct BetInfo {
        uint256 bullCounter;
        uint256 bearCounter;
        uint256 ticketPrice;
        bool claimed; // Đã claim
    }

    // Used to avoid "stack too deep" error
    struct PhaseTimeConfig {
        uint256 betSeconds;
        uint256 lockSeconds;
        uint256 bufferSeconds;
    }

    event BetBear(
        address indexed sender,
        uint256 indexed epoch,
        uint256 ticketPrice,
        uint256 totalBetTicket,
        uint256 totalBearTicket,
        uint256 totalBullTicket,
        uint256 tickets
    );
    event BetBull(
        address indexed sender,
        uint256 indexed epoch,
        uint256 ticketPrice,
        uint256 totalBetTicket,
        uint256 totalBearTicket,
        uint256 totalBullTicket,
        uint256 tickets
    );
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    event StartRound(uint256 indexed epoch, uint256 indexed oracleRoundId, int256 lockPrice);
    event EndRound(uint256 indexed epoch, uint256 indexed oracleRoundId, int256 closePrice);

    event NewAdminAddress(address admin);
    event NewOperatorAddress(address operator);

    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
    event NewOracle(address oracle);
    event NewOracleUpdateAllowance(uint256 oracleUpdateAllowance);
    event NewInitTicketAmount(uint256 indexed epoch, uint256 initTicketAmount);

    event TreasuryClaim(address indexed to, uint256 amount);
    event TreasuryFunding(address indexed from, uint256 amount);

    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );

    event Pause(uint256 indexed epoch);
    event Unpause(uint256 indexed epoch);
    event NewMaxTicketAmount(uint256 indexed maxTicketAmount);
    event NewTicketPrice(uint256 indexed ticketPrice);
    event NewBetAndLockAndBufferSeconds(uint256 betSeconds, uint256 lockSeconds, uint256 bufferSeconds);

    modifier onlyAdmin() {
        require(msg.sender == admin, "BullBear-A1: Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == admin || msg.sender == operator, "BullBear-A2: Not operator/admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "BullBear-A3: Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "BullBear-A4: Contract not allowed");
        require(msg.sender == tx.origin, "BullBear-A5: Proxy contract not allowed");
        _;
    }

    function initialize(
        address _oracleAddress,
        PhaseTimeConfig memory _phaseTimeConfig,
        address _admin,
        address _operator,
        uint256 _treasuryFee,
        uint256 _oracleUpdateAllowance,
        uint256 _ticketPrice,
        uint256 _maxTicketAmount,
        uint256 _initTicketAmount
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_treasuryFee <= MAX_TREASURY_FEE, "BullBear-STF1: Treasury fee too high");

        oracle = AggregatorV3Interface(_oracleAddress);

        betSeconds = _phaseTimeConfig.betSeconds;
        lockSeconds = _phaseTimeConfig.lockSeconds;
        bufferSeconds = _phaseTimeConfig.bufferSeconds;
        admin = _admin;
        operator = _operator;
        treasuryFee = _treasuryFee;
        oracleUpdateAllowance = _oracleUpdateAllowance;
        ticketPrice = _ticketPrice;
        maxTicketAmount = _maxTicketAmount;
        initTicketAmount = _initTicketAmount;

        genesisStartOnce = false;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    function betBull(uint256 epoch, uint256 ticketAmount) external payable whenNotPaused nonReentrant notContract {
        BetInfo storage betInfo = ledger[epoch][msg.sender];
        uint256 amount = msg.value;
        if (betInfo.bullCounter + betInfo.bearCounter == 0) {
            betInfo.ticketPrice = ticketPrice;
            userRounds[msg.sender].push(epoch);
        }

        require(amount >= ticketPrice * ticketAmount, "BullBear-BBU1: Bet amount is less than ticket price");

        // Refund dust amount
        if (amount > ticketPrice * ticketAmount) {
            uint256 dust = amount.sub(ticketPrice * ticketAmount);
            payable(msg.sender).transfer(dust);
        }

        require(epoch == currentEpoch, "BullBear-BBU2: Bet is too early/late");
        require(_bettable(epoch), "BullBear-BBU3: Round not bettable");
        require(betInfo.bullCounter + ticketAmount <= maxTicketAmount, "BullBear-BBU4: Out of bets in round");

        // Update round data
        RoundInfo storage round = rounds[epoch];
        round.bullCounter += ticketAmount;

        // Update user data
        betInfo.bullCounter += ticketAmount;

        emit BetBull(
            msg.sender,
            epoch,
            ticketPrice,
            betInfo.bullCounter,
            round.bearCounter,
            round.bullCounter,
            ticketAmount
        );
    }

    function betBear(uint256 epoch, uint256 ticketAmount) external payable whenNotPaused nonReentrant notContract {
        BetInfo storage betInfo = ledger[epoch][msg.sender];
        uint256 amount = msg.value;
        if (betInfo.bearCounter + betInfo.bullCounter == 0) {
            betInfo.ticketPrice = ticketPrice;
            userRounds[msg.sender].push(epoch);
        }

        require(amount >= ticketPrice * ticketAmount, "BullBear-BBE1: Bet amount is less than ticket price");

        // Refund dust amount
        if (amount > ticketPrice * ticketAmount) {
            uint256 dust = amount.sub(ticketPrice * ticketAmount);
            payable(msg.sender).transfer(dust);
        }

        require(epoch == currentEpoch, "BullBear-BBE2: Bet is too early/late");
        require(_bettable(epoch), "BullBear-BBE3: Round not bettable");
        require(betInfo.bearCounter + ticketAmount <= maxTicketAmount, "BullBear-BBE4: Out of bets in round");

        // Update round data
        RoundInfo storage round = rounds[epoch];
        round.bearCounter += ticketAmount;

        // Update user data
        betInfo.bearCounter += ticketAmount;

        emit BetBear(
            msg.sender,
            epoch,
            ticketPrice,
            betInfo.bearCounter,
            round.bearCounter,
            round.bullCounter,
            ticketAmount
        );
    }

    function claim(uint256[] calldata epochs) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(rounds[epochs[i]].startTimestamp != 0, "BullBear-CLM1: Round has not started");
            require(block.timestamp > rounds[epochs[i]].closeTimestamp, "BullBear-CLM2: Round has not ended");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (
                rounds[epochs[i]].oracleCalled &&
                rounds[epochs[i]].bearCounter != 0 &&
                rounds[epochs[i]].bullCounter != 0
            ) {
                bool bearClaimable = claimable(epochs[i], msg.sender, Position.Bear);
                bool bullClaimable = claimable(epochs[i], msg.sender, Position.Bull);
                require(bearClaimable || bullClaimable, "BullBear-CLM3: Not eligible for claim");

                RoundInfo memory round = rounds[epochs[i]];
                if (bearClaimable) {
                    addedReward =
                        (ledger[epochs[i]][msg.sender].bearCounter *
                            rounds[epochs[i]].ticketPrice *
                            round.rewardAmount) /
                        round.rewardBaseCalAmount;
                }

                if (bullClaimable) {
                    addedReward =
                        (ledger[epochs[i]][msg.sender].bullCounter *
                            rounds[epochs[i]].ticketPrice *
                            round.rewardAmount) /
                        round.rewardBaseCalAmount;
                }
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(epochs[i], msg.sender), "BullBear-CLM4: Not eligible for refund");
                addedReward =
                    (ledger[epochs[i]][msg.sender].bullCounter + ledger[epochs[i]][msg.sender].bearCounter) *
                    ledger[epochs[i]][msg.sender].ticketPrice;
            }

            ledger[epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }

        if (reward > 0) {
            payable(msg.sender).transfer(reward);
        }
    }

    /**
     * @notice Start genesis round
     * @dev Callable by admin or operator
     */
    function genesisStartRound() external whenNotPaused onlyOperator {
        require(!genesisStartOnce, "BullBear-GSR1: Can only run genesisStartRound once");

        (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();
        oracleLatestRoundId = uint256(currentRoundId);

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch, currentRoundId, currentPrice);
        genesisStartOnce = true;
    }

    function executeRound(bool _pauseNextRound) external whenNotPaused onlyOperator {
        require(genesisStartOnce, "BullBear-ER1: Can only run after genesisStartRound is triggered");

        (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();

        oracleLatestRoundId = uint256(currentRoundId);

        _safeEndRound(currentEpoch, currentRoundId, currentPrice);
        _calculateRewards(currentEpoch);

        if (_pauseNextRound) {
            // Pause game
            _pause();
            emit Pause(currentEpoch + 1);
        } else {
            //Start next round
            currentEpoch = currentEpoch + 1;
            _safeStartRound(currentEpoch, currentRoundId, currentPrice);
        }
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyAdminOrOperator {
        _pause();

        emit Pause(currentEpoch);
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     * @dev Callable by admin or operator
     */
    function unpause() external whenPaused onlyAdminOrOperator {
        genesisStartOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    function claimTreasury(address to, uint256 amount) external onlyAdmin {
        require(amount <= treasuryAmount, "BullBear-CT1: Amount exceeded treasury amount");
        treasuryAmount = treasuryAmount.sub(amount);
        payable(to).transfer(amount);
        emit TreasuryClaim(to, amount);
    }

    function fundingTreasury() external payable onlyAdmin {
        treasuryAmount += msg.value;
        emit TreasuryFunding(msg.sender, msg.value);
    }

    /**
     * @notice Set ticket amount
     * @param _maxTicketAmount: ticket amount
     * @dev Callable by admin
     */
    function setMaxTicketAmount(uint256 _maxTicketAmount) external whenPaused onlyAdmin {
        require(_maxTicketAmount != 0, "BullBear-SMTA1: Must be superior to 0");
        maxTicketAmount = _maxTicketAmount;
        emit NewMaxTicketAmount(_maxTicketAmount);
    }

    /**
     * @notice Set ticket price
     * @param _ticketPrice: ticket price
     * @dev Callable by admin
     */
    function setTicketPrice(uint256 _ticketPrice) external whenPaused onlyAdmin {
        require(_ticketPrice != 0, "BullBear-STP1: Must be superior to 0");
        ticketPrice = _ticketPrice;
        emit NewTicketPrice(_ticketPrice);
    }

    /**
     * @notice Set admin address
     * @param _adminAddress: admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "BullBear-SAD1: Cannot be zero address");
        admin = _adminAddress;

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
    function claimable(uint256 epoch, address user, Position position) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        RoundInfo memory round = rounds[epoch];

        return
            round.oracleCalled &&
            (round.bullCounter != 0 && round.bearCounter != 0) &&
            ((betInfo.bullCounter != 0 && position == Position.Bull) ||
                (betInfo.bearCounter != 0 && position == Position.Bear)) &&
            !betInfo.claimed &&
            ((round.lockPrice != round.closePrice && round.lockPrice < round.closePrice && position == Position.Bull) ||
                (round.lockPrice != round.closePrice &&
                    round.lockPrice > round.closePrice &&
                    position == Position.Bear) ||
                round.lockPrice == round.closePrice);
    }

    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        RoundInfo memory round = rounds[epoch];
        return
            (round.oracleCalled &&
                !betInfo.claimed &&
                (round.bullCounter == 0 || round.bearCounter == 0) &&
                betInfo.bullCounter + betInfo.bearCounter > 0) ||
            (!round.oracleCalled &&
                !betInfo.claimed &&
                block.timestamp > round.closeTimestamp + bufferSeconds &&
                betInfo.bullCounter + betInfo.bearCounter > 0);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "BullBear-SOP1: Cannot be zero address");
        operator = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    function setBetAndLockAndBuffer(
        uint256 _betSeconds,
        uint256 _lockSeconds,
        uint256 _bufferSeconds
    ) external whenPaused onlyAdmin {
        require(
            _bufferSeconds < _betSeconds + _lockSeconds,
            "BullBear-SBLB1: bufferSeconds must be inferior to phase seconds"
        );
        bufferSeconds = _bufferSeconds;
        lockSeconds = _lockSeconds;
        betSeconds = _betSeconds;

        emit NewBetAndLockAndBufferSeconds(_betSeconds, _lockSeconds, _bufferSeconds);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external whenPaused onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "BullBear-STF1: Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentEpoch, treasuryFee);
    }

    /**
     * @notice Set Oracle address
     * @dev Callable by admin
     */
    function setOracle(address _oracle) external whenPaused onlyAdmin {
        require(_oracle != address(0), "BullBear-SOR1: Cannot be zero address");
        oracleLatestRoundId = 0;
        oracle = AggregatorV3Interface(_oracle);

        // Dummy check to make sure the interface implements this function properly
        oracle.latestRoundData();

        emit NewOracle(_oracle);
    }

    /**
     * @notice Set oracle update allowance
     * @dev Callable by admin
     */
    function setOracleUpdateAllowance(uint256 _oracleUpdateAllowance) external whenPaused onlyAdmin {
        oracleUpdateAllowance = _oracleUpdateAllowance;

        emit NewOracleUpdateAllowance(_oracleUpdateAllowance);
    }

    /**
     * @notice Set init ticket
     * @dev Callable by admin
     */
    function setInitTicketAmount(uint256 _initTicketAmount) external whenPaused onlyAdmin {
        initTicketAmount = _initTicketAmount;

        emit NewInitTicketAmount(currentEpoch, initTicketAmount);
    }

    /**
     * @notice Start round
     * Previous round n-1 must end
     * @param epoch: epoch
     */
    function _safeStartRound(uint256 epoch, uint80 currentRoundId, int256 lockPrice) internal {
        require(genesisStartOnce, "BullBear-SSR1: Can only run after genesisStartRound is triggered");
        require(rounds[epoch - 1].closeTimestamp != 0, "BullBear-SSR2: Can only start round after round n-1 has ended");
        require(
            block.timestamp >= rounds[epoch - 1].closeTimestamp,
            "BullBear-SSR3: Can only start new round after round n-1 closeTimestamp"
        );
        _startRound(epoch, currentRoundId, lockPrice);
    }

    function _startRound(uint256 epoch, uint80 currentRoundId, int256 lockPrice) internal {
        // Refund init amount to treasuryAmount when the previous round is faulty
        if (!rounds[epoch - 1].oracleCalled && autoBetTicketAmount > 0) {
            treasuryAmount = treasuryAmount.add(rounds[epoch - 1].ticketPrice * autoBetTicketAmount);
        }

        RoundInfo storage round = rounds[epoch];
        round.startTimestamp = block.timestamp;
        round.lockTimestamp = block.timestamp + betSeconds;
        round.closeTimestamp = block.timestamp + betSeconds + lockSeconds;
        round.epoch = epoch;
        round.lockOracleId = currentRoundId;
        round.lockPrice = lockPrice;
        round.ticketPrice = ticketPrice;
        round.bearCounter = 0;
        round.bullCounter = 0;
        autoBetTicketAmount = 0;
        if (treasuryAmount >= 2 * ticketPrice * initTicketAmount) {
            round.bearCounter = initTicketAmount;
            round.bullCounter = initTicketAmount;
            treasuryAmount = treasuryAmount.sub(2 * ticketPrice * initTicketAmount);
            autoBetTicketAmount = 2 * initTicketAmount;
        }
        emit StartRound(epoch, currentRoundId, lockPrice);
    }

    /**
     * @notice Calculate rewards for round
     * @param epoch: epoch
     */
    function _calculateRewards(uint256 epoch) internal {
        require(
            rounds[epoch].rewardBaseCalAmount == 0 && rounds[epoch].rewardAmount == 0,
            "BullBear-CR1: Rewards calculated"
        );
        RoundInfo storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;
        uint256 totalAmount = (round.bearCounter + round.bullCounter) * round.ticketPrice;

        // Round fail
        if (round.bearCounter == 0 || round.bullCounter == 0) {
            rewardBaseCalAmount = totalAmount;
            treasuryAmt = autoBetTicketAmount * round.ticketPrice;
            rewardAmount = totalAmount;
        }
        // Round drawn
        else if (round.closePrice == round.lockPrice) {
            rewardBaseCalAmount = totalAmount;
            treasuryAmt = (totalAmount * treasuryFee) / 10_000;
            rewardAmount = totalAmount.sub(treasuryAmt);
            treasuryAmt += (autoBetTicketAmount * round.ticketPrice * rewardAmount) / rewardBaseCalAmount;
        }
        // Bull wins
        else if (round.closePrice > round.lockPrice) {
            rewardBaseCalAmount = round.bullCounter * round.ticketPrice;
            treasuryAmt = (totalAmount * treasuryFee) / 10_000;
            rewardAmount = totalAmount.sub(treasuryAmt);
            treasuryAmt += ((autoBetTicketAmount / 2) * round.ticketPrice * rewardAmount) / rewardBaseCalAmount;
        }
        // Bear wins
        else if (round.closePrice < round.lockPrice) {
            rewardBaseCalAmount = round.bearCounter * round.ticketPrice;
            treasuryAmt = (totalAmount * treasuryFee) / 10_000;
            rewardAmount = totalAmount.sub(treasuryAmt);
            treasuryAmt += ((autoBetTicketAmount / 2) * round.ticketPrice * rewardAmount) / rewardBaseCalAmount;
        }

        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;
        autoBetTicketAmount = 0;

        // Add to treasury
        treasuryAmount = treasuryAmount.add(treasuryAmt);

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount, treasuryAmt);
    }

    /**
     * @notice End round
     * @param epoch: epoch
     * @param roundId: roundId
     * @param price: price of the round
     */
    function _safeEndRound(uint256 epoch, uint256 roundId, int256 price) internal {
        require(
            block.timestamp >= rounds[epoch].closeTimestamp,
            "BullBear-SER1: Can only end round after closeTimestamp"
        );
        require(
            block.timestamp <= rounds[epoch].closeTimestamp + bufferSeconds,
            "BullBear-SER2: Can only end round within bufferSeconds"
        );
        RoundInfo storage round = rounds[epoch];
        round.closePrice = price;
        round.closeOracleId = roundId;
        round.oracleCalled = true;
        round.closeTimestamp = block.timestamp;

        emit EndRound(epoch, roundId, round.closePrice);
    }

    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current timestamp must be within startTimestamp and closeTimestamp
     */
    function _bettable(uint256 epoch) internal view returns (bool) {
        return
            rounds[epoch].startTimestamp != 0 &&
            rounds[epoch].lockTimestamp != 0 &&
            genesisStartOnce &&
            block.timestamp >= rounds[epoch].startTimestamp &&
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

    /**
     * @notice Get latest recorded price from oracle
     * If it falls below allowed buffer or has not updated, it would be invalid.
     */
    function _getPriceFromOracle() internal view returns (uint80, int256) {
        uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
        (uint80 roundId, int256 price, , uint256 timestamp, ) = oracle.latestRoundData();
        require(timestamp <= leastAllowedTimestamp, "BullBear-ORC1: Oracle update exceeded max timestamp allowance");
        require(
            uint256(roundId) > oracleLatestRoundId,
            "BullBear-ORC2: Oracle update roundId must be larger than oracleLatestRoundId"
        );
        return (roundId, price);
    }
}