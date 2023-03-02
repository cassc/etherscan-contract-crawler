// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {VestingVault} from "./VestingVault.sol";

/**
 * @notice Generic VestingVault contract allowing for an admin to claw back unvested funds
 */
abstract contract ClawbackVestingVault is VestingVault, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Clawback(uint256 amount);

    uint256 public clawbackTimestamp;

    /**
     * @notice Initializes the vesting vault
     * @param amount The amount of the ERC20 token to vest for the beneficiary in total
     * @param admin The address which can clawback unvested tokens
     * @dev this contract should have been deployed with ClonesWithImmutableArgs in order to
     * properly set up the immutable token and beneficiary args
     */
    function initialize(uint256 amount, address admin)
        internal
        onlyInitializing
    {
        __Ownable_init_unchained();
        _transferOwnership(admin);
        VestingVault.initialize(amount);
    }

    /**
     * @notice return all unvested tokens to the admin
     */
    function clawback() public virtual onlyOwner {
        clawbackTimestamp = block.timestamp;
        uint256 amount = unvested();
        token().safeTransfer(msg.sender, amount);
        emit Clawback(amount);
    }

    /**
     * @inheritdoc VestingVault
     */
    function vested() public view virtual override returns (uint256) {
        uint256 _clawbackTimestamp = clawbackTimestamp;
        if (_clawbackTimestamp != 0) {
            return vestedOn(_clawbackTimestamp);
        } else {
            return vestedOn(block.timestamp);
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner The address to transfer ownership to
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }
}