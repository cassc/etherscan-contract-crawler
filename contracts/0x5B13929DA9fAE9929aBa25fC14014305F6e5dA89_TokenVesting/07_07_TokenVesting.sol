// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev Token vesting contract for investors
 */
contract TokenVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address account, uint256 amount);
    event TokenVestingRevoked(address account);

    string public _name = "Private Sale (9 months, 30% unlock)";

    // vesting token
    IERC20 private token;

    // investors and allocated token amount
    address[] private _beneficiaries;
    mapping (address => uint256) private _allocated;
    mapping (address => uint256) private _initialRelease;

    // durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration = 270 days;

    // vesting is revocable or not
    bool private _revocable;

    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiaries addresses of the beneficiary to whom vested tokens are transferred
     * @param allocated tokens of the beneficiary to whom vested tokens are transferred
     * @param initialRelase percentage
     * @param __start the time (as Unix time) at which point vesting starts
     * @param __cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param __revocable whether the vesting is revocable or not
     */
    constructor (
        address _token,
        address[] memory beneficiaries,
        uint256[] memory allocated,
        uint256 initialRelase,
        uint256 __start,
        uint256 __cliffDuration,
        bool __revocable
    ) {
        require(_token != address(0), "TokenVesting: invalid token address");
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address investor = beneficiaries[i];
            // solhint-disable-next-line max-line-length
            require(investor != address(0), "TokenVesting: beneficiary is the zero address");
            _beneficiaries.push(investor);
            uint256 initial = allocated[i].mul(initialRelase).div(100);
            _initialRelease[investor] = initial;
            _allocated[investor] = allocated[i];
        }
        // solhint-disable-next-line max-line-length
        require(__cliffDuration <= _duration, "TokenVesting: cliff is longer than duration");
        require(_duration > 0, "TokenVesting: duration is 0");
        // solhint-disable-next-line max-line-length
        require(__start.add(_duration) > block.timestamp, "TokenVesting: final time is before current time");
        
        token = IERC20(_token);

        _cliff = __start.add(__cliffDuration);
        _start = __start;

        _revocable = __revocable;
    }

    /**
     * @notice Add investors.
     */
    function add(
        address[] memory beneficiaries,
        uint256[] memory allocated,
        uint256 initialRelase
    ) public onlyOwner {
        require(block.timestamp < _start.add(_duration), "TokenVesting: vesting is not active");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address investor = beneficiaries[i];
            // solhint-disable-next-line max-line-length
            require(investor != address(0), "TokenVesting: beneficiary is the zero address");
            _beneficiaries.push(investor);
            uint256 initial = allocated[i].mul(initialRelase).div(100);
            _initialRelease[investor] = initial;
            _allocated[investor] = allocated[i];
        }
    }

    /**
     * @return the name of vesting.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the allocation of investor.
     */
    function allocation(address investor) public view returns (uint256) {
        return _allocated[investor];
    }
    function releasable(address investor) public view returns (uint256) {
        return _releasableAmount(investor);
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function revocable() public view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address investor) public view returns (uint256) {
        return _released[investor];
    }

    /**
     * @return true if the token is revoked.
     */
    function revoked(address investor) public view returns (bool) {
        return _revoked[investor];
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = _releasableAmount(msg.sender);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[msg.sender] = _released[msg.sender].add(unreleased);

        token.safeTransfer(msg.sender, unreleased);

        emit TokensReleased(msg.sender, unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param _revoke address which is being vested
     */
    function revoke(address _revoke) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(!_revoked[_revoke], "TokenVesting: token already revoked");

        uint256 balance = _allocated[_revoke];
        require(balance > 0, "TokenVesting: no allocation");

        uint256 unreleased = _releasableAmount(_revoke);
        uint256 refund = balance.sub(unreleased);
        require(refund > 0, "TokenVesting: no refunds");

        _revoked[_revoke] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(_revoke);
    }

    /**
     * @notice Allows the owner to escape tokens.
     */
    function escape() public onlyOwner {
        require(block.timestamp >= _start.add(_duration), "TokenVesting: vesting is active");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = 0;
        
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            unreleased = unreleased.add(_releasableAmount(_beneficiaries[i]));
        }
        
        uint256 escapeAmount = balance.sub(unreleased);
        require(escapeAmount > 0, "TokenVesting: no escapable tokens");

        token.safeTransfer(owner(), escapeAmount);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param investor address which is being vested
     */
    function _releasableAmount(address investor) private view returns (uint256) {
        return _vestedAmount(investor).add(_initialRelease[investor]).sub(_released[investor]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param investor address which is being vested
     */
    function _vestedAmount(address investor) private view returns (uint256) {
        uint256 totalBalance = _allocated[investor].sub(_initialRelease[investor]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked[investor]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}