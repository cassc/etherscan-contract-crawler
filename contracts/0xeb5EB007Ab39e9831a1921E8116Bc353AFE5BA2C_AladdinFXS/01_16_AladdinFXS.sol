// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../AladdinCompounder.sol";
import "../../interfaces/IConvexBooster.sol";
import "../../interfaces/IConvexBasicRewards.sol";
import "../../interfaces/ICurveCryptoPool.sol";
import "../../interfaces/IZap.sol";

// solhint-disable no-empty-blocks

contract AladdinFXS is AladdinCompounder {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when the zap contract is updated.
  /// @param _zap The address of the zap contract.
  event UpdateZap(address _zap);

  /// @dev The address of Curve cvxfxs pool.
  address private constant CURVE_CVXFXS_POOL = 0xd658A338613198204DCa1143Ac3F01A722b5d94A;

  /// @dev The address of Curve cvxfxs pool token.
  address private constant CURVE_CVXFXS_TOKEN = 0xF3A43307DcAFa93275993862Aae628fCB50dC768;

  /// @dev The address of FXS token.
  address private constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

  /// @dev The address of cvxFXS token.
  // solhint-disable-next-line const-name-snakecase
  address private constant cvxFXS = 0xFEEf77d3f69374f66429C91d732A244f074bdf74;

  /// @dev The address of Convex Booster.
  address private constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

  /// @dev The pool id of cvxFXS-f pool in Convex Booster.
  uint256 private constant CURVE_CVXFXS_POOLID = 72;

  /// @dev The address of cvxFXS/FXS-f reward contract.
  address private constant CONVEX_REWARDER = 0xf27AFAD0142393e4b3E5510aBc5fe3743Ad669Cb;

  /// @dev The address of ZAP contract, will be used to swap tokens.
  address public zap;

  /// @notice The list of rewards token.
  address[] public rewards;

  function initialize(address _zap, address[] memory _rewards) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    ERC20Upgradeable.__ERC20_init("Aladdin cvxFXS/FXS", "aFXS");

    require(_zap != address(0), "aFXS: zero zap address");
    _checkRewards(_rewards);

    zap = _zap;
    rewards = _rewards;

    IERC20Upgradeable(FXS).safeApprove(CURVE_CVXFXS_POOL, uint256(-1));
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IAladdinCompounder
  function asset() public pure override returns (address) {
    return CURVE_CVXFXS_TOKEN;
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IAladdinCompounder
  function harvest(address _recipient, uint256 _minAssets) external override nonReentrant returns (uint256) {
    _distributePendingReward();

    // 1. claim rewards
    uint256 _length = rewards.length;
    uint256[] memory _balances = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      _balances[i] = IERC20Upgradeable(rewards[i]).balanceOf(address(this));
    }
    IConvexBasicRewards(CONVEX_REWARDER).getReward();

    // 2. convert to cvxFXS/FXS LP
    //   2.1. zap all tokens (except FXS, cvxFXS and FXS/cvxFXS LP) to FXS
    //   2.2. add liquidity to FXS/cvxFXS LP
    uint256 _amountLP;
    {
      uint256[2] memory _amounts; // FXS and cvxFXS amount
      address _zap = zap;
      for (uint256 i = 0; i < _length; i++) {
        address _token = rewards[i]; // saving gas
        // first token is always FXS, so this line will not be affected by zapping
        uint256 _pending = IERC20Upgradeable(_token).balanceOf(address(this)).sub(_balances[i]);
        if (_token == cvxFXS) {
          _amounts[1] += _pending;
        } else if (_token == CURVE_CVXFXS_TOKEN) {
          _amountLP += _pending;
        } else if (_token == FXS) {
          _amounts[0] += _pending;
        } else if (_pending > 0) {
          IERC20Upgradeable(_token).safeTransfer(_zap, _pending);
          _amounts[0] += IZap(_zap).zap(_token, _pending, FXS, 0);
        }
      }
      if (_amounts[0] > 0 || _amounts[1] > 0) {
        _amountLP = _amountLP.add(ICurveCryptoPool(CURVE_CVXFXS_POOL).add_liquidity(_amounts, 0));
      }
    }
    require(_amountLP >= _minAssets, "aFXS: insufficient rewards");

    FeeInfo memory _info = feeInfo;
    uint256 _platformFee;
    uint256 _harvestBounty;
    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    if (_info.platformPercentage > 0) {
      _platformFee = (_info.platformPercentage * _amountLP) / FEE_DENOMINATOR;
      // share will be a little more than the actual percentage since minted before distribute rewards
      _mint(_info.platform, _platformFee.mul(_totalShare) / _totalAssets);
    }
    if (_info.bountyPercentage > 0) {
      _harvestBounty = (_info.bountyPercentage * _amountLP) / FEE_DENOMINATOR;
      // share will be a little more than the actual percentage since minted before distribute rewards
      _mint(_recipient, _harvestBounty.mul(_totalShare) / _totalAssets);
    }
    totalAssetsStored = _totalAssets.add(_platformFee).add(_harvestBounty);

    emit Harvest(msg.sender, _recipient, _amountLP, _platformFee, _harvestBounty);

    // 3. update rewards info
    _depositToConvex(_amountLP);
    _notifyHarvestedReward(_amountLP - _platformFee - _harvestBounty);

    return _amountLP;
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the list of reward tokens.
  /// @param _rewards The address list of reward tokens to update.
  function updateRewards(address[] memory _rewards) external onlyOwner {
    _checkRewards(_rewards);

    delete rewards;
    rewards = _rewards;
  }

  /// @dev Update the zap contract
  /// @param _zap The address of the zap contract.
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "aFXS: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to validate rewards list.
  /// @param _rewards The address list of reward tokens.
  function _checkRewards(address[] memory _rewards) internal pure {
    bool _hasFXS = false;
    for (uint256 i = 0; i < _rewards.length; i++) {
      require(_rewards[i] != address(0), "aFXS: zero reward token");
      if (_rewards[i] == FXS) _hasFXS = true;
      for (uint256 j = 0; j < i; j++) {
        require(_rewards[i] != _rewards[j], "aFXS: duplicated reward token");
      }
    }
    if (_hasFXS) {
      require(_rewards[0] == FXS, "aFXS: first token not FXS");
    }
  }

  /// @inheritdoc AladdinCompounder
  /// @dev The caller should make sure `_distributePendingReward` is called before.
  function _deposit(uint256 _assets, address _receiver) internal override returns (uint256) {
    require(_assets > 0, "aFXS: deposit zero amount");

    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    uint256 _shares;
    if (_totalAssets == 0) _shares = _assets;
    else _shares = _assets.mul(_totalShare) / _totalAssets;

    _mint(_receiver, _shares);

    totalAssetsStored = _totalAssets + _assets;

    _depositToConvex(_assets);

    emit Deposit(msg.sender, _receiver, _assets, _shares);

    return _shares;
  }

  /// @inheritdoc AladdinCompounder
  /// @dev The caller should make sure `_distributePendingReward` is called before.
  function _withdraw(
    uint256 _shares,
    address _receiver,
    address _owner
  ) internal override returns (uint256) {
    require(_shares > 0, "aFXS: withdraw zero share");
    require(_shares <= balanceOf(_owner), "aFXS: insufficient owner shares");
    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    uint256 _amount = _shares.mul(_totalAssets) / _totalShare;
    _burn(_owner, _shares);

    if (_totalShare != _shares) {
      // take withdraw fee if it is not the last user.
      uint256 _withdrawFee = (_amount * feeInfo.withdrawPercentage) / FEE_DENOMINATOR;
      _amount = _amount - _withdrawFee; // never overflow here
    } else {
      // @note If it is the last user, some extra rewards still pending.
      // We just ignore it for now.
    }

    totalAssetsStored = _totalAssets - _amount; // never overflow here

    _withdrawFromConvex(_amount, _receiver);

    emit Withdraw(msg.sender, _receiver, _owner, _amount, _shares);

    return _amount;
  }

  /// @dev Internal function to deposit assets to Convex Booster.
  /// @param _amount The amount of assets to deposit.
  function _depositToConvex(uint256 _amount) internal {
    // @todo should do lazy deposit
    IERC20Upgradeable(CURVE_CVXFXS_TOKEN).safeApprove(BOOSTER, 0);
    IERC20Upgradeable(CURVE_CVXFXS_TOKEN).safeApprove(BOOSTER, _amount);
    IConvexBooster(BOOSTER).deposit(CURVE_CVXFXS_POOLID, _amount, true);
  }

  /// @dev Internal function to withdraw assets from Convex Booster.
  /// @param _amount The amount of assets to withdraw.
  /// @param _receiver The address of the account to receive the assets.
  function _withdrawFromConvex(uint256 _amount, address _receiver) internal {
    IConvexBasicRewards(CONVEX_REWARDER).withdrawAndUnwrap(_amount, false);
    IERC20Upgradeable(CURVE_CVXFXS_TOKEN).safeTransfer(_receiver, _amount);
  }
}