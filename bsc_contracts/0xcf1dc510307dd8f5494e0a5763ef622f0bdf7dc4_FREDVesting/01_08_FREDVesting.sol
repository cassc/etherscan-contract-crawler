// SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title FRED vesting contract
contract FREDVesting is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    uint public constant VESTING_PERIOD = 45 days;
    uint public constant INSTANT_PERCENT = 40;
    uint public constant PERCENT_DENOMINATOR = 100;

    IERC20 public immutable fred;
    uint public vestingStartDate;
    uint public totalVested;
    uint public totalWithdrawn;

    struct Vestment {
        uint total;
        uint withdrawn;
    }

    mapping(address => Vestment) public vestments;

    event VestmentsAdded(address[] addresses, uint[] amounts);
    event VestingStarted();
    event Claimed(address user, uint amount);

    modifier onlyBeforeStart() {
        require(!_hasVestingStarted(), "FREDVesting: Vesting has already started");
        _;
    }

    modifier onlyAfterStart() {
        require(_hasVestingStarted(), "FREDVesting: Vesting has not started yet");
        _;
    }

    /// @param _fred FRED token address
    constructor(address _fred) Ownable() {
        require(_fred != address(0), "FREDVesting: _fred must not equal the zero address");
        fred = IERC20(_fred);
    }

    /// @notice Import vestments, indexes of both parameters must correspond with one another (Owner)
    /// @param _addresses Wallet addresses
    /// @param _amounts Amounts
    function importVestments(address[] calldata _addresses, uint[] calldata _amounts) external onlyOwner onlyBeforeStart {
        require(_addresses.length == _amounts.length, "FREDVesting: _addresses and _amounts must have matching lengths");
        uint total;
        for (uint i; i < _addresses.length; i++) {
            vestments[_addresses[i]] = Vestment(
                _amounts[i],
                0
            );
            total += _amounts[i];
        }
        totalVested += total;
        emit VestmentsAdded(_addresses, _amounts);
    }

    /// @notice Start the vesting period which disables importing vestments and transfers required amount of FRED (Owner)
    function startVesting() external onlyOwner onlyBeforeStart {
        require(totalVested > 0, "FREDVesting: No vestments have been added");
        vestingStartDate = block.timestamp;
        fred.safeTransferFrom(_msgSender(), address(this), totalVested);
        emit VestingStarted();
    }

    /// @notice Claim vested tokens
    function claim() external nonReentrant onlyAfterStart {
        Vestment storage vestment = vestments[_msgSender()];
        require(vestment.total > 0, "FREDVesting: Nothing to claim");
        require(vestment.withdrawn < vestment.total, "FREDVesting: Already withdrawn full amount");
        uint amount = _claimableAmount(vestment);
        vestment.withdrawn += amount;
        totalWithdrawn += amount;
        fred.safeTransfer(_msgSender(), amount);
        emit Claimed(_msgSender(), amount);
    }

    /// @notice Available claim amount
    /// @param _address Wallet address
    /// @return amount Amount available
    function availableToClaim(address _address) external view onlyAfterStart returns (uint amount) {
        require(_address != address(0), "FREDVesting: _address must not equal the zero address");
        Vestment memory vestment = vestments[_address];
        if (vestment.total > 0 && vestment.withdrawn < vestment.total) {
            amount = _claimableAmount(vestment);
        }
        return amount;
    }

    /// @dev Calculate the amount to claim for a given vestment
    /// @param _vestment Vestment
    function _claimableAmount(Vestment memory _vestment) internal view returns (uint amount) {
        uint endDate = vestingStartDate + VESTING_PERIOD;
        if (block.timestamp >= endDate) {
            amount = _vestment.total;
        } else {
            uint timePassed = block.timestamp - vestingStartDate;
            uint instantClaim = _vestment.total * INSTANT_PERCENT / PERCENT_DENOMINATOR;
            uint vested = _vestment.total - instantClaim;
            uint available = (vested * timePassed / VESTING_PERIOD);
            amount = instantClaim + available;
        }
        amount -= _vestment.withdrawn;
    }

    /// @dev Has vesting started
    /// @return bool True - Vesting has started, False - Vesting has not started
    function _hasVestingStarted() internal view returns (bool) {
        return vestingStartDate > 0;
    }
}