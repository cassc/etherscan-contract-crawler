// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../rng-service/interfaces/IRNGServiceChainlinkV2.sol";

import "./interfaces/IPrizeDistributionBuffer.sol";
import "./interfaces/IPrizeDistributor.sol";
import "./interfaces/IDrawBuffer.sol";

import "../owner-manager/Manageable.sol";

import "../Constants.sol";

/**
 * @title  Asymetrix Protocol V1 PrizeDistributor
 * @author Asymetrix Protocol Inc Team
 * @notice The PrizeDistributor contract holds Tickets (captured interest) and
           distributes tickets to users with winning draw claims. An admin
           account can indicate the winners that will receive the payment of
           the prizes.
 */
contract PrizeDistributor is
    IPrizeDistributor,
    Manageable,
    Constants,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ============ Global Variables ============ */

    /// @notice Token address
    IERC20Upgradeable private token;

    /// @notice DrawBuffer that stores all draws info
    IDrawBuffer private drawBuffer;

    /// @notice PrizeDistributionBuffer address
    IPrizeDistributionBuffer private prizeDistributionBuffer;

    /// @notice RNG service interface
    IRNGServiceChainlinkV2 internal rngService;

    /// @notice Current RNG request
    RngRequest internal rngRequest;

    /// @notice Distribution of prizes what is used in time of paying
    uint16[] private distribution;

    /// @notice Last unpaid draw ID
    uint32 private lastUnpaidDrawId;

    /// @notice RNG request timeout
    uint32 internal rngTimeout;

    /// @notice 100% with 2 decimal points (i.s. 10000 == 100.00%)
    uint16 public constant ONE_HUNDRED_PERCENTS = 10000;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /**
     * @notice Initialize PrizeDistributor smart contract.
     * @param _owner Owner address.
     * @param _token Token address.
     * @param _drawBuffer DrawBuffer address.
     * @param _prizeDistributionBuffer Initial distribution of prizes.
     * @param _rngService RNG service address.
     * @param _distribution Initial array with distribution percentages.
     * @param _rngTimeout RNG request timeout in seconds.
     */
    function initialize(
        address _owner,
        IERC20Upgradeable _token,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        IRNGServiceChainlinkV2 _rngService,
        uint16[] calldata _distribution,
        uint32 _rngTimeout
    ) external initializer {
        __PrizeDistributor_init(_owner);
        __PrizeDistributor_init_unchained(
            _token,
            _drawBuffer,
            _prizeDistributionBuffer,
            _rngService,
            _distribution,
            _rngTimeout
        );
    }

    function __PrizeDistributor_init(address _owner) internal onlyInitializing {
        __Manageable_init_unchained(_owner);
    }

    function __PrizeDistributor_init_unchained(
        IERC20Upgradeable _token,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        IRNGServiceChainlinkV2 _rngService,
        uint16[] calldata _distribution,
        uint32 _rngTimeout
    ) internal onlyInitializing {
        _setToken(_token);
        _setDrawBuffer(_drawBuffer);
        _setPrizeDistributionBuffer(_prizeDistributionBuffer);
        _setRngService(_rngService);
        _setDistribution(_distribution);
        _setRngTimeout(_rngTimeout);

        lastUnpaidDrawId = 1;
    }

    /* ============ Public Functions ============ */

    /// @inheritdoc IPrizeDistributor
    function isRngRequested() public view override returns (bool) {
        return rngRequest.id != 0;
    }

    /// @inheritdoc IPrizeDistributor
    function isRngCompleted() public view override returns (bool) {
        return rngService.isRequestCompleted(rngRequest.id);
    }

    /// @inheritdoc IPrizeDistributor
    function isRngTimedOut() public view override returns (bool) {
        if (rngRequest.requestedAt == 0) {
            return false;
        }

        return rngTimeout + rngRequest.requestedAt < block.timestamp;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeDistributor
    function payWinners(
        uint32 _drawId,
        address[] memory _winners
    ) external override nonReentrant onlyManagerOrOwner returns (bool) {
        IDrawBeacon.Draw memory _draw = drawBuffer.getDraw(_drawId);

        _validateDraw(_draw);

        require(
            (_draw.isEmpty && _winners.length == 0) ||
                (!_draw.isEmpty && _winners.length == distribution.length),
            "PrizeDistributor/lengths-mismatch"
        );

        uint256 _totalPayout;

        if (_winners.length != 0) {
            _totalPayout = token.balanceOf(address(this));

            require(_totalPayout > 0, "PrizeDistributor/prizes-amount-is-zero");
        }

        uint256[] memory _payouts = new uint256[](_winners.length);
        uint16[] memory _distribution = distribution;

        for (uint16 i = 0; i < _winners.length; ++i) {
            require(
                _winners[i] != address(0),
                "PrizeDistributor/winner-is-zero-address"
            );

            uint256 _amount = (_totalPayout * _distribution[i]) /
                ONE_HUNDRED_PERCENTS;

            _awardPayout(_winners[i], _amount);

            _payouts[i] = _amount;
        }

        drawBuffer.markDrawAsPaid(_drawId);

        ++lastUnpaidDrawId;

        emit DrawPaid(
            _drawId,
            _totalPayout,
            _winners,
            _draw.randomness,
            _payouts,
            uint32(block.timestamp)
        );

        return true;
    }

    /// @inheritdoc IPrizeDistributor
    function requestRandomness(
        uint32 _drawId,
        uint256 _picksNumber,
        bytes memory _participantsHash,
        bool _isEmptyDraw
    ) external nonReentrant onlyManager {
        IDrawBeacon.Draw memory _draw = drawBuffer.getDraw(_drawId);

        _validateDraw(_draw);

        require(
            _participantsHash.length != 0,
            "PrizeDistributor/participants-hash-can-not-have-zero-length"
        );
        require(
            !isRngRequested(),
            "PrizeDistributor/randomness-already-requested"
        );

        uint32 _numbersCount = uint32(distribution.length);
        uint32 _requestId;
        uint32 _lockBlock;

        if (!_isEmptyDraw) {
            (_requestId, _lockBlock) = rngService.requestRandomNumbers(
                _numbersCount
            );

            rngRequest.id = _requestId;
            rngRequest.lockBlock = _lockBlock;
            rngRequest.requestedAt = uint32(block.timestamp);
        }

        _draw.rngRequestInternalId = _requestId;
        _draw.picksNumber = _picksNumber;
        _draw.participantsHash = _participantsHash;
        _draw.isEmpty = _isEmptyDraw;

        drawBuffer.setDraw(_draw);

        emit RandomnessRequested(
            _drawId,
            _requestId,
            _lockBlock,
            _numbersCount
        );
    }

    /// @inheritdoc IPrizeDistributor
    function processRandomness(
        uint32 _drawId
    ) external nonReentrant onlyManager returns (uint256[] memory _randomness) {
        IDrawBeacon.Draw memory _draw = drawBuffer.getDraw(_drawId);

        _validateDraw(_draw);

        require(
            isRngRequested(),
            "PrizeDistributor/randomness-is-not-requested"
        );
        require(
            isRngCompleted(),
            "PrizeDistributor/randomness-request-is-not-completed"
        );

        _randomness = rngService.getRandomNumbers(rngRequest.id);

        uint256 _randomnessLength = _randomness.length;

        require(
            _randomnessLength == distribution.length,
            "PrizeDistributor/lengths-mismatch"
        );

        for (uint256 i = 0; i < _randomnessLength; ++i) {
            if (_draw.picksNumber != 0) {
                _randomness[i] = _randomness[i] % _draw.picksNumber;
            }
        }

        _draw.randomness = _randomness;

        drawBuffer.setDraw(_draw);

        delete rngRequest;

        emit RandomnessProcessed(_drawId, _randomness);
    }

    function cancelRandomnessRequest() external override {
        require(
            isRngTimedOut(),
            "PrizeDistributor/randomness-request-not-timedout"
        );

        uint32 _requestId = rngRequest.id;
        uint32 _lockBlock = rngRequest.lockBlock;

        delete rngRequest;

        emit RandomnessRequestCancelled(_requestId, _lockBlock);
    }

    /// @inheritdoc IPrizeDistributor
    function withdrawERC20(
        IERC20Upgradeable _erc20Token,
        address _to,
        uint256 _amount
    ) external override onlyOwner returns (bool) {
        require(
            _to != address(0),
            "PrizeDistributor/recipient-not-zero-address"
        );
        require(
            address(_erc20Token) != address(0),
            "PrizeDistributor/ERC20-not-zero-address"
        );

        _erc20Token.safeTransfer(_to, _amount);

        emit ERC20Withdrawn(_erc20Token, _to, _amount);

        return true;
    }

    /// @inheritdoc IPrizeDistributor
    function setDrawBuffer(
        IDrawBuffer _drawBuffer
    ) external override onlyOwner {
        _setDrawBuffer(_drawBuffer);
    }

    /// @inheritdoc IPrizeDistributor
    function setPrizeDistributionBuffer(
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) external override onlyOwner {
        _setPrizeDistributionBuffer(_prizeDistributionBuffer);
    }

    /// @inheritdoc IPrizeDistributor
    function setRngService(
        IRNGServiceChainlinkV2 _rngService
    ) external override onlyOwner {
        _setRngService(_rngService);
    }

    /// @inheritdoc IPrizeDistributor
    function setDistribution(
        uint16[] calldata _distribution
    ) external override onlyOwner {
        _setDistribution(_distribution);
    }

    /// @inheritdoc IPrizeDistributor
    function setRngTimeout(uint32 _rngTimeout) external override onlyOwner {
        _setRngTimeout(_rngTimeout);
    }

    /// @inheritdoc IPrizeDistributor
    function getToken() external view override returns (IERC20Upgradeable) {
        return token;
    }

    /// @inheritdoc IPrizeDistributor
    function getDrawBuffer() external view override returns (IDrawBuffer) {
        return drawBuffer;
    }

    /// @inheritdoc IPrizeDistributor
    function getPrizeDistributionBuffer()
        external
        view
        override
        returns (IPrizeDistributionBuffer)
    {
        return prizeDistributionBuffer;
    }

    /// @inheritdoc IPrizeDistributor
    function getRngService()
        external
        view
        override
        returns (IRNGServiceChainlinkV2)
    {
        return rngService;
    }

    /// @inheritdoc IPrizeDistributor
    function getDistribution()
        external
        view
        override
        returns (uint16[] memory)
    {
        return distribution;
    }

    /// @inheritdoc IPrizeDistributor
    function getRngTimeout() external view override returns (uint32) {
        return rngTimeout;
    }

    /// @inheritdoc IPrizeDistributor
    function getLastRngRequest()
        external
        view
        override
        returns (RngRequest memory)
    {
        return rngRequest;
    }

    /// @inheritdoc IPrizeDistributor
    function getNumberOfWinners() external view override returns (uint16) {
        return uint16(distribution.length);
    }

    /// @inheritdoc IPrizeDistributor
    function getLastUnpaidDrawId() external view override returns (uint32) {
        return lastUnpaidDrawId;
    }

    /* ============ Private Functions ============ */

    /**
     * @notice Transfer claimed draw(s) total payout to user.
     * @param _to      User address
     * @param _amount  Transfer amount
     */
    function _awardPayout(address _to, uint256 _amount) private {
        if (_amount > 0) {
            token.safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice Set token that is used for prizes payment.
     * @param _token  A token to setup.
     */
    function _setToken(IERC20Upgradeable _token) private {
        require(
            address(_token) != address(0),
            "PrizeDistributor/token-not-zero-address"
        );

        token = _token;

        emit TokenSet(_token);
    }

    /**
     * @notice Set a DrawBuffer.
     * @param _drawBuffer A DrawBuffer to setup.
     */
    function _setDrawBuffer(IDrawBuffer _drawBuffer) private {
        require(
            address(_drawBuffer) != address(0),
            "PrizeDistributor/draw-buffer-not-zero-address"
        );

        drawBuffer = _drawBuffer;

        emit DrawBufferSet(_drawBuffer);
    }

    /**
     * @notice Set a PrizeDistributionBuffer.
     * @param _prizeDistributionBuffer A PrizeDistributionBuffer to setup.
     */
    function _setPrizeDistributionBuffer(
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) private {
        require(
            address(_prizeDistributionBuffer) != address(0),
            "PrizeDistributor/prize-distribution-buffer-not-zero-address"
        );

        prizeDistributionBuffer = _prizeDistributionBuffer;

        emit PrizeDistributionBufferSet(_prizeDistributionBuffer);
    }

    /**
     * @notice Set a RNG service that the PrizeDistributor is connected to.
     * @param _rngService The address of the new RNG service interface.
     */
    function _setRngService(IRNGServiceChainlinkV2 _rngService) internal {
        require(
            address(_rngService) != address(0),
            "PrizeDistributor/rng-service-not-zero-address"
        );

        rngService = _rngService;

        emit RngServiceSet(_rngService);
    }

    /**
     * @notice Set prizes distribution.
     * @param _distribution  Prizes distribution to setup.
     */
    function _setDistribution(uint16[] calldata _distribution) private {
        require(
            _distribution.length <= MAX_DISTRIBUTION_LENGTH,
            "PrizeDistributor/wrong-array-length"
        );

        uint16 _totalDistribution;

        for (uint16 i = 0; i < _distribution.length; ++i) {
            _totalDistribution += _distribution[i];
        }

        require(
            _totalDistribution == ONE_HUNDRED_PERCENTS,
            "PrizeDistributor/distribution-should-be-equal-to-100%"
        );

        delete distribution;

        distribution = _distribution;

        emit DistributionSet(_distribution);
    }

    /**
     * @notice Set an RNG request timeout in seconds. This is the time that
     *         must elapsed before an RNG request can be cancelled.
     * @param _rngTimeout An RNG request timeout in seconds.
     */
    function _setRngTimeout(uint32 _rngTimeout) internal {
        require(_rngTimeout > 60, "PrizeDistributor/rng-timeout-gt-60-seconds");

        rngTimeout = _rngTimeout;

        emit RngTimeoutSet(_rngTimeout);
    }

    /**
     * @notice Validates a draw before requesting randomness and prizes payment.
     * @param _draw A draw to validate.
     */
    function _validateDraw(IDrawBeacon.Draw memory _draw) private view {
        require(
            _draw.drawId == lastUnpaidDrawId,
            "PrizeDistributor/draw-id-should-be-the-same-as-last-unpaid-draw-id"
        );
        require(
            block.timestamp >
                _draw.beaconPeriodStartedAt + _draw.beaconPeriodSeconds,
            "PrizeDistributor/draw-is-not-finished-yet"
        );
        require(!_draw.paid, "PrizeDistributor/draw-is-already-paid");
    }

    uint256[45] private __gap;
}