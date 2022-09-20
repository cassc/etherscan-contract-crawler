// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ITokenController.sol";
import "./IControlledToken.sol";

/// @title Controlled ERC20 Token
/// @notice ERC20 Tokens with a controller for minting & burning
contract ControlledToken is ERC20, IControlledToken {

  /// @notice Interface to the contract responsible for controlling mint/burn
  ITokenController public override controller;

  /// @notice See {ERC20-decimals}
  uint8 private immutable DECIMALS; 


  /// @notice Initializes the Controlled Token with Token Details and the Controller
  /// @param _name The name of the Token
  /// @param _symbol The symbol for the Token
  /// @param _decimals The decimals for the Token
  /// @param _controller Address of the Controller contract for minting & burning
  constructor(string memory _name, string memory _symbol, uint8 _decimals, ITokenController _controller) 
    ERC20(_name, _symbol)
  {
    controller = _controller;
    DECIMALS = _decimals;
  }

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param _user Address of the receiver of the minted tokens
  /// @param _amount Amount of tokens to mint
  function controllerMint(address _user, uint256 _amount) external virtual override onlyController {
    _mint(_user, _amount);
  }

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurn(address _user, uint256 _amount) external virtual override onlyController {
    _burn(_user, _amount);
  }

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurnFrom(address, address _user, uint256 _amount) external virtual override onlyController {
    _burn(_user, _amount);
  }

  /// @dev Function modifier to ensure that the caller is the controller contract
  modifier onlyController {
    require(_msgSender() == address(controller), "ControlledToken/only-controller");
    _;
  }

  /// @dev Controller hook to provide notifications & rule validations on token transfers to the controller.
  /// This includes minting and burning.
  /// May be overridden to provide more granular control over operator-burning
  /// @param from Address of the account sending the tokens (address(0x0) on minting)
  /// @param to Address of the account receiving the tokens (address(0x0) on burning)
  /// @param amount Amount of tokens being transferred
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    controller.beforeTokenTransfer(from, to, amount);
  }

  /// @notice See {ERC20-decimals}
  function decimals() public override view returns (uint8) {
    return DECIMALS;
  } 
}