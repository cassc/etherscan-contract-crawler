// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title US+ Token Contract
/// @author Fluent Group - Development team
/// @notice Stable coin backed in USD Dolars
/// @dev This is a standard ERC20 with Pause, Mint and Access Control features
/// @notice  In order to implement governance in the federation and security to the user
/// the burn and burnfrom functions had been overrided to require a BURNER_ROLE
/// no other modification has been made.
contract USPlus is
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    int public constant Version = 3;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); //The role assigned to the USPlusMinter
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); //The role assigned to the USPlusBurner

    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE");

    function initialize() public initializer {
        __ERC20_init("USPLUS", "US+");
        AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice returns the default US+ decimal places
    /// @return uint8 that represents the decimals
    function decimals() public pure override(ERC20Upgradeable) returns (uint8) {
        return 6;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice access control applied. The address that has a BURNER_ROLE can burn tokens equivalent to its balanceOf
    function burn(
        uint256 amount
    ) public virtual override onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), amount);
    }

    /// @notice access control applied. The address that has a BURNER_ROLE can burn tokens of any address
    /// as long as such address grants allowance to an address granted with a BURNER_ROLE
    function burnFrom(
        address account,
        uint256 amount
    ) public virtual override onlyRole(BURNER_ROLE) {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    /// @notice Mints the amount of US+ defined in the ticket
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function mint(
        address to,
        uint amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused returns (bool) {
        _mint(to, amount);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE) {
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(erc20Addr),
            to,
            amount
        );
    }
}