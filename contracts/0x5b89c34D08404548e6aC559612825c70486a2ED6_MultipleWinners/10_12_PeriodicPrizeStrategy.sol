// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/ITulipArt.sol";
import "./interfaces/RNGInterface.sol";

/* solium-disable security/no-block-members */
abstract contract PeriodicPrizeStrategy is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    event PrizeLotteryOpened(
        address indexed operator,
        uint256 indexed prizePeriodStartedAt
    );

    event RngRequestFailed();

    event PrizeLotteryAwardStarted(
        address indexed operator,
        uint32 indexed rngRequestId,
        uint32 rngLockBlock
    );

    event PrizeLotteryAwardCancelled(
        address indexed operator,
        uint32 indexed rngRequestId,
        uint32 rngLockBlock
    );

    event PrizePoolAwarded(address indexed operator, uint256 randomNumber);

    event RngServiceUpdated(RNGInterface indexed rngService);

    event RngRequestTimeoutSet(uint32 rngRequestTimeout);

    event PrizePeriodBlocksUpdated(uint256 prizePeriodBlocks);

    event Initialized(
        uint256 prizePeriodStart,
        uint256 prizePeriodBlocks,
        ITulipArt tulipArt,
        RNGInterface rng
    );

    struct RngRequest {
        uint32 id;
        uint32 lockBlock;
        uint32 requestedAt;
    }

    // Contract Interfaces
    ITulipArt public tulipArt;
    RNGInterface public rng;

    // Current RNG Request
    RngRequest internal rngRequest;

    /// @notice RNG Request Timeout. In fact, this is really a "complete award" timeout.
    /// If the rng completes the award can still be cancelled.
    uint32 public rngRequestTimeout;

    // Prize period
    uint256 public prizePeriodBlocks;
    uint256 public prizePeriodStartedAt;

    /// @notice Initializes a new prize period startegy.
    /// @param _prizePeriodStart The starting block of the prize period.
    /// @param _prizePeriodBlocks The duration of the prize period in blocks.
    /// @param _tulipArt The staking contract used to draw winners.
    /// @param _rng The RNG service to use.
    function initialize(
        uint256 _prizePeriodStart,
        uint256 _prizePeriodBlocks,
        uint32 _rngRequestTimeout,
        ITulipArt _tulipArt,
        RNGInterface _rng
    ) public initializer {
        require(
            address(_tulipArt) != address(0),
            "PeriodicPrizeStrategy/lottery-not-zero"
        );
        require(
            address(_rng) != address(0),
            "PeriodicPrizeStrategy/rng-not-zero"
        );
        tulipArt = _tulipArt;
        rng = _rng;

        _setPrizePeriodBlocks(_prizePeriodBlocks);

        __Ownable_init();

        prizePeriodStartedAt = _prizePeriodStart;

        _setRngRequestTimeout(_rngRequestTimeout);

        emit Initialized(
            _prizePeriodStart,
            _prizePeriodBlocks,
            _tulipArt,
            _rng
        );
    }

    /// @notice Starts the award process by starting random number request.
    /// The prize period must have ended.
    /// @dev The RNG-Request-Fee is expected to be held within this contract
    /// before calling this function.
    function startAward() external requireCanStartAward {
        (address feeToken, uint256 requestFee) = rng.getRequestFee();
        if (feeToken != address(0) && requestFee > 0) {
            IERC20Upgradeable(feeToken).safeApprove(address(rng), requestFee);
        }

        (uint32 requestId, uint32 lockBlock) = rng.requestRandomNumber();
        rngRequest.id = requestId;
        rngRequest.lockBlock = lockBlock;
        rngRequest.requestedAt = block.timestamp.toUint32();

        // Tell the TulipArt contract to pause deposits and withdrawals
        // until the RNG winners have been selected
        tulipArt.startDraw();

        emit PrizeLotteryAwardStarted(_msgSender(), requestId, lockBlock);
    }

    /// @notice Completes the award process and awards the winners.
    /// The random number must have been requested and is now available.
    function completeAward() external requireCanCompleteAward {
        uint256 randomNumber = rng.randomNumber(rngRequest.id);
        delete rngRequest;

        _distribute(randomNumber);

        // To avoid clock drift, we should calculate the start block based on
        // the previous period start block.
        prizePeriodStartedAt = _calculateNextPrizePeriodStartBlock(
            block.number
        );

        // Tell TulipArt contracts that deposits/withdrawals are live again
        tulipArt.finishDraw();

        emit PrizePoolAwarded(_msgSender(), randomNumber);
        emit PrizeLotteryOpened(_msgSender(), prizePeriodStartedAt);
    }

    /// @notice Sets the RNG service that the Prize Strategy is connected to.
    /// @param rngService The address of the new RNG service interface.
    function setRngService(RNGInterface rngService)
        external
        onlyOwner
        requireRngNotInFlight
    {
        require(!isRngRequested(), "PeriodicPrizeStrategy/rng-in-flight");

        rng = rngService;
        emit RngServiceUpdated(rngService);
    }

    /// @notice Allows the owner to set the RNG request timeout in seconds.
    /// This is the time that must elapsed before the RNG request can be cancelled
    /// and the pool unlocked.
    /// @param _rngRequestTimeout The RNG request timeout in seconds.
    function setRngRequestTimeout(uint32 _rngRequestTimeout)
        external
        onlyOwner
        requireRngNotInFlight
    {
        _setRngRequestTimeout(_rngRequestTimeout);
    }

    /// @notice Allows the owner to set the prize period in blocks.
    /// @param _prizePeriodBlocks The new prize period in blocks. Must be greater than zero.
    function setPrizePeriodBlocks(uint256 _prizePeriodBlocks)
        external
        onlyOwner
        requireRngNotInFlight
    {
        _setPrizePeriodBlocks(_prizePeriodBlocks);
    }

    /// @notice Returns the block number that the current RNG request has been locked to.
    ///@return The block number that the RNG request is locked to.
    function getLastRngLockBlock() external view returns (uint32) {
        return rngRequest.lockBlock;
    }

    /// @notice Returns the current RNG Request ID.
    /// @return The current Request ID.
    function getLastRngRequestId() external view returns (uint32) {
        return rngRequest.id;
    }

    /// @notice Returns the number of blocks remaining until the prize can be awarded.
    /// @return The number of blocks remaining until the prize can be awarded.
    function prizePeriodRemainingBlocks() external view returns (uint256) {
        return _prizePeriodRemainingBlocks();
    }

    /// @notice Returns whether the prize period is over.
    /// @return True if the prize period is over, false otherwise.
    function isPrizePeriodOver() external view returns (bool) {
        return _isPrizePeriodOver();
    }

    /// @notice Returns the block at which the prize period ends.
    /// @return The block at which the prize period ends.
    function prizePeriodEndAt() external view returns (uint256) {
        // current prize started at is non-inclusive, so add one
        return _prizePeriodEndAt();
    }

    /// @notice Calculates when the next prize period will start.
    /// @param currentBlock The block to use as the current block.
    /// @return The block at which the next prize period would start.
    function calculateNextPrizePeriodStartBlock(uint256 currentBlock)
        external
        view
        returns (uint256)
    {
        return _calculateNextPrizePeriodStartBlock(currentBlock);
    }

    /// @notice Returns whether an award process can be started.
    /// @return True if an award can be started, false otherwise.
    function canStartAward() external view returns (bool) {
        return _isPrizePeriodOver() && !isRngRequested();
    }

    /// @notice Returns whether an award process can be completed.
    /// @return True if an award can be completed, false otherwise.
    function canCompleteAward() external view returns (bool) {
        return isRngRequested() && isRngCompleted();
    }

    /// @notice Can be called by anyone to unlock the tickets if the RNG has timed out.
    function cancelAward() public {
        require(isRngTimedOut(), "PeriodicPrizeStrategy/rng-not-timedout");
        uint32 requestId = rngRequest.id;
        uint32 lockBlock = rngRequest.lockBlock;
        delete rngRequest;

        // Tell TulipArt contracts that deposits/withdrawals are live again
        tulipArt.finishDraw();

        emit RngRequestFailed();
        emit PrizeLotteryAwardCancelled(msg.sender, requestId, lockBlock);
    }

    /// @notice Returns whether a random number has been requested.
    /// @return True if a random number has been requested, false otherwise.
    function isRngRequested() public view returns (bool) {
        return rngRequest.id != 0;
    }

    /// @notice Returns whether the random number request has completed.
    /// @return True if a random number request has completed, false otherwise.
    function isRngCompleted() public view returns (bool) {
        return rng.isRequestComplete(rngRequest.id);
    }

    /// @notice checks if the rng request sent to the CL VRF has timed out.
    /// @return True if it has timed out, False if it hasn't or hasn't been requested.
    function isRngTimedOut() public view returns (bool) {
        if (rngRequest.requestedAt == 0) {
            return false;
        } else {
            return
                block.timestamp >
                uint256(rngRequestTimeout).add(rngRequest.requestedAt);
        }
    }

    /// @notice Sets the RNG request timeout in seconds.  This is the time that must
    /// elapsed before the RNG request can be cancelled and the pool unlocked.
    /// @param _rngRequestTimeout The RNG request timeout in seconds.
    function _setRngRequestTimeout(uint32 _rngRequestTimeout) internal {
        require(
            _rngRequestTimeout > 60,
            "PeriodicPrizeStrategy/rng-timeout-gt-60-secs"
        );
        rngRequestTimeout = _rngRequestTimeout;
        emit RngRequestTimeoutSet(rngRequestTimeout);
    }

    /// @notice Sets the prize period in blocks.
    /// @param _prizePeriodBlocks The new prize period in blocks.
    /// Must be greater than zero.
    function _setPrizePeriodBlocks(uint256 _prizePeriodBlocks) internal {
        require(
            _prizePeriodBlocks > 0,
            "PeriodicPrizeStrategy/prize-period-greater-than-zero"
        );
        prizePeriodBlocks = _prizePeriodBlocks;

        emit PrizePeriodBlocksUpdated(prizePeriodBlocks);
    }

    /// @notice Returns the number of blocks remaining until the prize can be awarded.
    /// @return The number of blocks remaining until the prize can be awarded.
    function _prizePeriodRemainingBlocks() internal view returns (uint256) {
        uint256 endAt = _prizePeriodEndAt();
        if (block.number > endAt) {
            return 0;
        }
        return endAt.sub(block.number);
    }

    /// @notice Returns whether the prize period is over.
    /// @return True if the prize period is over, false otherwise.
    function _isPrizePeriodOver() internal view returns (bool) {
        return block.number >= _prizePeriodEndAt();
    }

    /// @notice Returns the block at which the prize period ends.
    /// @return The block at which the prize period ends.
    function _prizePeriodEndAt() internal view returns (uint256) {
        // current prize started at is non-inclusive, so add one
        return prizePeriodStartedAt.add(prizePeriodBlocks);
    }

    /// @return calculates and returns the next prize period start block.
    function _calculateNextPrizePeriodStartBlock(uint256 currentBlock)
        internal
        view
        returns (uint256)
    {
        uint256 elapsedPeriods = currentBlock.sub(prizePeriodStartedAt).div(
            prizePeriodBlocks
        );
        return prizePeriodStartedAt.add(elapsedPeriods.mul(prizePeriodBlocks));
    }

    /// @notice ensure that the award period is currently not in progress.
    function _requireRngNotInFlight() internal view {
        require(
            rngRequest.lockBlock == 0 || block.number < rngRequest.lockBlock,
            "PeriodicPrizeStrategy/rng-in-flight"
        );
    }

    function _distribute(uint256 randomNumber) internal virtual;

    modifier requireRngNotInFlight() {
        _requireRngNotInFlight();
        _;
    }

    modifier requireCanStartAward() {
        require(
            _isPrizePeriodOver(),
            "PeriodicPrizeStrategy/prize-period-not-over"
        );
        require(
            !isRngRequested(),
            "PeriodicPrizeStrategy/rng-already-requested"
        );
        _;
    }

    modifier requireCanCompleteAward() {
        require(isRngRequested(), "PeriodicPrizeStrategy/rng-not-requested");
        require(isRngCompleted(), "PeriodicPrizeStrategy/rng-not-complete");
        _;
    }
}