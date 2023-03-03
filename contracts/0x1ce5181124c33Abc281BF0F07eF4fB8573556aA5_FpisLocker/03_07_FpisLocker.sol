// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVeFPIS.sol";
import "../interfaces/IYieldDistributor.sol";

/// @title FpisLocker
/// @author StakeDAO
/// @notice Locks the FPIS tokens to veFPIS contract
contract FpisLocker {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    address public governance;
    address public fpisDepositor;
    address public accumulator;
    address public voter;

    address public constant fpis = address(0xc2544A32872A91F4A553b404C6950e89De901fdb);
    address public constant veFPIS = address(0x574C154C83432B0A45BA3ad2429C3fA242eD7359);
    address public yieldDistributor = address(0xE6D31C144BA99Af564bE7E81261f7bD951b802F6);

    /* ========== EVENTS ========== */
    event LockCreated(address indexed user, uint256 value, uint256 duration);
    event FPISClaimed(address indexed user, uint256 value);
    event Released(address indexed user, uint256 value);
    event GovernanceChanged(address indexed newGovernance);
    event FpisDepositorChanged(address indexed newFxsDepositor);
    event AccumulatorChanged(address indexed newAccumulator);
    event YieldDistributorChanged(address indexed newYieldDistributor);
    event StakerSetProxy(address proxy);
    event VoterChanged(address voter);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _governance, address _accumulator) {
        governance = _governance;
        accumulator = _accumulator;
        IERC20(fpis).approve(veFPIS, type(uint256).max);
    }

    /* ========== MODIFIERS ========== */
    modifier onlyGovernance() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier onlyGovernanceOrAcc() {
        require(msg.sender == governance || msg.sender == accumulator, "!(gov||acc)");
        _;
    }

    modifier onlyGovernanceOrDepositor() {
        require(msg.sender == governance || msg.sender == fpisDepositor, "!(gov||fpisDepositor)");
        _;
    }

    modifier onlyGovernanceOrVoter() {
        require(msg.sender == governance || msg.sender == voter, "!(gov|voter)");
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Creates a lock by locking FPIS token in the veFPIS contract for the specified time
    /// @dev Can only be called by governance
    /// @param _value The amount of token to be locked
    /// @param _unlockTime The duration for which the token is to be locked
    function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernance {
        IVeFPIS(veFPIS).create_lock(_value, _unlockTime);
        IYieldDistributor(yieldDistributor).checkpoint();
        emit LockCreated(msg.sender, _value, _unlockTime);
    }

    /// @notice Increases the amount of FPIS locked in veFPIS
    /// @dev The FPIS needs to be transferred to this contract before calling
    /// @param _value The amount by which the lock amount is to be increased
    function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
        IVeFPIS(veFPIS).increase_amount(_value);
        IYieldDistributor(yieldDistributor).checkpoint();
    }

    /// @notice Increases the duration for which FPIS is locked in veFPIS for the user calling the function
    /// @param _unlockTime The duration in seconds for which the token is to be locked
    function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
        IVeFPIS(veFPIS).increase_unlock_time(_unlockTime);
        IYieldDistributor(yieldDistributor).checkpoint();
    }

    /// @notice Claim the FPIS reward from the FPIS Yield Distributor at 0xE6D31C144BA99Af564bE7E81261f7bD951b802F6
    /// @param _recipient The address which will receive the claimedFPIS reward
    function claimFPISRewards(address _recipient) external onlyGovernanceOrAcc {
        IYieldDistributor(yieldDistributor).getYield();
        emit FPISClaimed(_recipient, IERC20(fpis).balanceOf(address(this)));
        IERC20(fpis).safeTransfer(_recipient, IERC20(fpis).balanceOf(address(this)));
    }

    /// @notice Withdraw the FPIS from veFPIS
    /// @dev call only after lock time expires
    /// @param _recipient The address which will receive the released FPIS
    function release(address _recipient) external onlyGovernance {
        IVeFPIS(veFPIS).withdraw();
        uint256 balance = IERC20(fpis).balanceOf(address(this));

        IERC20(fpis).safeTransfer(_recipient, balance);
        emit Released(_recipient, balance);
    }

    /// @notice Set new governance address
    /// @param _governance governance address
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit GovernanceChanged(_governance);
    }

    /// @notice Set the FPIS Depositor
    /// @param _fpisDepositor fpis deppositor address
    function setFpisDepositor(address _fpisDepositor) external onlyGovernance {
        fpisDepositor = _fpisDepositor;
        emit FpisDepositorChanged(_fpisDepositor);
    }

    /// @notice Set the yield distributor
    /// @param _newYD yield distributor address
    function setYieldDistributor(address _newYD) external onlyGovernance {
        yieldDistributor = _newYD;
        emit YieldDistributorChanged(_newYD);
    }

    /// @notice Set the accumulator
    /// @param _accumulator accumulator address
    function setAccumulator(address _accumulator) external onlyGovernance {
        accumulator = _accumulator;
        emit AccumulatorChanged(_accumulator);
    }

    /// @notice Set the voter
    /// @param _voter voter address
    function setVoter(address _voter) external onlyGovernance {
        voter = _voter;
        emit VoterChanged(_voter);
    }

    /// @notice Set the veFPIS proxy to do activities on its behalf 
    /// @param _proxy frax proxy address 
    function stakerSetProxy(address _proxy) external onlyGovernance {
        IVeFPIS(veFPIS).stakerSetProxy(_proxy);
        emit StakerSetProxy(_proxy);
    }

    /// @notice execute a function
    /// @param to Address to sent the value to
    /// @param value Value to be sent
    /// @param data Call function data
    function execute(address to, uint256 value, bytes calldata data)
        external
        onlyGovernanceOrVoter
        returns (bool, bytes memory)
    {
        (bool success, bytes memory result) = to.call{value: value}(data);
        return (success, result);
    }
}