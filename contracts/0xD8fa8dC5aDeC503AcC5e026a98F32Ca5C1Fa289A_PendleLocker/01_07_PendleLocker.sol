// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVePendle.sol";
import "../interfaces/IPendleFeeDistributor.sol";

/// @title Pendle Locker
/// @author StakeDAO
/// @notice Locks the PENDLE tokens to vePENDLE contract
contract PendleLocker {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    address public governance;
    address public pendleDepositor;
    address public accumulator;

    address public constant TOKEN = 0x808507121B80c02388fAd14726482e061B8da827;
    address public constant VOTING_ESCROW =
        0x4f30A9D41B80ecC5B94306AB4364951AE3170210;
    address public feeDistributor = 0x8C237520a8E14D658170A633D96F8e80764433b9;

    /* ========== EVENTS ========== */
    event LockCreated(address indexed user, uint256 value, uint256 duration);
    event TokenClaimed(address indexed user, uint256 value);
    event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
    event Released(address indexed user, uint256 value);
    event GovernanceChanged(address indexed newGovernance);
    event PendleDepositorChanged(address indexed newApwDepositor);
    event AccumulatorChanged(address indexed newAccumulator);
    event FeeDistributorChanged(address indexed newFeeDistributor);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _governance, address _accumulator) {
        governance = _governance;
        accumulator = _accumulator;
        IERC20(TOKEN).approve(VOTING_ESCROW, type(uint256).max);
    }

    /* ========== MODIFIERS ========== */
    modifier onlyGovernance() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier onlyGovernanceOrAcc() {
        require(
            msg.sender == governance || msg.sender == accumulator,
            "!(gov||acc)"
        );
        _;
    }

    modifier onlyGovernanceOrDepositor() {
        require(
            msg.sender == governance || msg.sender == pendleDepositor,
            "!(gov||PendleDepositor)"
        );
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Creates a lock by locking PENDLE token in the VEPENDLE contract for the specified time
    /// @dev Can only be called by governance or proxy
    /// @param _value The amount of token to be locked
    /// @param _unlockTime The duration for which the token is to be locked
    function createLock(
        uint128 _value,
        uint128 _unlockTime
    ) external onlyGovernance {
        IVePendle(VOTING_ESCROW).increaseLockPosition(_value, _unlockTime);
        emit LockCreated(msg.sender, _value, _unlockTime);
    }

    /// @notice Increases the amount of PENDLE locked in VEPENDLE
    /// @dev The PENDLE needs to be transferred to this contract before calling
    /// @param _value The amount by which the lock amount is to be increased
    function increaseAmount(uint128 _value) external onlyGovernanceOrDepositor {
        (, uint128 expiry) = IVePendle(VOTING_ESCROW).positionData(address(this));
        IVePendle(VOTING_ESCROW).increaseLockPosition(_value, expiry);
    }

    /// @notice Increases the duration for which PENDLE is locked in VEPENDLE for the user calling the function
    /// @param _unlockTime The duration in seconds for which the token is to be locked
    function increaseUnlockTime(
        uint128 _unlockTime
    ) external onlyGovernanceOrDepositor {
        IVePendle(VOTING_ESCROW).increaseLockPosition(0, _unlockTime);
    }

    /// @notice Claim the token reward from the PENDLE fee Distributor passing the tokens as input parameter
    /// @param _recipient The address which will receive the claimed token reward
    function claimRewards(
        address _recipient,
        address[] calldata _pools
    ) external onlyGovernanceOrAcc {
        (uint256 totalAmount,) = IPendleFeeDistributor(feeDistributor)
            .claimProtocol(_recipient, _pools);
        emit TokenClaimed(_recipient, totalAmount);
    }

    /// @notice Withdraw the PENDLE from VEPENDLE
    /// @dev call only after lock time expires
    /// @param _recipient The address which will receive the released PENDLE
    function release(address _recipient) external onlyGovernance {
        IVePendle(VOTING_ESCROW).withdraw();
        uint256 balance = IERC20(TOKEN).balanceOf(address(this));

        IERC20(TOKEN).safeTransfer(_recipient, balance);
        emit Released(_recipient, balance);
    }

    /// @notice Set new governance address
    /// @param _governance governance address
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit GovernanceChanged(_governance);
    }

    /// @notice Set the PENDLE Depositor
    /// @param _pendleDepositor PENDLE deppositor address
    function setPendleDepositor(
        address _pendleDepositor
    ) external onlyGovernance {
        pendleDepositor = _pendleDepositor;
        emit PendleDepositorChanged(_pendleDepositor);
    }

    /// @notice Set the fee distributor
    /// @param _newFD fee distributor address
    function setFeeDistributor(address _newFD) external onlyGovernance {
        feeDistributor = _newFD;
        emit FeeDistributorChanged(_newFD);
    }

    /// @notice Set the accumulator
    /// @param _accumulator accumulator address
    function setAccumulator(address _accumulator) external onlyGovernance {
        accumulator = _accumulator;
        emit AccumulatorChanged(_accumulator);
    }

    /// @notice execute a function
    /// @param to Address to sent the value to
    /// @param value Value to be sent
    /// @param data Call function data
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyGovernance returns (bool, bytes memory) {
        (bool success, bytes memory result) = to.call{value: value}(data);
        return (success, result);
    }
}