// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {IVoyStaking} from "./IVoyStaking.sol";

contract VoyVesting is AccessControl {
    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");

    using SafeERC20 for IERC20;

    struct User {
        uint256 lockedAmount;
        uint256 claimAmount;
    }

    mapping(address => User) public users;

    // Vesting Period - 90 Days by default
    uint256 public vestingPeriod = 30 * 3;
    uint256 public endTime;
    uint256 public totalVestedAmount;
    uint256 public totalRewardAmount;

    IERC20 public immutable voyToken;
    IVoyStaking public immutable stakingContract;

    modifier whenStartedVestingSeason() {
        require(endTime > 0, "Voy - Vesting: Season was not started yet!");
        _;
    }

    modifier whenNotStartedVestingSeason() {
        require(endTime == 0, "Voy - Vesting: Season was already started!");
        _;
    }

    modifier whenFinishedVestingPeriod() {
        require(
            block.timestamp > endTime,
            "Voy - Vesting: Vesting period wasn't finished yet"
        );
        _;
    }

    modifier onlyUser() {
        require(
            users[msg.sender].lockedAmount > 0,
            "Voy - Vesting: Not Vester"
        );
        _;
    }

    event Stake(address user, uint256 amount);
    event UpdateVestingPeriod(address _owner, uint256 _vestingPeriod);
    event Claim(address _userAddress, uint256 _claimAmount);

    constructor(IERC20 _voyToken, IVoyStaking _stakingContract) {
        voyToken = _voyToken;
        stakingContract = _stakingContract;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VESTER_ROLE, msg.sender);
    }

    // =============================== Admin Functions ===============================

    // Initialize Functions
    function setVestingPeriod(uint56 _vestingPeriod)
        external
        whenNotStartedVestingSeason
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_vestingPeriod > 0, "VestingPeriod is Zero");
        vestingPeriod = _vestingPeriod;
        emit UpdateVestingPeriod(msg.sender, _vestingPeriod);
    }

    function addUsers(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts
    ) external whenNotStartedVestingSeason onlyRole(VESTER_ROLE) {
        require(
            _userAddresses.length == _amounts.length,
            "UserAddresses length is different with amounts"
        );
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            _addUser(_userAddresses[i], _amounts[i]);
        }
    }

    function addUser(address _userAddress, uint256 _amount)
        external
        whenNotStartedVestingSeason
        onlyRole(VESTER_ROLE)
    {
        _addUser(_userAddress, _amount);
    }

    function _addUser(address _userAddress, uint256 _amount) private {
        require(_userAddress != address(0x0), "UserAddress is Zero");
        require(_amount > 0, "Amount is Zero");
        User storage user = users[_userAddress];
        user.lockedAmount += _amount;
        totalVestedAmount += _amount;
    }

    function stake()
        external
        whenNotStartedVestingSeason
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            voyToken.balanceOf(address(this)) >= totalVestedAmount,
            "Balance is not enough"
        );
        voyToken.approve(address(stakingContract), totalVestedAmount);
        stakingContract.stake(totalVestedAmount);
        endTime = block.timestamp + 3600 * 24 * vestingPeriod;
        emit Stake(msg.sender, totalVestedAmount);
    }

    function withdraw(uint256 _amount)
        external
        whenStartedVestingSeason
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _amount <= voyToken.balanceOf(address(this)) - totalRewardAmount,
            "Too high amount"
        );
        voyToken.safeTransfer(msg.sender, _amount);
    }

    function withdrawAll()
        external
        whenStartedVestingSeason
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 maxAmount = voyToken.balanceOf(address(this)) -
            totalRewardAmount;
        voyToken.safeTransfer(msg.sender, maxAmount);
    }

    // =============================== User Functions ===============================

    function claim() external whenFinishedVestingPeriod onlyUser {
        User storage user = users[msg.sender];
        require(user.claimAmount == 0, "Already claim");
        uint256 lockedAmount = user.lockedAmount;
        uint256 unstakedAmount = stakingContract.unStake(lockedAmount);

        uint256 rewardAmount = stakingContract.harvest();
        totalRewardAmount += rewardAmount;
        uint256 userRewardAmount = (totalRewardAmount * lockedAmount) /
            totalVestedAmount;
        uint256 amount = unstakedAmount + userRewardAmount;
        voyToken.safeTransfer(msg.sender, amount);
        totalVestedAmount -= lockedAmount;
        totalRewardAmount -= userRewardAmount;
        user.claimAmount = amount;
        emit Claim(msg.sender, amount);
    }

    function getClaimAmount(address _userAddress)
        external
        view
        returns (uint256, bool)
    {
        return _getClaimAmount(_userAddress);
    }

    function _getClaimAmount(address _userAddress)
        internal
        view
        returns (uint256, bool)
    {
        bool claimable;
        if (endTime == 0) {
            return (0, false);
        }
        User storage user = users[_userAddress];
        require(user.claimAmount == 0, "Already claimed");
        uint256 unstakedAmount = (stakingContract.getUnStakeFeePercent(
            address(this)
        ) * user.lockedAmount) / 100;
        uint256 _totalRewardAmount = totalRewardAmount +
            stakingContract.getPending(address(this));
        uint256 userRewardAmount = (_totalRewardAmount * user.lockedAmount) /
            totalVestedAmount;
        uint256 amount = unstakedAmount + userRewardAmount;
        if (endTime < block.timestamp) {
            claimable = true;
        }
        return (amount, claimable);
    }
}