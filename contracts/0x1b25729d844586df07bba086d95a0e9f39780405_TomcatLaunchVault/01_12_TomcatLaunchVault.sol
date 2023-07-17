pragma solidity 0.8.18;
// SPDX-License-Identifier: AGPL-3.0
// Tomcat (launch/TomcatLaunchVault.sol)

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ITcMav } from "contracts/interfaces/core/ITcMav.sol";
import { ITomcatLaunchLocker } from "contracts/interfaces/launch/ITomcatLaunchLocker.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/* solhint-disable not-rely-on-time */

/**
 * @title Tomcat Launch Vault 
 * 
 * @notice The Tomcat Finance Vault where users stake MAV and receive tcMAV 1:1 in return.
 * tcMAV is a liquid/tradeable receipt token.
 * 
 * Users can stake/unstake their MAV freely, until the vault closing time (prior to the veMAV 
 * incentive snapshot date).
 * 
 * Upon vault closing, Tomcat Finance will lock the MAV for veMAV and unstaking will no
 * longer be possible. (It will be possible to sell tcMAV on secondary markets)
 * 
 * Tomcat Launch Vault stakers will be eligable for future incentives:
 *   - Extra tcMAV, proportional from the total amount Tomcat was awarded from the Maverick incentives program
 *   - TOMCAT emissions, Tomcat Finance's governance token
 */
contract TomcatLaunchVault is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice The Maverick MAV governance token.
     */
    IERC20 public immutable mavToken;

    /**
     * @notice The Tomcat tcMAV liquid MAV wrapper token
     */
    ITcMav public immutable tcMavToken;

    /**
     * @notice The timestamp for when the launch vault closes.
     * @dev This can be extended by Tomcat Finance, in case the Maverick incentive program
     * date is pushed out.
     */
    uint256 public closingTimestamp;

    /**
     * @notice The Tomcat contract which will be called at vault closing time
     * to lock the MAV into veMAV.
     */
    ITomcatLaunchLocker public locker;

    event Stake(address indexed account, uint256 amount);
    event Unstake(address indexed account, uint256 amount);
    event ClosingTimestampExtended(uint256 timestamp);
    event LockerSet(address indexed locker);
    event MavLocked(uint256 amount);

    error VaultClosed();
    error VaultNotClosed();
    error InvalidAmount();
    error InvalidAddress();
    error LockerAlreadySet();

    constructor(address _mavToken, address _tcMavToken, uint256 _closingTimestamp) {
        mavToken = IERC20(_mavToken);
        tcMavToken = ITcMav(_tcMavToken);
        closingTimestamp = _closingTimestamp;
    }

    /**
     * @notice Users can stake MAV into the vault and will be minted
     * tcMAV 1:1
     * @param _amount The amount of MAV to stake
     */
    function stake(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        if (block.timestamp > closingTimestamp) revert VaultClosed();
        emit Stake(msg.sender, _amount);

        // Pull the MAV from the user
        mavToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Mint tcMAV to the user
        tcMavToken.mint(msg.sender, _amount);
    }

    /**
     * @notice Users may unstake their MAV 1:1, their
     * tcMAV will be burned.
     * @param _amount The amount of MAV to unstake
     */
    function unstake(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        if (block.timestamp > closingTimestamp) revert VaultClosed();
        emit Unstake(msg.sender, _amount);

        // Burn the tcMAV
        tcMavToken.burn(msg.sender, _amount);

        // Send the MAV back to the user
        mavToken.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice If the Maverick incentives program dates are extended,
     * Tomcat can extend the vault closing date so users can continue
     * staking/unstaking MAV
     */
    function extendClosingTimestamp(uint256 _timestamp) external onlyOwner {
        if (_timestamp <= closingTimestamp) revert InvalidAmount();
        emit ClosingTimestampExtended(_timestamp);
        closingTimestamp = _timestamp;
    }

    /**
     * @notice Tomcat will set the locker contract prior to the vault closing time
     * @dev It can only be set once.
     */
    function setLocker(address _locker) external onlyOwner {
        if (_locker == address(0)) revert InvalidAddress();
        if (address(locker) != address(0)) revert LockerAlreadySet();
        emit LockerSet(_locker);
        locker = ITomcatLaunchLocker(_locker);
    }

    /**
     * @notice After the vault closing time, Tomcat will call to
     * lock the MAV into veMAV
     */
    function lockMav() external onlyOwner {
        if (block.timestamp <= closingTimestamp) revert VaultNotClosed();
        if (address(locker) == address(0)) revert InvalidAddress();
        uint256 amount = mavToken.balanceOf(address(this));
        if (amount == 0) revert InvalidAmount();
        emit MavLocked(amount);

        mavToken.safeIncreaseAllowance(address(locker), amount);
        locker.lock(amount);
    }
}