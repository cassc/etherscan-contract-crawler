// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import { IFractionalToken } from "./interfaces/IFractionalToken.sol";
import { ILeveragedToken } from "./interfaces/ILeveragedToken.sol";
import { ITreasury } from "./interfaces/ITreasury.sol";

contract LeveragedToken is ERC20Upgradeable, ILeveragedToken {
  using SafeMathUpgradeable for uint256;

  /*************
   * Constants *
   *************/

  /// @dev The precision used to compute nav.
  uint256 private constant PRECISION = 1e18;

  /*************
   * Variables *
   *************/

  /// @notice The address of Treasury contract.
  address public treasury;

  /// @notice The address of corresponding FractionalToken.
  address public fToken;

  /*************
   * Modifiers *
   *************/

  modifier onlyTreasury() {
    require(msg.sender == treasury, "Only treasury");
    _;
  }

  /***************
   * Constructor *
   ***************/

  function initialize(
    address _treasury,
    address _fToken,
    string memory _name,
    string memory _symbol
  ) external initializer {
    ERC20Upgradeable.__ERC20_init(_name, _symbol);

    treasury = _treasury;
    fToken = _fToken;
  }

  /*************************
   * Public View Functions *
   *************************/

  /// @inheritdoc ILeveragedToken
  function nav() external view override returns (uint256) {
    ITreasury _treasury = ITreasury(treasury);
    address _fToken = fToken;

    uint256 _totalXToken = totalSupply();
    if (_totalXToken == 0) return PRECISION;

    uint256 _totalFToken = ERC20Upgradeable(_fToken).totalSupply();
    uint256 _navFToken = IFractionalToken(_fToken).nav();
    uint256 _totalBaseToken = _treasury.totalBaseToken();
    uint256 _price = _treasury.lastPermissionedPrice();

    return _totalBaseToken.mul(_price).sub(_totalFToken.mul(_navFToken)).div(_totalXToken);
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @inheritdoc ILeveragedToken
  function mint(address _to, uint256 _amount) external override onlyTreasury {
    _mint(_to, _amount);
  }

  /// @inheritdoc ILeveragedToken
  function burn(address _from, uint256 _amount) external override onlyTreasury {
    _burn(_from, _amount);
  }
}