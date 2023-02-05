// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock is Ownable {

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;

    // The timestamp of the block where the contract was deployed
    uint256 private immutable _creationTime;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_
    ) {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        _creationTime = block.timestamp;
    }

    /**
     * @dev Returns the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @dev Returns the beneficiary that will receive the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return (unlocked())?(_beneficiary):(owner());
    }

    /**
     * @dev Returns the beneficiary that will receive the tokens after expiration.
     */
    function beneficiaryAfterExpiration() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Returns the timestamp when the contract was deployed.
     */
    function creationTime() public view virtual returns (uint256) {
        return _creationTime;
    }

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Check wheter the timelock is unlocked.
     */
    function unlocked() public view virtual returns (bool) {
        return block.timestamp >= _releaseTime;
    }

    /**
     * @dev Time left in seconds
     */
    function timeLeft() public view virtual returns (uint256) {
        return (_releaseTime > block.timestamp)?(_releaseTime - block.timestamp):(0);
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        require(unlocked() || (_msgSender() == owner()), "TokenTimelock: current time is before release time");
        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");
        token().transfer(beneficiary(), amount);
    }
}