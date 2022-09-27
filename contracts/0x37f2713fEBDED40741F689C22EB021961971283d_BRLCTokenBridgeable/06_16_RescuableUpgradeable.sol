// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title RescuableUpgradeable base contract
 * @dev Allows to rescue ERC20 tokens locked up in the contract using the `rescuer` role.
 *
 * This contract is used through inheritance. It introduces the `rescuer` role that is allowed to
 * rescue tokens locked up in the contract that is inherited from this one.
 *
 * By default, the rescuer is to the zero address. This can later be changed
 * by the contract owner with the {setRescuer} function.
 */
abstract contract RescuableUpgradeable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The address of the rescuer.
    address private _rescuer;

    // -------------------- Events -----------------------------------

    /// @dev Emitted when the rescuer is changed.
    event RescuerChanged(address indexed newRescuer);

    // -------------------- Errors -----------------------------------

    /// @dev The transaction sender is not a rescuer.
    error UnauthorizedRescuer(address account);

    // -------------------- Functions --------------------------------

    function __Rescuable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();

        __Rescuable_init_unchained();
    }

    function __Rescuable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Reverts if called by any account other than the rescuer.
     */
    modifier onlyRescuer() {
        if (_msgSender() != _rescuer) {
            revert UnauthorizedRescuer(_msgSender());
        }
        _;
    }

    /**
     * @dev Returns the rescuer address.
     */
    function rescuer() public view virtual returns (address) {
        return _rescuer;
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
     * @dev Rescues ERC20 tokens locked up in this contract.
     *
     * Requirements:
     *
     * - Can only be called by the rescuer.
     *
     * @param token The address of the ERC20 token.
     * @param to The address of the tokens recipient.
     * @param amount The amount of tokens to transfer.
     */
    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyRescuer {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }
}