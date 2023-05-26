//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SafeMath.sol";

/**
 * Default vesting contract
 * vesting schedules can be added and revoked
 * vesting schedule has start time, initial release, vesting period and cliff
 */
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeMath128 for uint128;
    using SafeMath64 for uint64;
    using SafeMath32 for uint32;
    using SafeERC20 for IERC20;

    /**
     * @notice Vesting Schedule per Payee
     * @dev uses total uint512 (2 slots x uint256)
     */
    struct VestingSchedule {
        // total vested amount
        uint128 amount;
        // total claimed amount
        uint128 claimed;
        // vesting start time
        // Using uint32 should be good enough until '2106-02-07T06:28:15+00:00'
        uint64 startTime;
        // total vesting period e.g 2 years
        uint32 vestingPeriod;
        // cliff period e.g 180 days
        // 10 years   = 315360000
        // uint32.max = 4294967295
        uint32 cliff;
        // initial release amount after start, before cliff
        uint128 initialRelease;
    }

    IERC20 private immutable _token;

    // total allocation amount for vesting
    uint256 private _totalAlloc;

    // total claimed amount from payees
    uint256 private _totalClaimed;

    bool private _claimAllowed;

    mapping(address => VestingSchedule) private _vestingSchedules;

    event VestingAdded(address payee, uint256 amount);
    event TokensClaimed(address payee, uint256 amount);
    event VestingRevoked(address payee);

    constructor(address token) {
        _token = IERC20(token);

        _claimAllowed = false;
    }

    /**
     * @notice get vesting schedule by payee
     * @param _payee address of payee
     * @return amount total vesting amount
     * @return startTime vesting start time
     * @return vestingPeriod vesting period
     * @return cliff cliff period
     * @return initialRelease initial release amount
     */
    function vestingSchedule(address _payee)
        public
        view
        returns (
            uint128,
            uint128,
            uint64,
            uint32,
            uint32,
            uint128
        )
    {
        VestingSchedule memory v = _vestingSchedules[_payee];

        return (v.amount, v.claimed, v.startTime, v.vestingPeriod, v.cliff, v.initialRelease);
    }

    /**
     * @return total vesting allocation
     */
    function totalAlloc() public view returns (uint256) {
        return _totalAlloc;
    }

    /**
     * @return total claimed amount
     */
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }

    /**
     * @return claim is allowed or not
     */
    function claimAllowed() public view returns (bool) {
        return _claimAllowed;
    }

    /**
     * @notice set claim allowed status
     * @param allowed bool value to set _claimAllowed
     */
    function setClaimAllowed(bool allowed) external onlyOwner {
        _claimAllowed = allowed;
    }

    /**
     * @notice add vesting schedules from array inputs
     * @param _payees array of payee addresses
     * @param _amounts array of total vesting amounts
     * @param _startTimes array of vesting start times
     * @param _vestingPeriods array of vesting periods
     * @param _cliffs array of cliff periods
     * @param _initialReleases array of initial release amounts
     */
    function addVestingSchedules(
        address[] calldata _payees,
        uint256[] calldata _amounts,
        uint64[] calldata _startTimes,
        uint32[] calldata _vestingPeriods,
        uint32[] calldata _cliffs,
        uint128[] calldata _initialReleases
    ) external onlyOwner {
        require(_payees.length == _amounts.length, "TokenVesting: payees and amounts length mismatch");
        require(_payees.length == _startTimes.length, "TokenVesting: payees and startTimes length mismatch");
        require(_payees.length == _vestingPeriods.length, "TokenVesting: payees and vestingPeriods length mismatch");
        require(_payees.length == _cliffs.length, "TokenVesting: payees and cliffs length mismatch");
        require(_payees.length == _initialReleases.length, "TokenVesting: payees and initialReleases length mismatch");

        for (uint256 i = 0; i < _payees.length; i++) {
            _addVestingSchedule(
                _payees[i],
                _amounts[i],
                _startTimes[i],
                _vestingPeriods[i],
                _cliffs[i],
                _initialReleases[i]
            );
        }
    }

    /**
     * @notice add vesting schedule
     * @param _payee payee addresse
     * @param _amount total vesting amount
     * @param _startTime vesting start time
     * @param _vestingPeriod vesting period
     * @param _cliff cliff period
     * @param _initialRelease initial release amount
     */
    function _addVestingSchedule(
        address _payee,
        uint256 _amount,
        uint64 _startTime,
        uint32 _vestingPeriod,
        uint32 _cliff,
        uint128 _initialRelease
    ) private {
        require(_payee != address(0), "TokenVesting: payee is the zero address");
        require(_amount > 0, "TokenVesting: amount is 0");
        require(_vestingSchedules[_payee].amount == 0, "TokenVesting: payee already has a vesting schedule");
        require(_vestingPeriod > 0, "TokenVesting: total period is 0");
        require(_cliff <= _vestingPeriod, "TokenVesting: vestingPeriod is less than cliff");
        require(_initialRelease < _amount, "TokenVesting: initial release is larger than total alloc");
        require(
            _initialRelease < (_amount * _cliff) / _vestingPeriod,
            "TokenVesting: initial release is larger than cliff alloc"
        );

        _vestingSchedules[_payee] = VestingSchedule({
            amount: _amount.to128(),
            claimed: 0,
            startTime: _startTime,
            vestingPeriod: _vestingPeriod,
            cliff: _cliff,
            initialRelease: _initialRelease
        });

        _totalAlloc = _totalAlloc.add(_amount);

        emit VestingAdded(_payee, _amount);
    }

    /**
     * @notice revoke vesting schedule
     * @param _payee payee addresse
     */
    function revokeVestingSchedule(address _payee) external onlyOwner {
        VestingSchedule memory v = _vestingSchedules[_payee];

        require(v.amount > 0, "TokenVesting: payee does not exist");

        uint256 remainingAmount = v.amount.sub(v.claimed);
        _totalAlloc = _totalAlloc.sub(remainingAmount);

        delete _vestingSchedules[_payee];

        emit VestingRevoked(_payee);
    }

    /**
     * @notice claim available vested funds
     * @param _amount token amount to claim from vested amounts
     */
    function claim(uint256 _amount) external {
        require(_claimAllowed == true, "TokenVesting: claim is disabled");
        require(_amount <= _token.balanceOf(address(this)), "TokenVesting: contract does not have enough funds");

        address payee = msg.sender;
        VestingSchedule storage v = _vestingSchedules[payee];

        require(v.amount > 0, "TokenVesting: not vested address");

        uint256 claimableTokens = claimableAmount(payee);

        require(claimableTokens > 0, "TokenVesting: no vested funds");

        require(_amount <= claimableTokens, "TokenVesting: cannot claim larger than total vested amount");

        v.claimed = v.claimed.add(_amount.to128());
        _totalClaimed = _totalClaimed.add(_amount);

        // transfer vested token to payee
        _token.safeTransfer(payee, _amount);

        emit TokensClaimed(payee, _amount);
    }

    /**
     * @return available amount to claim
     * @param _payee address of payee
     */
    function claimableAmount(address _payee) public view returns (uint256) {
        VestingSchedule memory v = _vestingSchedules[_payee];

        // return 0 if vesting is not started
        if (block.timestamp < v.startTime) {
            return 0;
        }

        uint256 vestedPeriod = block.timestamp.sub(v.startTime);
        uint256 vestedAmount;

        // return initialRelease if vested period is less than the cliff
        if (vestedPeriod < v.cliff) {
            vestedAmount = v.initialRelease;
        } else if (vestedPeriod > v.vestingPeriod) {
            // return all remaining alloc amount if vested period exceeds total vesting period
            vestedAmount = v.amount;
        } else {
            // vestedAmount = totalAllocation * (vestedPeriod / totalVestingPeriod)
            vestedAmount = (v.amount * vestedPeriod) / v.vestingPeriod;
        }

        // if vested amount is less than claimed amount, return 0
        if (vestedAmount < v.claimed) {
            return 0;
        }

        // return claimable amount
        return vestedAmount.sub(v.claimed);
    }

    /**
     * @notice withdraw amount of token from vesting contract to owner
     * @param _amount token amount to withdraw from contract
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount < _token.balanceOf(address(this)), "TokenVesting: withdraw amount larger than balance");

        _token.safeTransfer(owner(), _amount);
    }

    /**
     * @notice withdraw all token from vesting contract to owner
     */
    function withdrawAll() external onlyOwner {
        _token.safeTransfer(owner(), _token.balanceOf(address(this)));
    }
}