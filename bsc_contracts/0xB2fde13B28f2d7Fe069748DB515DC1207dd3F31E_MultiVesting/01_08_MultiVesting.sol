// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVesting.sol";

/// @title MultiVesting
/// @notice Smart contract used to create vesting schedules
contract MultiVesting is IVesting, Ownable {
    using SafeERC20 for IERC20;

    event SetSeller(address newSeller);
    event Vested(address indexed beneficiary, uint256 amount);
    event EmergencyVest(uint256 amount);
    event UpdateBeneficiary(
        address indexed oldBeneficiary,
        address indexed newBeneficiary
    );
    event DisableEarlyWithdraw(address owner);

    IERC20 public immutable token;
    uint256 public sumVesting;
    address public seller;
    address public constant GNOSIS = 0x42DA5e446453319d4076c91d745E288BFef264D0;
    uint256 public immutable updateBeneficiaryMin;
    uint256 public immutable updateBeneficiaryMax;

    mapping(address => uint256) public released;
    mapping(address => Beneficiary) public beneficiary;

    bool public changeBeneficiaryAllowed;
    bool public earlyWithdrawAllowed;

    struct UpdateBeneficiaryLock {
        address oldBeneficiary;
        address newBeneficiary;
        uint256 timestamp;
    }

    mapping(address => UpdateBeneficiaryLock) public updateBeneficiaryLock;

    constructor(
        IERC20 _token,
        bool _changeBeneficiaryAllowed,
        bool _earlyWithdrawAllowed,
        uint256 _updateBeneficiaryMin,
        uint256 _updateBeneficiaryMax
    ) {
        require(address(_token) != address(0), "Can't set zero address");
        token = _token;

        changeBeneficiaryAllowed = _changeBeneficiaryAllowed;
        earlyWithdrawAllowed = _earlyWithdrawAllowed;
        updateBeneficiaryMin = _updateBeneficiaryMin;
        updateBeneficiaryMax = _updateBeneficiaryMax;

        // transferOwnership(GNOSIS);
    }

    /// @notice Sets seller, who can call vest function
    function setSeller(address _addr) external onlyOwner {
        require(_addr != address(0), "Can't set zero address");
        seller = _addr;

        emit SetSeller(seller);
    }

    /// @notice Creates vesting schedule for one person or updates existing one
    /// @param _cliff Duration in seconds
    /// @param _durationSeconds Duration in seconds
    /// @param _startTimestamp Timestamp
    /// @param _amount Amount of tokens, 
    /// if _amount is 0, we update existing schedule
    /// if _amount  > 0, we create new vesting schedule
    
    function vest(
        address _beneficiaryAddress,
        uint256 _startTimestamp,
        uint256 _durationSeconds,
        uint256 _amount,
        uint256 _cliff
    ) external override {
        require(
            sumVesting + _amount <= token.balanceOf(address(this)),
            "Not enough tokens"
        );
        sumVesting += _amount;
        require(msg.sender == seller, "Only sale contract can call");
        // require(
            // _beneficiaryAddress != address(0),
            // "beneficiary is zero address"
        // );

        // require(_durationSeconds > 0, "Duration must be above 0");
        // require(_cliff > 0, "Cliff must be above 0");

        if (_amount > 0) { //trying to create new schedule
            require(
                beneficiary[_beneficiaryAddress].amount == 0,
                "User is already a beneficiary"
            );
        } else { //trying to update existing one
            require(
                beneficiary[_beneficiaryAddress].amount > 0,
                "User is not beneficiary"
            );
            require(
                beneficiary[_beneficiaryAddress].start +
                    beneficiary[_beneficiaryAddress].cliff >=
                    _startTimestamp + _cliff,
                "New cliff must be no later than older one"
            );
        }

        beneficiary[_beneficiaryAddress].start = _startTimestamp;
        beneficiary[_beneficiaryAddress].duration = _durationSeconds;
        beneficiary[_beneficiaryAddress].cliff = _cliff;
        beneficiary[_beneficiaryAddress].amount += _amount;

        emit Vested(_beneficiaryAddress, _amount);
    }

    /// @notice Returns tokens that can be released from vesting.
    function release(address _beneficiary) external override {
        (uint256 _releasableAmount, ) = _releasable(
            _beneficiary,
            block.timestamp
        );

        require(_releasableAmount > 0, "Can't claim yet!");

        released[_beneficiary] += _releasableAmount;
        token.safeTransfer(_beneficiary, _releasableAmount);

        sumVesting -= _releasableAmount;

        emit Released(_releasableAmount, _beneficiary);
    }

    /// @notice Returns amount of tokens that can be released from vesting at given timestamp.
    /// @return canClaim how much user can claim if they call release function
    /// @return earnedAmount how much user has earned
    function releasable(address _beneficiary, uint256 _timestamp)
        external
        view
        override
        returns (uint256 canClaim, uint256 earnedAmount)
    {
        return _releasable(_beneficiary, _timestamp);
    }

    function _releasable(address _beneficiary, uint256 _timestamp)
        internal
        view
        returns (uint256 canClaim, uint256 earnedAmount)
    {
        (canClaim, earnedAmount) = _vestingSchedule(
            _beneficiary,
            beneficiary[_beneficiary].amount,
            _timestamp
        );
        if (released[_beneficiary] > canClaim) canClaim = 0;
        else canClaim -= released[_beneficiary];
    }

    /// @notice Returns amount of tokens that can be released from vesting at given timestamp.
    /// @return vestedAmount how much was earned
    /// @return maxAmount how much tokens can be earned
    function vestedAmountBeneficiary(address _beneficiary, uint256 _timestamp)
        external
        view
        override
        returns (uint256 vestedAmount, uint256 maxAmount)
    {
        return _vestedAmountBeneficiary(_beneficiary, _timestamp);
    }

    function _vestedAmountBeneficiary(address _beneficiary, uint256 _timestamp)
        internal
        view
        returns (uint256 vestedAmount, uint256 maxAmount)
    {
        maxAmount = beneficiary[_beneficiary].amount;
        (, vestedAmount) = _vestingSchedule(
            _beneficiary,
            maxAmount,
            _timestamp
        );
    }

    function _vestingSchedule(
        address _beneficiary,
        uint256 _totalAllocation,
        uint256 _timestamp
    ) internal view returns (uint256, uint256) {
        if (_timestamp < beneficiary[_beneficiary].start) {
            return (0, 0);
        } else if (
            _timestamp >
            beneficiary[_beneficiary].start + beneficiary[_beneficiary].duration
        ) {
            return (_totalAllocation, _totalAllocation);
        } else {
            uint256 res = (_totalAllocation *
                (_timestamp - beneficiary[_beneficiary].start)) /
                beneficiary[_beneficiary].duration;

            if (
                _timestamp <
                beneficiary[_beneficiary].start +
                    beneficiary[_beneficiary].cliff
            ) return (0, res);
            else return (res, res);
        }
    }

    /// @notice Update beneficiary
    function updateBeneficiary(address _oldBeneficiary, address _newBeneficiary)
        external
    {
        require(changeBeneficiaryAllowed, "Option not allowed");
        require(
            msg.sender == owner() || msg.sender == _oldBeneficiary,
            "Not allowed to change"
        );

        require(
            updateBeneficiaryLock[_oldBeneficiary].timestamp == 0 ||
                updateBeneficiaryLock[_oldBeneficiary].timestamp +
                    updateBeneficiaryMax >
                block.timestamp,
            "Update pending"
        );
        require(beneficiary[_oldBeneficiary].amount > 0, "Not a beneficiary");
        require(
            beneficiary[_newBeneficiary].amount == 0,
            "Already a beneficiary"
        );

        updateBeneficiaryLock[_oldBeneficiary] = UpdateBeneficiaryLock(
            _oldBeneficiary,
            _newBeneficiary,
            block.timestamp
        );
    }

    function finishUpdateBeneficiary(address _oldBeneficiary) external {
        require(changeBeneficiaryAllowed, "Option not allowed");

        UpdateBeneficiaryLock memory it = updateBeneficiaryLock[
            _oldBeneficiary
        ];
        require(beneficiary[it.oldBeneficiary].amount > 0, "Not a beneficiary");
        require(
            beneficiary[it.newBeneficiary].amount == 0,
            "Already a beneficiary"
        );

        require(it.timestamp != 0, "No pending updates");
        require(
            block.timestamp > it.timestamp + updateBeneficiaryMin,
            "Required time hasn't passed"
        );
        require(
            block.timestamp < it.timestamp + updateBeneficiaryMax,
            "Time passed, request new update"
        );
        require(
            msg.sender == owner() || msg.sender == it.newBeneficiary,
            "Not allowed to change"
        );

        released[it.newBeneficiary] = released[it.oldBeneficiary];
        beneficiary[it.newBeneficiary] = beneficiary[it.oldBeneficiary];

        delete released[it.oldBeneficiary];
        delete beneficiary[it.oldBeneficiary];
        delete updateBeneficiaryLock[it.oldBeneficiary];

        emit UpdateBeneficiary(it.oldBeneficiary, it.newBeneficiary);
    }

    /// @notice Emergency withdrawal for tokens
    function emergencyVest(IERC20 _token) external override onlyOwner {
        require(earlyWithdrawAllowed, "Option not allowed");

        uint256 amount = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), amount);

        if (address(token) == address(_token)) sumVesting = 0;

        emit EmergencyVest(amount);
    }

    /// @notice Disable withdrawal for tokens
    function disableEarlyWithdraw() external onlyOwner {
        earlyWithdrawAllowed = false;

        emit DisableEarlyWithdraw(msg.sender);
    }
}