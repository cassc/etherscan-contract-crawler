// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITokenVesting.sol";

contract TokenVesting is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeERC20 for IERC20;

    uint256 internal constant SECONDS_PER_WEEK = 604800;

    struct VestingSchedule {
        bool isValid;
        uint256 startTime;
        uint256 amount;
        uint16 duration;
        uint16 delay;
        uint16 weeksClaimed;
        uint256 totalClaimed;
        address recipient;
    }

    event VestingAdded(
        address indexed recipient,
        uint256 vestingId,
        uint256 startTime,
        uint256 amount,
        uint16 duration,
        uint16 delay
    );
    event VestingTokensClaimed(address indexed recipient, uint256 vestingId, uint256 amountClaimed);
    event VestingRemoved(address recipient, uint256 vestingId, uint256 amountVested, uint256 amountNotVested);
    event VestingRecipientUpdated(uint256 vestingId, address oldRecipient, address newRecipient);
    event TokenWithdrawn(address indexed recipient, uint256 tokenAmount);

    IERC20 public immutable token;
    ITokenVesting public immutable oldVestingContract = ITokenVesting(0x85f42ed0c8C6aE626aCA8ebB92aFe23140253AaF);

    mapping(uint256 => VestingSchedule) public vestingSchedules;
    mapping(address => uint256) private activeVesting;
    uint256 public totalVestingCount;
    uint256 public totalVestingAmount;
    bool public allocInitialized;

    constructor(IERC20 _token, address aragonAgent) {
        require(address(aragonAgent) != address(0), "invalid aragon agent address");
        require(address(_token) != address(0), "invalid token address");
        token = _token;
        _transferOwnership(aragonAgent);
    }

    function addVestingSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks
    ) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)) - totalVestingAmount, "Insufficient token balance");
        require(activeVesting[_recipient] == 0, "active vesting already exists");

        uint256 amountVestedPerWeek = _amount.div(_durationInWeeks);
        require(amountVestedPerWeek > 0, "amountVestedPerWeek > 0");

        VestingSchedule memory vesting = VestingSchedule({
            isValid: true,
            startTime: _startTime == 0 ? currentTime() : _startTime,
            amount: _amount,
            duration: _durationInWeeks,
            delay: _delayInWeeks,
            weeksClaimed: 0,
            totalClaimed: 0,
            recipient: _recipient
        });

        totalVestingCount++;
        vestingSchedules[totalVestingCount] = vesting;
        activeVesting[_recipient] = totalVestingCount;
        emit VestingAdded(_recipient, totalVestingCount, vesting.startTime, _amount, _durationInWeeks, _delayInWeeks);
        totalVestingAmount += _amount;
    }

    function getActiveVesting(address _recipient) public view returns (uint256) {
        return activeVesting[_recipient];
    }

    function calculateVestingClaim(uint256 _vestingId) public view returns (uint16, uint256) {
        require(_vestingId > 0, "invalid vestingId");
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        return _calculateVestingClaim(vestingSchedule);
    }

    function _calculateVestingClaim(VestingSchedule storage vestingSchedule) internal view returns (uint16, uint256) {
        if (currentTime() < vestingSchedule.startTime || !vestingSchedule.isValid) {
            return (0, 0);
        }

        uint256 elapsedTime = currentTime().sub(vestingSchedule.startTime);
        uint256 elapsedWeeks = elapsedTime.div(SECONDS_PER_WEEK);

        if (elapsedWeeks < vestingSchedule.delay) {
            return (uint16(elapsedWeeks), 0);
        }

        if (elapsedWeeks >= vestingSchedule.duration + vestingSchedule.delay) {
            uint256 remainingVesting = vestingSchedule.amount.sub(vestingSchedule.totalClaimed);
            return (vestingSchedule.duration, remainingVesting);
        } else {
            uint16 claimableWeeks = uint16(elapsedWeeks.sub(vestingSchedule.delay));
            uint16 weeksVested = uint16(claimableWeeks.sub(vestingSchedule.weeksClaimed));
            uint256 amountVestedPerWeek = vestingSchedule.amount.div(uint256(vestingSchedule.duration));
            uint256 amountVested = uint256(weeksVested.mul(amountVestedPerWeek));
            return (weeksVested, amountVested);
        }
    }

    function claimVestedTokens() external {
        uint256 _vestingId = activeVesting[msg.sender];
        require(_vestingId > 0, "no active vesting found");

        uint16 weeksVested;
        uint256 amountVested;

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];

        require(vestingSchedule.recipient == msg.sender, "only recipient can claim");

        (weeksVested, amountVested) = _calculateVestingClaim(vestingSchedule);
        require(amountVested > 0, "amountVested is 0");

        vestingSchedule.weeksClaimed = uint16(vestingSchedule.weeksClaimed.add(weeksVested));
        vestingSchedule.totalClaimed = uint256(vestingSchedule.totalClaimed.add(amountVested));

        require(token.balanceOf(address(this)) >= amountVested, "no tokens");
        totalVestingAmount -= amountVested;
        token.safeTransfer(vestingSchedule.recipient, amountVested);
        emit VestingTokensClaimed(vestingSchedule.recipient, _vestingId, amountVested);
    }

    function removeVestingSchedule(uint256 _vestingId) external onlyOwner {
        require(_vestingId > 0, "invalid vestingId");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        require(activeVesting[vestingSchedule.recipient] == _vestingId, "inactive vesting");
        address recipient = vestingSchedule.recipient;
        uint16 weeksVested;
        uint256 amountVested;
        (weeksVested, amountVested) = _calculateVestingClaim(vestingSchedule);

        uint256 amountNotVested = (vestingSchedule.amount.sub(vestingSchedule.totalClaimed)).sub(amountVested);

        vestingSchedule.isValid = false;
        activeVesting[recipient] = 0;

        require(token.balanceOf(address(this)) >= amountVested, "not enough balance");
        token.safeTransfer(recipient, amountVested);

        totalVestingAmount -= amountNotVested;
        emit VestingRemoved(recipient, _vestingId, amountVested, amountNotVested);
    }

    function updateVestingRecipient(uint256 _vestingId, address recipient) external onlyOwner {
        require(_vestingId > 0, "invalid vestingId");
        require(activeVesting[recipient] == 0, "recipient has an active vesting");
        require(address(recipient) != address(0), "invalid recipient address");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        require(activeVesting[vestingSchedule.recipient] == _vestingId, "inactive vesting");
        activeVesting[vestingSchedule.recipient] = 0;

        emit VestingRecipientUpdated(_vestingId, vestingSchedule.recipient, recipient);

        vestingSchedule.recipient = recipient;
        activeVesting[recipient] = _vestingId;
    }

    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    function tokensVestedPerWeek(uint256 _vestingId) public view returns (uint256) {
        require(_vestingId > 0, "invalid vestingId");
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        return vestingSchedule.amount.div(uint256(vestingSchedule.duration));
    }

    function withdrawToken(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "invalid token address");
        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, "amount should not exceed balance");
        token.safeTransfer(recipient, amount);
        emit TokenWithdrawn(recipient, amount);
    }

    function init() external onlyOwner {
        require(!allocInitialized, "already initialized.");

        uint256 vestingCount = oldVestingContract.totalVestingCount();
        uint256 totalClaimed = 0;
        // vesting id starts from 1
        for (uint256 i = 1; i <= vestingCount; ++i) {
            ITokenVesting.VestingSchedule memory oldVesting = oldVestingContract.vestingSchedules(i);
            VestingSchedule memory vesting = VestingSchedule({
                isValid: oldVesting.isValid,
                startTime: oldVesting.startTime,
                amount: oldVesting.amount,
                duration: oldVesting.duration,
                delay: oldVesting.delay,
                weeksClaimed: oldVesting.weeksClaimed,
                totalClaimed: oldVesting.totalClaimed,
                recipient: oldVesting.recipient
            });
            vestingSchedules[i] = vesting;
            activeVesting[vesting.recipient] = oldVestingContract.getActiveVesting(vesting.recipient);
            totalClaimed += oldVesting.totalClaimed;
        }

        totalVestingCount = vestingCount;
        totalVestingAmount = oldVestingContract.totalVestingAmount() - totalClaimed;

        allocInitialized = true;
    }
}