// SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Stablz vesting contract
contract StablzVesting is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    IERC20 public stablz;

    uint constant private TGE_PERCENT_DENOMINATOR = 100;

    uint public vestingStartedAt;

    uint public totalAmount;
    uint public totalWithdrawn;

    struct Vestment {
        uint amount;
        uint withdrawn;
        uint period;
        /// @dev tgeAmount refers to the amount that the user is allowed to withdraw at TGE
        uint tgeAmount;
        bool isTGEAmountWithdrawn;
    }

    struct User {
        uint numberOfVestments;
        mapping(uint => Vestment) vestments;
    }

    mapping(address => User) private _users;

    event Withdrawn(address user, uint amount);
    event VestingPeriodStarted();

    /// @param _user User address
    /// @param _vestmentId Vestment ID
    modifier onlyValidVestmentId(address _user, uint _vestmentId) {
        uint numberOfVestments = _users[_user].numberOfVestments;
        require(numberOfVestments > 0, "StablzVesting: No vestments found for user");
        require(_vestmentId < numberOfVestments, "StablzVesting: Invalid vestment ID");
        _;
    }

    /// @notice Import vesting data
    /// @param _addresses List of addresses
    /// @param _amounts List of amounts
    /// @param _tgePercent TGE percentage e.g. 20 is 20%
    /// @param _vestingPeriod Vesting period in seconds e.g. 2592000 is 30 days
    function importData(address[] calldata _addresses, uint[] calldata _amounts, uint _tgePercent, uint _vestingPeriod) external onlyOwner {
        require(!_hasVestingStarted(), "StablzVesting: Cannot import data after vesting has started");
        require(_addresses.length == _amounts.length, "StablzVesting: _addresses and _amounts list lengths do not match");
        require(_tgePercent < TGE_PERCENT_DENOMINATOR, "StablzVesting: _tgePercent must be less than 100");
        uint total;
        for (uint i; i < _addresses.length; i++) {
            total += _amounts[i];
            User storage user = _users[_addresses[i]];

            uint tgeAmount;
            if (_tgePercent > 0) {
                tgeAmount = _amounts[i] * _tgePercent / TGE_PERCENT_DENOMINATOR;
            }
            uint vested = _amounts[i] - tgeAmount;
            user.vestments[user.numberOfVestments] = Vestment(
                vested,
                0,
                _vestingPeriod,
                tgeAmount,
                false
            );
            user.numberOfVestments++;
        }
        totalAmount += total;
    }

    /// @notice Start vesting period
    /// @param _stablz Stablz token address
    function startVestingPeriod(IERC20 _stablz) external onlyOwner {
        require(address(_stablz) != address(0), "StablzVesting: _stablz cannot be the zero address");
        require(!_hasVestingStarted(), "StablzVesting: Vesting period has already started");
        require(totalAmount > 0, "StablzVesting: No data has been configured");
        stablz = _stablz;
        vestingStartedAt = block.timestamp;
        stablz.safeTransferFrom(_msgSender(), address(this), totalAmount);
        emit VestingPeriodStarted();
    }

    /// @notice Withdraw Stablz tokens
    function withdraw(uint _vestmentId) external nonReentrant onlyValidVestmentId(_msgSender(), _vestmentId) {
        require(_hasVestingStarted(), "StablzVesting: Unlock period has not started");
        User storage user = _users[_msgSender()];
        Vestment storage vestment = user.vestments[_vestmentId];
        bool unclaimedTGE = !vestment.isTGEAmountWithdrawn && vestment.tgeAmount > 0;
        bool unclaimedVestment = vestment.withdrawn < vestment.amount;
        require(unclaimedTGE || unclaimedVestment, "StablzVesting: You have already withdrawn the total amount");
        uint amount;
        if (unclaimedTGE) {
            vestment.isTGEAmountWithdrawn = true;
            amount += vestment.tgeAmount;
        }
        uint available = _availableToWithdraw(vestment);
        vestment.withdrawn += available;
        amount += available;
        totalWithdrawn += amount;
        stablz.safeTransfer(_msgSender(), amount);
        emit Withdrawn(_msgSender(), amount);
    }

    /// @notice Get the number of vestments for a user
    /// @param _user User address
    /// @return uint The total number of user vestments
    function getNumberOfVestments(address _user) external view returns (uint) {
        return _users[_user].numberOfVestments;
    }

    /// @notice Get details about a vestment for a given user and vestment ID
    /// @param _user User address
    /// @param _vestmentId Vestment ID
    /// @return Vestment A user's vestment
    function getVestment(address _user, uint _vestmentId) external view onlyValidVestmentId(_user, _vestmentId) returns (Vestment memory) {
        return _users[_user].vestments[_vestmentId];
    }

    /// @dev Calculate amount to withdraw based on the current time relative to the vesting period
    /// @param _vestment Vestment
    /// @return amount Available amount to withdraw for a given vestment
    function _availableToWithdraw(Vestment memory _vestment) internal view returns (uint amount) {
        uint endDate = vestingStartedAt + _vestment.period;
        if (block.timestamp >= endDate) {
            amount = _vestment.amount - _vestment.withdrawn;
        } else {
            uint timeDifference = block.timestamp - vestingStartedAt;
            amount = (_vestment.amount * timeDifference / _vestment.period) - _vestment.withdrawn;
        }
    }

    /// @dev Checks whether or not the vesting period has started
    /// @return bool true if vesting has started, false if not
    function _hasVestingStarted() internal view returns (bool) {
        return vestingStartedAt > 0;
    }
}