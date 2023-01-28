// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title RescuableUpgradeable base contract
 * @author CloudWalk Inc.
 * @dev Allows to rescue ERC20 tokens locked up in the contract using the `rescuer` account.
 *
 * This contract is used through inheritance. It introduces the `rescuer` role that is allowed to
 * rescue tokens locked up in the contract that is inherited from this one.
 */
abstract contract RescuableUpgradeable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The address of the rescuer that is allowed to rescue tokens locked up in the contract.
    address private _rescuer;

    // -------------------- Events -----------------------------------

    /// @dev Emitted when the rescuer is changed.
    event RescuerChanged(address indexed newRescuer);

    // -------------------- Errors -----------------------------------

    /// @dev The message sender is not a rescuer.
    error UnauthorizedRescuer(address account);

    // -------------------- Modifiers --------------------------------

    /**
     * @dev Throws if called by any account other than the rescuer.
     */
    modifier onlyRescuer() {
        if (_msgSender() != _rescuer) {
            revert UnauthorizedRescuer(_msgSender());
        }
        _;
    }

    // -------------------- Functions --------------------------------

    /**
     * @dev The internal initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     */
    function __Rescuable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();

        __Rescuable_init_unchained();
    }

    /**
     * @dev The unchained internal initializer of the upgradable contract.
     *
     * See {RescuableUpgradeable-__Rescuable_init}.
     */
    function __Rescuable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Withdraws ERC20 tokens locked up in the contract.
     *
     * Requirements:
     *
     * - Can only be called by the rescuer account.
     *
     * @param token The address of the ERC20 token contract.
     * @param to The address of the recipient of tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyRescuer {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }

    /**
     * @dev Updates the rescuer address.
     *
     * Requirements:
     *
     * - Can only be called by the contract owner.
     *
     * Emits a {RescuerChanged} event.
     *
     * @param newRescuer The address of a new rescuer.
     */
    function setRescuer(address newRescuer) external onlyOwner {
        if (_rescuer == newRescuer) {
            return;
        }

        _rescuer = newRescuer;

        emit RescuerChanged(newRescuer);
    }

    /**
     * @dev Returns the rescuer address.
     */
    function rescuer() public view virtual returns (address) {
        return _rescuer;
    }
}