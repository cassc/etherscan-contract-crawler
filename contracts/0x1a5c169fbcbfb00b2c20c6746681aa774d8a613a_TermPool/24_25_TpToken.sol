// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {ITpToken} from './interfaces/ITpToken.sol';

/// @notice Contract for TpToken, that represents the right to receive the interest of certain term of the TermPool
contract TpToken is ITpToken, ERC20Upgradeable {
  /// @notice Term pool address
  address public termPool;

  /// @notice Decimals of the token
  uint8 private __decimals;

  /// @notice Modifier that allows only term pool to call the function
  modifier onlyTermPool() {
    if (msg.sender == termPool) _;
    else revert NotTermPool(msg.sender);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the upgradeable contract
  /// @param _name Name of the token
  /// @param _symbol Symbol of the token
  /// @param _decimals Decimals of the token
  function __TpToken_init(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) external initializer {
    __ERC20_init(_name, _symbol);
    termPool = msg.sender;
    __decimals = _decimals;
  }

  /// @notice Returns the amount of token smallest unit
  function decimals()
    public
    view
    virtual
    override(ERC20Upgradeable, IERC20MetadataUpgradeable)
    returns (uint8)
  {
    return __decimals;
  }

  /// @notice Mints the tokens according to provided cpToken amount
  function mint(address to, uint256 _amount) external override onlyTermPool {
    _mint(to, _amount);
  }

  /// @notice Burns the tokens according to provided cpToken amount
  function burn(address from, uint256 _amount) external override onlyTermPool {
    _burn(from, _amount);
  }
}