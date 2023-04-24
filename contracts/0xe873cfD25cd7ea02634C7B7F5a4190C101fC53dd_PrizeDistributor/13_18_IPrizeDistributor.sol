// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../../rng-service/interfaces/IRNGServiceChainlinkV2.sol";

import "./IPrizeDistributionBuffer.sol";
import "./IDrawBuffer.sol";

/**
 * @title  IPrizeDistributor
 * @author Asymetrix Protocol Inc Team
 * @notice The PrizeDistributor interface.
 */
interface IPrizeDistributor {
    /**
     * @notice RNG Request
     * @param id          RNG request ID.
     * @param lockBlock   Block number when the RNG request is locked.
     * @param requestedAt Time when RNG is requested.
     */
    struct RngRequest {
        uint32 id;
        uint32 lockBlock;
        uint64 requestedAt;
    }

    /**
     * @notice Emit when draw is paid.
     * @param drawId       Draw ID that was paid out.
     * @param totalPayout  Total paid tokens.
     * @param winners      List of addresses winners of the draw.
     * @param winningPicks List of winning picks of the draw.
     * @param payouts      List of payouts for winners of the draw.
     * @param timestamp    Datetime when the draw was paid.
     */
    event DrawPaid(
        uint32 indexed drawId,
        uint256 totalPayout,
        address[] winners,
        uint256[] winningPicks,
        uint256[] payouts,
        uint64 indexed timestamp
    );

    /**
     * @notice Emit when randomness is requested.
     * @param drawId A draw ID for which randomness was requested.
     * @param requestId An internal randomness request ID.
     * @param lockBlock A number of a block when randomness was requested.
     * @param numbersCount An amount of random numbers that was requested.
     */
    event RandomnessRequested(
        uint32 indexed drawId,
        uint32 indexed requestId,
        uint32 indexed lockBlock,
        uint32 numbersCount
    );

    /**
     * @notice Emit when randomness is processed.
     * @param drawId A draw ID for which randomness was processed.
     * @param randomness An array with randomness for a specified `drawId`.
     */
    event RandomnessProcessed(uint32 indexed drawId, uint256[] randomness);

    /**
     * @notice Emit when a randomness request has been cancelled.
     * @param rngRequestId An internal randomness request ID that was cancelled.
     * @param rngLockBlock A block when randomness request becomes invalid.
     */
    event RandomnessRequestCancelled(
        uint32 indexed rngRequestId,
        uint32 rngLockBlock
    );

    /**
     * @notice Emit when a new DrawBuffer is set.
     * @param drawBuffer A new DrawBuffer that is set.
     */
    event DrawBufferSet(IDrawBuffer drawBuffer);

    /**
     * @notice Emit when a new PrizeDistributionBuffer is set.
     * @param prizeDistributionBuffer A new PrizeDistributionBuffer that is set.
     */
    event PrizeDistributionBufferSet(
        IPrizeDistributionBuffer prizeDistributionBuffer
    );

    /**
     * @notice Emit when a new RNG service is set.
     * @param rngService A new RNG service that is set.
     */
    event RngServiceSet(IRNGServiceChainlinkV2 indexed rngService);

    /**
     * @notice Emit when a new prizes distribution is set.
     * @param distribution A new prizes distribution that is set.
     */
    event DistributionSet(uint16[] distribution);

    /**
     * @notice Emit when Token is set.
     * @param token Token address.
     */
    event TokenSet(IERC20Upgradeable indexed token);

    /**
     * @notice Emit when an RNG request timeout is set.
     * @param rngTimeout An RNG request timeout in seconds
     */
    event RngTimeoutSet(uint32 rngTimeout);

    /**
     * @notice Emit when ERC20 tokens are withdrawn.
     * @param token  ERC20 token transferred.
     * @param to     Address that received funds.
     * @param amount Amount of tokens transferred.
     */
    event ERC20Withdrawn(
        IERC20Upgradeable indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @notice Pay prizes to winners using current prizes distribution.
     * @dev    Only callable by contract owner.
     * @param _drawId  An ID of a draw to pay prizes for.
     * @param _winners Winners of a draw.
     * @return true if operation is successful.
     */
    function payWinners(
        uint32 _drawId,
        address[] memory _winners
    ) external returns (bool);

    /**
     * @notice Requests an array of random numbers for a draw according to the
     *         current prizes distribution length.
     * @param _drawId An ID of a draw to request random numbers for.
     * @param _picksNumber A number of picks (participants) in a draw.
     * @param _participantsHash An IPFS hash that links to a list of
     *                          participants in a draw.
     * @param _isEmptyDraw A flag that indicates if a draw has no participants.
     */
    function requestRandomness(
        uint32 _drawId,
        uint256 _picksNumber,
        bytes memory _participantsHash,
        bool _isEmptyDraw
    ) external;

    /**
     * @notice Retrieves an array of random numbers that was requested for a
     *         draw and processes it.
     * @param _drawId An ID of a draw to retrieve random numbers for.
     * @return _randomness An array of random numbers for a draw.
     */
    function processRandomness(
        uint32 _drawId
    ) external returns (uint256[] memory _randomness);

    /**
     * @notice Can be called by anyone to cancel the randomness request if the
     *         RNG has timed out.
     */
    function cancelRandomnessRequest() external;

    /**
     * @notice Transfer ERC20 tokens out of contract to recipient address.
     * @dev    Only callable by contract owner.
     * @param token  IERC20Upgradeable token to transfer.
     * @param to     Recipient of the tokens.
     * @param amount Amount of tokens to transfer.
     * @return true if operation is successful.
     */
    function withdrawERC20(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Set a DrawBuffer.
     * @param _drawBuffer A new DrawBuffer to setup.
     */
    function setDrawBuffer(IDrawBuffer _drawBuffer) external;

    /**
     * @notice Set a PrizeDistributionBuffer.
     * @param _prizeDistributionBuffer A new PrizeDistributionBuffer to setup.
     */
    function setPrizeDistributionBuffer(
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) external;

    /**
     * @notice Set an RNG service that the PrizeDistributor is connected to.
     * @param _rngService The address of the new RNG service interface.
     */
    function setRngService(IRNGServiceChainlinkV2 _rngService) external;

    /**
     * @notice Set prizes distribution.
     * @param _distribution Prizes distribution to setup.
     */
    function setDistribution(uint16[] calldata _distribution) external;

    /**
     * @notice Allows the owner to set an RNG request timeout in seconds. This
     *         is the time that must elaps before an RNG request can be canceled.
     * @param _rngTimeout An RNG request timeout in seconds.
     */
    function setRngTimeout(uint32 _rngTimeout) external;

    /**
     * @notice Read global Ticket address.
     * @return IERC20Upgradeable.
     */
    function getToken() external view returns (IERC20Upgradeable);

    /**
     * @notice Read global DrawBuffer address. The DrawBuffer contains
     *         information about the draw.
     * @return IDrawBuffer.
     */
    function getDrawBuffer() external view returns (IDrawBuffer);

    /**
     * @notice Read global PrizeDistributionBuffer address.
     * @return IPrizeDistributionBuffer.
     */
    function getPrizeDistributionBuffer()
        external
        view
        returns (IPrizeDistributionBuffer);

    /**
     * @notice Read global RNGServiceChainlinkV2 address.
     * @return IRNGServiceChainlinkV2.
     */
    function getRngService() external view returns (IRNGServiceChainlinkV2);

    /**
     * @notice Read global prizes distribution. Returns an array with the split
     *         percentages in which the prizes will be distributed.
     * @return uint16[].
     */
    function getDistribution() external view returns (uint16[] memory);

    /**
     * @notice Read global RNG timeout.
     * @return uint32.
     */
    function getRngTimeout() external view returns (uint32);

    /**
     * @notice Read global info about the last RNG request.
     * @return RngRequest
     */
    function getLastRngRequest() external view returns (RngRequest memory);

    /**
     * @notice Read global prizes distribution length.
     * @return uint16.
     */
    function getNumberOfWinners() external view returns (uint16);

    /**
     * @notice Read global last unpaid draw ID. It increments when the draw is
     *         paid.
     * @return uint32
     */
    function getLastUnpaidDrawId() external view returns (uint32);

    /**
     * @notice Returns whether a random numbers has been requested.
     * @return `true` if a random numbers has been requested, `false` otherwise.
     */
    function isRngRequested() external view returns (bool);

    /**
     * @notice Returns whether the random numbers request has completed.
     * @return `true` if a random numbers request has completed, `false`
     *         otherwise.
     */
    function isRngCompleted() external view returns (bool);

    /**
     * @notice Returns whether the random numbers request has timed out.
     * @return `true` if a random numbers request has timed out, `false`
     *         otherwise.
     */
    function isRngTimedOut() external view returns (bool);
}