// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../owner-manager/Manageable.sol";

import "./interfaces/IPrizeFlush.sol";

/**
 * @title  Asymetrix Protocol V1 PrizeFlush
 * @author Asymetrix Protocol Inc Team
 * @notice The PrizeFlush contract helps capture interest from the PrizePool and
 *         move collected funds to a designated PrizeDistributor contract. When
 *         deployed, the destination, reserve addresses are set and used as
 *         static parameters during every "flush" execution. The parameters can
 *         be reset by the owner if necessary. The protocol can charge a fee
 *         during the movement of the funds.
 */
contract PrizeFlush is Initializable, IPrizeFlush, Manageable {
    /**
     * @notice Destination address for captured interest.
     * @dev Should be set to the PrizeDistributor address.
     */
    address internal destination;

    /// @notice Fee percentage.
    uint16 internal protocolFeePercentage;

    /// @notice Representation of 100% with 3 decimal places, used to split the
    ///         obtained funds.
    uint16 public constant ONE_AS_FIXED_POINT_3 = 1000;

    /// @notice Receives the protocol fee.
    address internal protocolFeeRecipient;

    /// @notice Reserve address.
    IReserve internal reserve;

    /// @notice Prize Pool address.
    IPrizePool internal prizePool;

    /**
     * @notice Emitted when contract has been deployed.
     * @param destination Destination address.
     * @param reserve Reserve contract address.
     *
     */
    event Deployed(address indexed destination, IReserve indexed reserve);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /**
     * @notice Deploy Prize Flush.
     * @param _owner Prize Flush owner address.
     * @param _destination Destination address.
     * @param _reserve Reserve address.
     * @param _prizePool PrizePool address.
     */
    function initialize(
        address _owner,
        address _destination,
        IReserve _reserve,
        IPrizePool _prizePool
    ) external initializer {
        __Manageable_init_unchained(_owner);

        _setDestination(_destination);
        _setReserve(_reserve);
        _setPrizePool(_prizePool);

        emit Deployed(_destination, _reserve);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeFlush
    function getDestination() external view override returns (address) {
        return destination;
    }

    /// @inheritdoc IPrizeFlush
    function getReserve() external view override returns (IReserve) {
        return reserve;
    }

    /// @inheritdoc IPrizeFlush
    function getPrizePool() external view override returns (IPrizePool) {
        return prizePool;
    }

    /// @inheritdoc IPrizeFlush
    function getProtocolFeeRecipient()
        external
        view
        override
        returns (address)
    {
        return protocolFeeRecipient;
    }

    /// @inheritdoc IPrizeFlush
    function getProtocolFeePercentage()
        external
        view
        override
        returns (uint16)
    {
        return protocolFeePercentage;
    }

    /// @inheritdoc IPrizeFlush
    function setDestination(
        address _destination
    ) external override onlyOwner returns (address) {
        _setDestination(_destination);

        emit DestinationSet(_destination);

        return _destination;
    }

    /// @inheritdoc IPrizeFlush
    function setReserve(
        IReserve _reserve
    ) external override onlyOwner returns (IReserve) {
        _setReserve(_reserve);

        emit ReserveSet(_reserve);

        return _reserve;
    }

    /// @inheritdoc IPrizeFlush
    function setPrizePool(
        IPrizePool _prizePool
    ) external override onlyOwner returns (IPrizePool) {
        _setPrizePool(_prizePool);

        emit PrizePoolSet(_prizePool);

        return _prizePool;
    }

    /// @inheritdoc IPrizeFlush
    function setProtocolFeeRecipient(
        address _protocolFeeRecipient
    ) external override onlyOwner returns (address) {
        _setProtocolFeeRecipient(_protocolFeeRecipient);

        emit ProtocolFeeRecipientSet(_protocolFeeRecipient);

        return _protocolFeeRecipient;
    }

    /// @inheritdoc IPrizeFlush
    function setProtocolFeePercentage(
        uint16 _protocolFeePercentage
    ) external onlyOwner returns (uint16) {
        _setProtocolFeePercentage(_protocolFeePercentage);

        emit ProtocolPercentageSet(_protocolFeePercentage);

        return _protocolFeePercentage;
    }

    /// @inheritdoc IPrizeFlush
    function flush() external override onlyManagerOrOwner returns (bool) {
        _distributeFunds();

        // After funds are distributed, we EXPECT funds to be located in the
        // Reserve contract.
        IReserve _reserve = reserve;
        IERC20Upgradeable _token = _reserve.getToken();
        uint256 _amount = _token.balanceOf(address(_reserve));

        // IF the tokens were successfully moved to the Reserve, now move them
        // to the destination (PrizeDistributor) address.
        if (_amount > 0) {
            address _destination = destination;

            // Create checkpoint and transfers new total balance to
            // PrizeDistributor
            _reserve.withdrawTo(_destination, _amount);

            emit Flushed(_destination, _amount);

            return true;
        }

        return false;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set global destination variable.
     * @dev `_destination` cannot be the zero address.
     * @param _destination Destination address.
     */
    function _setDestination(address _destination) internal {
        require(
            _destination != address(0),
            "Flush/destination-not-zero-address"
        );

        destination = _destination;
    }

    /**
     * @notice Set global reserve variable.
     * @dev `_reserve` cannot be the zero address.
     * @param _reserve Reserve address.
     */
    function _setReserve(IReserve _reserve) internal {
        require(
            address(_reserve) != address(0),
            "Flush/reserve-not-zero-address"
        );

        reserve = _reserve;
    }

    /**
     * @notice Set global prizePool variable.
     * @dev `_prizePool` cannot be the zero address.
     * @param _prizePool PrizePool address.
     */
    function _setPrizePool(IPrizePool _prizePool) internal {
        require(
            address(_prizePool) != address(0),
            "Flush/prizePool-not-zero-address"
        );

        prizePool = _prizePool;
    }

    /**
     * @notice Set global protocolFeeRecipient variable.
     * @dev `_protocolFeeRecipient` cannot be the zero address.
     * @param _protocolFeeRecipient ProtocolFeeRecipient address.
     */
    function _setProtocolFeeRecipient(address _protocolFeeRecipient) internal {
        require(
            address(_protocolFeeRecipient) != address(0),
            "Flush/feeRecipient-not-zero-address"
        );

        protocolFeeRecipient = _protocolFeeRecipient;
    }

    /**
     * @notice Set global protocolFeePercentage variable.
     * @dev `_protocolFeePercentage` cannot be the zero address.
     * @param _protocolFeePercentage ProtocolFeePercentage address.
     */
    function _setProtocolFeePercentage(uint16 _protocolFeePercentage) internal {
        require(
            _protocolFeePercentage <= ONE_AS_FIXED_POINT_3,
            "Flush/feePercentage-greater-100%"
        );

        protocolFeePercentage = _protocolFeePercentage;
    }

    /**
     * @notice Distribute ticket tokens to prize to the reserve and protocol fee
     *         recipient.
     * @dev Transfers the minted ticket tokens to the reserve and protocol fee
     *      recipient.
     */
    function _distributeFunds() internal {
        // Captures interest from PrizePool and distributes funds.
        uint256 prize = prizePool.captureAwardBalance();

        if (prize == 0) return;

        if (protocolFeeRecipient == address(0)) {
            _awardPrizeAmount(address(reserve), prize);
        } else {
            uint256 amountForReserve = (prize *
                (ONE_AS_FIXED_POINT_3 - protocolFeePercentage)) /
                ONE_AS_FIXED_POINT_3;
            uint256 amountForProtocolFee = prize - amountForReserve;

            if (amountForReserve > 0) {
                _awardPrizeAmount(address(reserve), amountForReserve);
            }

            if (amountForProtocolFee > 0) {
                _awardPrizeAmount(protocolFeeRecipient, amountForProtocolFee);
            }
        }

        emit Distributed(prize);
    }

    /**
     * @notice Award ticket tokens to prize split recipient.
     * @dev Award ticket tokens to prize split recipient via the linked
     *      PrizePool contract.
     * @param _to Recipient of minted tokens.
     * @param _amount Amount of minted tokens.
     */
    function _awardPrizeAmount(address _to, uint256 _amount) internal {
        IControlledToken _ticket = prizePool.getTicket();

        prizePool.award(_to, _amount);

        emit PrizeAwarded(_to, _amount, _ticket);
    }
}