//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract TokenTransmuter is Ownable, ReentrancyGuard {

    event OutputTokenInstantReleased(address indexed vester, uint256 amount, address tokenAddress);
    event OutputTokenLinearReleased(address indexed vester, uint256 amount, address tokenAddress);

    uint256 public linearMultiplier;
    uint256 public instantMultiplier;
    uint256 public tokenDecimalDivider; // used to equalise an input token and output token with different decimals, e.g. tokenDecimalDivider = 10000000000 to go from an inputToken of 18 decimals to an outputToken of 8 decimals
    uint256 public vestingEntryStartTime;
    uint256 public vestingEntryCloseTime;
    uint256 public totalAllocatedOutputToken;
    uint256 public totalReleasedOutputToken;
    uint256 public linearVestingDuration;
    address public immutable inputTokenAddress;
    address public immutable outputTokenAddress;
    mapping(address => uint256) public addressToTotalAllocatedOutputToken;
    mapping(address => uint256) public addressToTotalReleasedOutputToken;
    mapping(address => uint256) public addressToVestingStartTime;
    mapping(address => uint8) public addressToVestingCode; // 0 = unvested | 1 = instant | 2 = linear vesting

    // Emergency config
    bool public isPaused = false;

    constructor(
        uint256 _linearMultiplier,
        uint256 _instantMultiplier,
        uint256 _tokenDecimalDivider,
        uint256 _vestingEntryStartTime,
        uint256 _vestingEntryCloseTime,
        uint256 _linearVestingDuration,
        address _inputTokenAddress,
        address _outputTokenAddress,
        address _multisigAddress
    ) {
        require(_linearMultiplier > 0);
        require(_instantMultiplier > 0);
        require(_tokenDecimalDivider > 0);
        require(_vestingEntryStartTime > 0);
        require(_vestingEntryCloseTime > _vestingEntryStartTime);
        require(_linearVestingDuration > 0);
        require(_inputTokenAddress != address(0));
        require(_outputTokenAddress != address(0));
        require(_multisigAddress != address(0));
        linearMultiplier = _linearMultiplier;
        instantMultiplier = _instantMultiplier;
        tokenDecimalDivider = _tokenDecimalDivider;
        vestingEntryStartTime = _vestingEntryStartTime;
        vestingEntryCloseTime = _vestingEntryCloseTime;
        linearVestingDuration = _linearVestingDuration;
        inputTokenAddress = _inputTokenAddress;
        outputTokenAddress = _outputTokenAddress;
        transferOwnership(_multisigAddress);
    }

    function transmuteLinear(uint256 _inputTokenAmount) external nonReentrant {
        require(block.timestamp >= vestingEntryStartTime, "ENTRY_NOT_OPEN");
        require(block.timestamp <= vestingEntryCloseTime, "ENTRY_CLOSED");
        require(_inputTokenAmount > 0, "ZERO_INPUT_FORBIDDEN");
        require(addressToVestingCode[msg.sender] == 0, "ALREADY_ENTERED");
        require(isPaused == false, "EMERGENCY_PAUSE");
        addressToVestingCode[msg.sender] = 2;
        addressToVestingStartTime[msg.sender] = block.timestamp;
        uint256 allocation = (_inputTokenAmount * linearMultiplier) / tokenDecimalDivider;
        require(allocation > 0, "ZERO_ALLOCATION_FORBIDDEN");
        addressToTotalAllocatedOutputToken[msg.sender] = allocation;
        totalAllocatedOutputToken = totalAllocatedOutputToken + allocation;
        require(IERC20(outputTokenAddress).balanceOf(address(this)) >= (totalAllocatedOutputToken - totalReleasedOutputToken), "INSUFFICIENT_OUTPUT_TOKEN");
        IERC20(inputTokenAddress).transferFrom(msg.sender, address(0), _inputTokenAmount);
    }

    function transmuteInstant(uint256 _inputTokenAmount) external nonReentrant {
        require(block.timestamp >= vestingEntryStartTime, "ENTRY_NOT_OPEN");
        require(block.timestamp <= vestingEntryCloseTime, "ENTRY_CLOSED");
        require(_inputTokenAmount > 0, "ZERO_INPUT_FORBIDDEN");
        require(addressToVestingCode[msg.sender] == 0, "ALREADY_ENTERED");
        require(isPaused == false, "EMERGENCY_PAUSE");
        addressToVestingCode[msg.sender] = 1;
        addressToVestingStartTime[msg.sender] = block.timestamp;
        uint256 allocation = (_inputTokenAmount * instantMultiplier) / tokenDecimalDivider;
        require(allocation > 0, "ZERO_ALLOCATION_FORBIDDEN");
        require(IERC20(outputTokenAddress).balanceOf(address(this)) >= ((totalAllocatedOutputToken - totalReleasedOutputToken) + allocation), "INSUFFICIENT_UNALLOCATED_OUTPUT_TOKEN");
        addressToTotalAllocatedOutputToken[msg.sender] = allocation;
        addressToTotalReleasedOutputToken[msg.sender] = allocation;
        totalAllocatedOutputToken = totalAllocatedOutputToken + allocation;
        totalReleasedOutputToken = totalReleasedOutputToken + allocation;
        IERC20(inputTokenAddress).transferFrom(msg.sender, address(0), _inputTokenAmount);
        SafeERC20.safeTransfer(IERC20(outputTokenAddress), msg.sender, allocation);
        emit OutputTokenInstantReleased(msg.sender, allocation, outputTokenAddress);
    }

    /**
     * @dev Amount of token already released
     */
    function released(address _vester) public view virtual returns (uint256) {
        return addressToTotalReleasedOutputToken[_vester];
    }

    /**
     * @dev Calculates the amount of tokens that will have been vested at at specific timestamp. Linear vesting curve.
     */
    function vestedAmountAtTimestamp(address _vester, uint64 _timestamp) public view virtual returns (uint256) {
        if (addressToVestingCode[_vester] == 1) {
            return addressToTotalAllocatedOutputToken[_vester];
        } else if (addressToVestingCode[_vester] == 2) {
            return _vestingSchedule(addressToTotalAllocatedOutputToken[_vester], uint64(_timestamp), _vester);
        }
        return 0;
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Linear vesting curve.
     */
    function vestedAmount(address _vester) public view virtual returns (uint256) {
        if (addressToVestingCode[_vester] == 1) {
            return addressToTotalAllocatedOutputToken[_vester];
        } else if (addressToVestingCode[_vester] == 2) {
            return _vestingSchedule(addressToTotalAllocatedOutputToken[_vester], uint64(block.timestamp), _vester);
        }
        return 0;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start(address _vester) public view virtual returns (uint256) {
        return addressToVestingStartTime[_vester];
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return linearVestingDuration;
    }

    /**
     * @dev Release the output token units that have already vested.
     *
     * Emits a {OutputTokenReleased} event.
     */
    function releaseTransmutedLinear() public virtual nonReentrant {
        require(addressToVestingCode[msg.sender] == 2, "NOT_VESTING");
        uint256 releasable = _vestingSchedule(addressToTotalAllocatedOutputToken[msg.sender], uint64(block.timestamp), msg.sender) - released(msg.sender);
        addressToTotalReleasedOutputToken[msg.sender] += releasable;
        totalReleasedOutputToken = totalReleasedOutputToken + releasable;
        emit OutputTokenLinearReleased(msg.sender, releasable, outputTokenAddress);
        SafeERC20.safeTransfer(IERC20(outputTokenAddress), msg.sender, releasable);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp, address _vester) internal view virtual returns (uint256) {
        if (timestamp < start(_vester)) {
            return 0;
        } else if (timestamp > start(_vester) + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start(_vester))) / duration();
        }
    }

    // onlyOwner functions

    function setVestingEntryStartTime(uint256 _vestingEntryStartTime) external onlyOwner {
        vestingEntryStartTime = _vestingEntryStartTime;
    }

    function setVestingEntryCloseTime(uint256 _vestingEntryCloseTime) external onlyOwner {
        vestingEntryCloseTime = _vestingEntryCloseTime;
    }

    function setEmergencyPause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function emergencyPull(address _emergencyOutputDestination) external onlyOwner {
        uint256 outputTokenBalance = IERC20(outputTokenAddress).balanceOf(address(this));
        uint256 vestingRequiredBalance = totalAllocatedOutputToken - totalReleasedOutputToken;
        require(outputTokenBalance > vestingRequiredBalance, "NO_UNALLOCATED_TOKENS");
        SafeERC20.safeTransfer(IERC20(outputTokenAddress), _emergencyOutputDestination, outputTokenBalance - vestingRequiredBalance);
    }

    function outputTokenPull(address _outputDestination) external onlyOwner {
        require(block.timestamp >= vestingEntryCloseTime, "PULL_NOT_YET_ENABLED");
        uint256 outputTokenBalance = IERC20(outputTokenAddress).balanceOf(address(this));
        uint256 vestingRequiredBalance = totalAllocatedOutputToken - totalReleasedOutputToken;
        require(outputTokenBalance > vestingRequiredBalance, "NO_EXCESS_TOKENS");
        SafeERC20.safeTransfer(IERC20(outputTokenAddress), _outputDestination, outputTokenBalance - vestingRequiredBalance);
    }

    /**
     * @dev Recovery function that can be used in case someone accidentally sends their input tokens directly
     * to this contract
     */
    function inputTokenPull(address _inputDestination) external onlyOwner {
        uint256 inputTokenBalance = IERC20(inputTokenAddress).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(inputTokenAddress), _inputDestination, inputTokenBalance);
    }
}