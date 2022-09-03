// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (contracts/UnsIcoVestingWallet.sol)
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title UnsIcoVestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract UnsIcoVestingWallet is AccessControl {
    bytes32 public constant ICO_VESTING_ROLE = keccak256("ICO_VESTING_ROLE");

    mapping(address => uint256) private _unsVested;
    mapping(address => uint256) private _unsReleased;
    uint64 private _start = 1688515200; //Jul 5, 2023
    uint64 private _duration = 489 * 60 * 60 * 24; // Nov 5, 2024
    address private _unsToken;

    event UnsReleased(address indexed token, uint256 amount);
    event UnsVested(address indexed account, uint256 amount);

    /**
     * @dev Set the unsToken of the vesting wallet.
     * @dev Set the icoAddress of the vesting wallet.
     */
    constructor(
        address unsTokenAddress,
        address icoAddress
    ) {
        _unsToken = unsTokenAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ICO_VESTING_ROLE, icoAddress);
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Getter for the unsToken.
     */
    function unsToken() public view virtual returns (address) {
        return _unsToken;
    }

    /**
     * @dev Amount of token already released
     */
    function released(address account) public view virtual returns (uint256) {
        return _unsReleased[account];
    }

    /**
     * @dev Amount of uns vested on account
     */
    function unsVested(address account) public view virtual returns (uint256) {
        return _unsVested[account];
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {UnsReleased} event.
     */
    function release(address account) public virtual {
        uint256 releasable = vestedAmount(account, uint64(block.timestamp)) - released(account);
        require (releasable > 0 , "Zero releasable");
        _unsReleased[account] += releasable;
        emit UnsReleased(account, releasable);
        SafeERC20.safeTransfer(IERC20(_unsToken), account, releasable);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address account, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(unsVested(account), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }

    /**
     * @dev Create Vesting  for account
     */
    function createVesting(
        address account, 
        uint256 amount
    ) external onlyRole(ICO_VESTING_ROLE) returns (bool) {
        _unsVested[account] += amount;
        emit UnsVested(account, amount);
        return true;
    }

}