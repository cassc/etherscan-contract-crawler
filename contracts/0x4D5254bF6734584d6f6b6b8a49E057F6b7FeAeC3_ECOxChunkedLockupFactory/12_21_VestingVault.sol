// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {IVestingVault} from "./interfaces/IVestingVault.sol";

/**
 * @notice Generic VestingVault contract which handles storage and claiming of vesting tokens
 * @dev This contract is meant to be extended with handling for vesting schedules
 * @dev immutable args:
 * - slot 0 - address token (20 bytes)
 * - slot 1 - address beneficiary (20 bytes)
 */
abstract contract VestingVault is
    Clone,
    ReentrancyGuardUpgradeable,
    IVestingVault
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @inheritdoc IVestingVault
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the token which is being vested
     */
    function token() public pure returns (IERC20Upgradeable) {
        return IERC20Upgradeable(_getArgAddress(0));
    }

    /**
     * @inheritdoc IVestingVault
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The beneficiary address
     */
    function beneficiary() public pure returns (address) {
        return _getArgAddress(20);
    }

    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary()) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * @notice Initializes the vesting vault
     * @param amount The amount of the ERC20 token to vest for the beneficiary in total
     * @dev this contract should have been deployed with ClonesWithImmutableArgs in order to
     * properly set up the immutable token and beneficiary args
     */
    function initialize(uint256 amount) internal virtual onlyInitializing {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        if (address(token()) == address(0)) {
            revert InvalidParams();
        }
        if (beneficiary() == address(0)) {
            revert InvalidParams();
        }

        IERC20Upgradeable(token()).safeTransferFrom(
            msg.sender, address(this), amount
        );
    }

    /**
     * @inheritdoc IVestingVault
     */
    function claim() external nonReentrant onlyBeneficiary {
        uint256 vestedAmount = vested();
        if (vestedAmount == 0) {
            revert NotVested();
        }

        onClaim(vestedAmount);
        token().safeTransfer(beneficiary(), vestedAmount);
        emit Claimed(beneficiary(), address(token()), vestedAmount);
    }

    /**
     * @inheritdoc IVestingVault
     */
    function vested() public view virtual returns (uint256) {
        return vestedOn(block.timestamp);
    }

    /**
     * @inheritdoc IVestingVault
     */
    function unvested() public view virtual returns (uint256) {
        return token().balanceOf(address(this)) - vested();
    }

    /**
     * @inheritdoc IVestingVault
     */
    function vestedOn(uint256 timestamp)
        public
        view
        virtual
        returns (uint256);

    /**
     * @notice hook for downstream contracts to update vesting schedule based on a claim
     * @param amount The amount of token() which were claimed
     */
    function onClaim(uint256 amount) internal virtual;
}