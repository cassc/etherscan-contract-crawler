// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IguVesting is Ownable {
    error ArrayLengthsMismatch(uint256 length);
    error InsufficientBalanceOrAllowance(uint256 required);
    error VestingNotFound();
    error VestingNotStartedYet();
    error ActivationAmountCantBeGreaterThanFullAmount();
    error ClaimingDisabled();

    struct Vesting {
        /// @notice Total vesting amount (includes activation amount)
        uint256 vestingAmount;
        /// @notice Alread vested amount
        uint256 claimedAmount;
        /// @notice Activation amount - released fully after vesting start time
        uint256 activationAmount;
        /// @notice Vesting beginning time
        uint256 timestampStart;
        /// @notice Vesting ending time
        uint256 timestampEnd;
    }

    /// @notice IGU ERC20 token
    IERC20 internal _token;

    /// @notice List of vestings
    /// @dev address => index => Vesting
    mapping(address => mapping(uint256 => Vesting)) internal _vesting;

    /// @notice Number of vestings for each account
    mapping(address => uint256) internal _slotsOf;

    /// @notice Is Claiming Enabled
    bool public isEnabled;

    constructor(IERC20 _tokenContractAddress) {
        _token = _tokenContractAddress;
    }

    /**
     * @notice Enables claiming
     */
    function enable() external onlyOwner {
        isEnabled = true;
    }

    /**
     * @notice Number of vestings for each account
     * @param _address Account
     */
    function slotsOf(address _address) external view returns (uint256) {
        return _slotsOf[_address];
    }

    /**
     * @notice Returns vesting information
     * @param _address Account
     * @param _slot Slot index
     */
    function vestingInfo(
        address _address,
        uint256 _slot
    ) external view returns (Vesting memory) {
        return _vesting[_address][_slot];
    }

    /**
     * @dev Internal function.
     * Calculates vested amount available to claim (at the moment of execution)
     */
    function _vestedAmount(
        Vesting memory vesting
    ) internal view returns (uint256) {
        if (vesting.vestingAmount == 0) {
            return 0;
        }

        if (block.timestamp < vesting.timestampStart) {
            return 0;
        }

        if (block.timestamp >= vesting.timestampEnd) {
            // in case of exceeding end time
            return vesting.vestingAmount - vesting.activationAmount;
        }

        uint256 vestingAmount = vesting.vestingAmount -
            vesting.activationAmount;
        uint256 vestingPeriod = vesting.timestampEnd - vesting.timestampStart;
        uint256 timeSinceVestingStart = block.timestamp -
            vesting.timestampStart;
        uint256 unlockedAmount = (vestingAmount * timeSinceVestingStart) /
            vestingPeriod;
        return unlockedAmount;
    }

    /**
     * @notice Returns amount available to claim
     * @param _address Owner account
     * @param _slot Vesting slot
     * @return amount available to withdraw
     */
    function available(
        address _address,
        uint256 _slot
    ) public view returns (uint256) {
        Vesting memory vesting = _vesting[_address][_slot];
        uint256 unlocked = vesting.activationAmount + _vestedAmount(vesting);
        return unlocked - vesting.claimedAmount;
    }

    /**
     * @notice Adds vesting informations.
     * In case of linear vesting of 200 tokens and intial unlock of 50 tokens
     *      _amounts[i] should contain 200
     *      _initialUnlock[i] should contain 50
     * @param _addresses Addresses
     * @param _amounts Vesting amount (this value excludes inital unlock amount)
     * @param _timestampStart Start timestamps
     * @param _timestampEnd End timestamps
     * @param _initialUnlock Intially unlocked amounts
     */
    function addVestingEntries(
        address[] memory _addresses,
        uint256[] memory _amounts,
        uint256[] memory _timestampStart,
        uint256[] memory _timestampEnd,
        uint256[] memory _initialUnlock
    ) external onlyOwner {
        uint256 len = _addresses.length;
        if (
            len != _amounts.length ||
            len != _timestampStart.length ||
            len != _timestampEnd.length ||
            len != _initialUnlock.length
        ) {
            revert ArrayLengthsMismatch(len);
        }

        uint256 tokensSum;
        for (uint256 i = 0; i < len; i++) {
            address account = _addresses[i];

            // increase required amount to transfer
            tokensSum += _amounts[i];

            if (_initialUnlock[i] > _amounts[i]) {
                revert ActivationAmountCantBeGreaterThanFullAmount();
            }

            Vesting memory vesting = Vesting(
                _amounts[i],
                0,
                _initialUnlock[i],
                _timestampStart[i],
                _timestampEnd[i]
            );

            uint256 vestingNum = _slotsOf[account];
            _vesting[account][vestingNum] = vesting;
            _slotsOf[account]++;
        }

        if (
            _token.balanceOf(msg.sender) < tokensSum ||
            _token.allowance(msg.sender, address(this)) < tokensSum
        ) {
            revert InsufficientBalanceOrAllowance(tokensSum);
        }

        _token.transferFrom(msg.sender, address(this), tokensSum);
    }

    /**
     * @notice Withdraws available amount
     * @param _slot Vesting slot
     */
    function withdraw(address to, uint256 _slot) external {
        if (!isEnabled) {
            revert ClaimingDisabled();
        }

        Vesting storage vesting = _vesting[to][_slot];

        if (vesting.vestingAmount == 0) {
            revert VestingNotFound();
        }

        uint256 toWithdraw = available(to, _slot);

        vesting.claimedAmount += toWithdraw;

        // withdraw all available funds
        _token.transfer(to, toWithdraw);
    }
}