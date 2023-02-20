// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

contract VestingWalletOMN is Context {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 internal _maxRelease;
    mapping(address => uint256) private _erc20Released;
    address internal _beneficiary;
    address internal _vestToken;

    uint256 internal _startTime;
    uint256 internal _duration;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        uint256 startTimeVesting,
        uint256 durationVesting,
        uint256 maxRelease,
        address vestToken
    ) {
        require(
            beneficiaryAddress != address(0),
            "VestingWallet: beneficiary is zero address"
        );
        _beneficiary = beneficiaryAddress;

        require(startTimeVesting > now(), "VestingWallet: start invalid");
        _duration = durationVesting;
        _startTime = startTimeVesting;

        _maxRelease = maxRelease;

        _vestToken = vestToken;
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _startTime;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of eth already released
     */
    function released() public view virtual returns (uint256) {
        return _erc20Released[_vestToken];
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    function maxRelease() public view virtual returns (uint256) {
        return _maxRelease;
    }

    function remainingRelease() public view virtual returns (uint256) {
        return IERC20(_vestToken).balanceOf(address(this));
    }

    /**
    * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(address token) public view virtual returns (uint256) {
        return vestedAmount(token, uint64(now())) - released(token);
    }


    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release() public virtual {
        uint256 _releasable = releasable(_vestToken);
        _erc20Released[_vestToken] += _releasable;
        emit ERC20Released(_vestToken, _releasable);
        SafeERC20.safeTransfer(IERC20(_vestToken), beneficiary(), _releasable);
    }


    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }

    function now() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}