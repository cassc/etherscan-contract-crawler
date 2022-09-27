// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title RescueControlUpgradeable base contract
 * @dev Allows to rescue tokens locked up in the contract by transferring to a specified address.
 *
 * This contract is used through inheritance. It introduces the {RESCUER_ROLE} role that is allowed to
 * rescue tokens locked up in the contract that is inherited from this one.
 *
 * The admins of the {RESCUER_ROLE} roles are accounts with the role defined in the init() function.
 */
abstract contract RescueControlUpgradeable is AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The role of rescuer that is allowed to rescue tokens locked up in the contract.
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");

    // ------------------- Functions ---------------------------------

    function __RescueControl_init(bytes32 rescuerRoleAdmin) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();

        __RescueControl_init_unchained(rescuerRoleAdmin);
    }

    function __RescueControl_init_unchained(bytes32 rescuerRoleAdmin) internal onlyInitializing {
        _setRoleAdmin(RESCUER_ROLE, rescuerRoleAdmin);
    }

    /**
     * @dev Rescue ERC20 tokens locked up in this contract.
     *
     * Requirements:
     *
     * - The caller must have the {RESCUER_ROLE} role.
     *
     * @param tokenContract The ERC20 token contract address.
     * @param to The recipient address.
     * @param amount The amount to withdraw.
     */
    function rescueERC20(
        IERC20Upgradeable tokenContract,
        address to,
        uint256 amount
    ) external onlyRole(RESCUER_ROLE) {
        tokenContract.safeTransfer(to, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;
}