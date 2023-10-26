// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract VoyVesting is AccessControl {
    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");

    using SafeERC20 for IERC20;

    address owner;

    struct User {
        bool claimed;
        uint256 totalLocked;
    }

    mapping(address => User) public users;

    uint256 public percentageRewards = 3; //3% in total for the 3 months
    uint256 public vestingStartDate;
    uint256 public vestingEndDate;
    uint256 public totalLockedAmount;
    uint256 public totalUnlockedAmount;
    uint256 public totalRewardsClaimed;

    uint256 public immutable vestingPeriod = 90; //90 days
    IERC20 public immutable voyToken;

    modifier whenStartedVestingSeason() {
        require(vestingEndDate > 0, "Voy - Vesting: Season not started yet!");
        _;
    }

    modifier whenNotStartedVestingSeason() {
        require(vestingEndDate == 0, "Voy - Vesting: Season already started!");
        _;
    }

    modifier whenFinishedVestingPeriod() {
        require(block.timestamp > vestingEndDate, "Voy - Vesting: Vesting Season not finished yet");
        _;
    }

    modifier onlyUser() {
        require(users[msg.sender].totalLocked > 0, "Voy - Vesting: Not Vester");
        _;
    }

    event VestingStarted(address indexed user, uint256 amount);
    event PercentageRewardsUpdated(address indexed _owner, uint256 _percentage);
    event Claim(address indexed _userAddress, uint256 _lockedAmount, uint256 _rewards);

    constructor(IERC20 _voyToken) {
        voyToken = _voyToken;
        owner = msg.sender;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VESTER_ROLE, msg.sender);
    }

    // =============================== User Functions ===============================

    function claim() external whenFinishedVestingPeriod onlyUser {
        User storage user = users[msg.sender];

        require(user.claimed == false, "Already claimed");

        uint256 rewards = calculateVestingRewardsForUser(msg.sender);

        user.claimed = true;

        voyToken.safeTransfer(msg.sender, user.totalLocked + rewards);

        totalUnlockedAmount += user.totalLocked;
        totalRewardsClaimed += rewards;

        emit Claim(msg.sender, user.totalLocked, rewards);
    }

    function totalDaysPassedSinceVesting(uint256 _endDate) public view returns(uint256) {
        if (vestingStartDate == 0) {
            return 0;
        }

        return (_endDate - vestingStartDate) / 60 / 60 / 24;
    }

    function calculateVestingRewards(uint256 _totalLocked, uint256 _totalDays) public view returns (uint256) {
        return (_totalDays * _totalLocked * percentageRewards / 100) / vestingPeriod;
    }

    function calculateVestingRewardsForUser(address _userAddress) public view returns (uint256) {
        User memory user = users[_userAddress];
        
        if (user.totalLocked == 0 || user.claimed || vestingStartDate == 0) {
            return 0;
        }

        uint256 totalDays = totalDaysPassedSinceVesting(block.timestamp);
        if (totalDays > vestingPeriod) {
            totalDays = vestingPeriod;
        }
        
        return calculateVestingRewards(user.totalLocked, totalDays);
    }

    function calculateTotalRequiredToFunction() public view returns(uint256) {
        uint256 totalRewards = calculateVestingRewards(totalLockedAmount, vestingPeriod);
        return totalLockedAmount + totalRewards - totalRewardsClaimed - totalUnlockedAmount;
    }

    // =============================== Admin Functions ===============================

    function setPercentageRewards(uint56 _percentageRewards) external whenNotStartedVestingSeason onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_percentageRewards > percentageRewards, "Can only increase");
        percentageRewards = _percentageRewards;

        emit PercentageRewardsUpdated(msg.sender, _percentageRewards);
    }

    function addUsers(address[] calldata _userAddresses, uint256[] calldata _amounts) external whenNotStartedVestingSeason onlyRole(VESTER_ROLE) {
        require(_userAddresses.length == _amounts.length, "UserAddresses length is different with amounts");
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            _addUser(_userAddresses[i], _amounts[i]);
        }
    }

    function addUser(address _userAddress, uint256 _amount) external whenNotStartedVestingSeason onlyRole(VESTER_ROLE) {
        _addUser(_userAddress, _amount);
    }

    function _addUser(address _userAddress, uint256 _amount) private {
        require(_userAddress != address(0x0), "UserAddress is Zero");
        require(_amount > 0, "Amount is Zero");

        users[_userAddress].totalLocked += _amount;
        totalLockedAmount += _amount;
    }

    function startVestingSeason() external whenNotStartedVestingSeason onlyRole(DEFAULT_ADMIN_ROLE) {
        require(voyToken.balanceOf(address(this)) >= calculateTotalRequiredToFunction(), "Balance is not enough");

        vestingStartDate = block.timestamp;
        vestingEndDate = block.timestamp + 3600 * 24 * vestingPeriod;

        emit VestingStarted(msg.sender, totalLockedAmount);
    }

    function withdraVoy(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (vestingEndDate > 0) {
            require (voyToken.balanceOf(address(this)) - _amount >= calculateTotalRequiredToFunction(), "Invalid amount");
        }
        voyToken.safeTransfer(msg.sender, _amount);
    }

    function recoverETH(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
         (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getUserInfo(address _user) public view returns(bool, uint256, uint256) {
        return (users[_user].claimed, users[_user].totalLocked, calculateVestingRewardsForUser(_user));
    }
}