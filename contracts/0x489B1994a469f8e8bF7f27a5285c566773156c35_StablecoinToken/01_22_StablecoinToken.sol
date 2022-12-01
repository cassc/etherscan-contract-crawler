// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title StablecoinToken
/// @author Bluejay Core Team
/// @notice StablecoinToken is the contract for stablecoins minted by the protocol
/// @dev The token can be upgraded to support additional features
contract StablecoinToken is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  AccessControlUpgradeable,
  ERC20PermitUpgradeable,
  UUPSUpgradeable
{
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

  /// @notice Initializer for the contract
  /// @param name Name of the token
  /// @param symbol Symbol of the token
  function initialize(string memory name, string memory symbol)
    public
    initializer
  {
    __ERC20_init(name, symbol);
    __ERC20Burnable_init();
    __AccessControl_init();
    __ERC20Permit_init(name);
    __UUPSUpgradeable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Mint stablecoin tokens to an address. Minter must have MINTER_ROLE.
  /// @dev MINTER_ROLE should only be granted to StablecoinEngine
  /// @param to Address to receive the stablecoin token
  /// @param amount Amount of stablecoin tokens to mint, in WAD
  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  /// @notice Internal function to check that upgrader of contract has UPGRADER_ROLE
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(UPGRADER_ROLE)
  {}
}