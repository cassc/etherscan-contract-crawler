// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../ConcentratorConvexVault.sol";
import "../interfaces/IAladdinCompounder.sol";
import "../../interfaces/ICurveCryptoPool.sol";
import "../../interfaces/IZap.sol";

contract AladdinFXSConvexVault is ConcentratorConvexVault {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when the zap contract is updated.
  /// @param _zap The address of the zap contract.
  event UpdateZap(address indexed _zap);

  /// @dev The address of Curve cvxfxs pool.
  address private constant CURVE_CVXFXS_POOL = 0xd658A338613198204DCa1143Ac3F01A722b5d94A;

  /// @dev The address of Curve cvxfxs pool token.
  address private constant CURVE_CVXFXS_TOKEN = 0xF3A43307DcAFa93275993862Aae628fCB50dC768;

  /// @dev The address of FXS token.
  address private constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

  /// @dev The address of cvxFXS token.
  // solhint-disable-next-line const-name-snakecase
  address private constant cvxFXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

  /// @notice The address of AladdinFXS token.
  address public aladdinFXS;

  /// @notice The address of ZAP contract, will be used to swap tokens.
  address public zap;

  function initialize(
    address _aladdinFXS,
    address _zap,
    address _platform
  ) external initializer {
    ConcentratorConvexVault._initialize(_platform);

    require(_aladdinFXS != address(0), "zero aFXS address");
    require(_zap != address(0), "zero zap address");

    aladdinFXS = _aladdinFXS;
    zap = _zap;

    IERC20Upgradeable(CURVE_CVXFXS_TOKEN).safeApprove(_aladdinFXS, uint256(-1));
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IConcentratorConvexVault
  function rewardToken() public view virtual override returns (address) {
    return aladdinFXS;
  }

  /********************************** Restricted Functions **********************************/

  /// @dev Update the zap contract
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc ConcentratorConvexVault
  function _claim(
    uint256 _amount,
    uint256 _minOut,
    address _recipient,
    address _claimAsToken
  ) internal virtual override returns (uint256) {
    address _aladdinFXS = aladdinFXS;
    uint256 _amountOut;
    if (_claimAsToken == _aladdinFXS) {
      _amountOut = _amount;
    } else {
      _amountOut = IAladdinCompounder(_aladdinFXS).redeem(_amount, address(this), address(this));
      if (_claimAsToken != CURVE_CVXFXS_TOKEN) {
        address _zap = zap;
        IERC20Upgradeable(CURVE_CVXFXS_TOKEN).safeTransfer(_zap, _amountOut);
        _amountOut = IZap(_zap).zap(CURVE_CVXFXS_TOKEN, _amountOut, _claimAsToken, 0);
      }
    }

    require(_amountOut >= _minOut, "insufficient rewards");

    if (_claimAsToken == address(0)) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool _success, ) = msg.sender.call{ value: _amount }("");
      require(_success, "transfer ETH failed");
    } else {
      IERC20Upgradeable(_claimAsToken).safeTransfer(_recipient, _amountOut);
    }

    return _amountOut;
  }

  /// @inheritdoc ConcentratorConvexVault
  function _zapAsRewardToken(address[] memory _tokens, uint256[] memory _amounts)
    internal
    virtual
    override
    returns (uint256)
  {
    // 1. zap as FXS
    address _zap = zap;
    uint256 _amountFXS;
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_tokens[i] == FXS) {
        _amountFXS = _amountFXS.add(_amounts[i]);
      } else if (_amounts[i] > 0) {
        IERC20Upgradeable(_tokens[i]).safeTransfer(_zap, _amounts[i]);
        _amountFXS = _amountFXS.add(IZap(_zap).zap(_tokens[i], _amounts[i], FXS, 0));
      }
    }

    // 2. add liquidity as FXS/cvxFXS LP
    uint256 _amountLP;
    if (_amountFXS > 0) {
      uint256[2] memory _inputs;
      _inputs[0] = _amountFXS;
      IERC20Upgradeable(FXS).safeApprove(CURVE_CVXFXS_POOL, 0);
      IERC20Upgradeable(FXS).safeApprove(CURVE_CVXFXS_POOL, uint256(-1));
      _amountLP = ICurveCryptoPool(CURVE_CVXFXS_POOL).add_liquidity(_inputs, 0);
    }

    // 3. deposit as aladdinFXS
    if (_amountLP > 0) {
      return IAladdinCompounder(aladdinFXS).deposit(_amountLP, address(this));
    } else {
      return 0;
    }
  }
}