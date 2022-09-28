// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./deposits/PaymentTransfersAdapter.sol";

contract PaymentLite is AccessControlUpgradeable, PausableUpgradeable, PaymentTransfersAdapter {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Upgradeable initializer of contract.
     * @param ownerAddress initial contract owner
     */
    function initialize(address ownerAddress, uint256) public virtual initializer {
        __PaymentLite_init(ownerAddress);
    }

    function __PaymentLite_init(address ownerAddress) internal onlyInitializing {
        __AccessControl_init();
        __Pausable_init();

        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setupRole(OWNER_ROLE, ownerAddress);

        // pause contract until entirely configured
        _pause();
    }

    /**
     * @notice Set the version of the implementation contract.
     * @dev Called when linking a new implementation to the proxy
     * contract at `upgradeToAndCall` using the hard-coded integer version.
     */
    function upgradeVersion() external reinitializer(1) {}

    /**
     * @notice Set the support-level for a payment token.
     * @param erc20 token address
     * @param state support-level to update to
     */
    function setCurrencySupport(IERC20Upgradeable erc20, CurrencySupport state) external onlyRole(OWNER_ROLE) {
        _setCurrencySupport(erc20, state);
    }

    /**
     * @notice Extract `amount` of `erc20` tokens from this contract and send them to `account`.
     * @param account destination of rescued tokens
     * @param erc20 token to transfer out
     * @param amount amount of tokens to rescue
     */
    function rescueTokens(
        address account,
        IERC20Upgradeable erc20,
        uint256 amount
    ) external onlyRole(OWNER_ROLE) {
        erc20.safeTransfer(account, amount);
    }

    /**
     * @notice Freeze contract: deny client deposits and node operations.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause contract.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Deposit `amount` of supported token `erc20` to increase owned platform funds.
     * @param erc20 currency token to use for payment operation
     * @param amount amount of tokens to deposit
     */
    function depositFunds(IERC20Upgradeable erc20, uint256 amount) external whenNotPaused {
        _deposit(_msgSender(), erc20, amount);
    }

    uint256[50] private __gap;
}