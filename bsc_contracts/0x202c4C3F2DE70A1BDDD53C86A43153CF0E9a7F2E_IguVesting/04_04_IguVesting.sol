// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IguVesting is Ownable {
    event Withdrawn(address indexed to, uint256 indexed slot, uint256 amount);

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
     * @notice Returns vesting information
     * @param _address Account
     */
    function batchVestingInfo(
        address _address
    ) external view returns (Vesting[] memory) {
        Vesting[] memory vestings = new Vesting[](_slotsOf[_address]);
        for (uint256 i = 0; i < _slotsOf[_address]; i++) {
            Vesting memory v = _vesting[_address][i];
            vestings[i] = v;
        }
        return vestings;
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
     * @notice Returns amount available to claim for all slots
     * @param _address Owner account
     * @return amount available to withdraw
     */
    function batchAvailable(address _address) public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _slotsOf[_address]; i++) {
            Vesting memory vesting = _vesting[_address][i];
            uint256 unlocked = vesting.activationAmount +
                _vestedAmount(vesting);
            sum += unlocked - vesting.claimedAmount;
        }
        return sum;
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
        require(
            len == _amounts.length &&
                len == _timestampStart.length &&
                len == _timestampEnd.length &&
                len == _initialUnlock.length,
            "ArrayLengthsMismatch"
        );

        uint256 tokensSum;
        for (uint256 i = 0; i < len; i++) {
            address account = _addresses[i];

            // increase required amount to transfer
            tokensSum += _amounts[i];

            require (_initialUnlock[i] <= _amounts[i], "ActivationAmountCantBeGreaterThanFullAmount");

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

        require (
            _token.balanceOf(msg.sender) >= tokensSum &&
            _token.allowance(msg.sender, address(this)) >= tokensSum
        ,
            "InsufficientBalanceOrAllowance"
        );

        _token.transferFrom(msg.sender, address(this), tokensSum);
    }

    /**
     * @notice Withdraws available amount
     * @param to User address
     * @param _slot Vesting slot
     */
    function withdraw(address to, uint256 _slot) external {
        require (_withdraw(to, _slot), "NothingToClaim");
    }

    /**
     * @notice Withdraws available amount
     * @param to User address
     * @param _slot Vesting slot
     */
    function _withdraw(address to, uint256 _slot) internal returns (bool) {
        require (isEnabled, "ClaimingDisabled");

        Vesting storage vesting = _vesting[to][_slot];

        uint256 toWithdraw = available(to, _slot);

        // withdraw all available funds
        if (toWithdraw > 0) {
            vesting.claimedAmount += toWithdraw;
            _token.transfer(to, toWithdraw);
            emit Withdrawn(to, _slot, toWithdraw);
            return true;
        }
        return false;
    }

    /**
     * @notice Withdraws available amounts of first five slots
     * @param to User address
     */
    function batchWithdraw(address to) external {
        bool success;
        for (uint256 i = 0; i < _slotsOf[to]; i++) {
            bool ret = _withdraw(to, i);
            success = ret || success;
        }
        require (success, "NothingToClaim");
    }
}