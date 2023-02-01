// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IStakeDAOCRVVault.sol";
import "../../interfaces/IZap.sol";

import "./SdCRVLocker.sol";
import "../AladdinCompounder.sol";

// solhint-disable reason-string

contract AladdinSdCRV is AladdinCompounder, SdCRVLocker {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when the zap contract is updated.
  /// @param _zap The address of the zap contract.
  event UpdateZap(address _zap);

  /// @dev The type for withdraw fee in StakeDAOVaultBase
  bytes32 private constant VAULT_WITHDRAW_FEE_TYPE = keccak256("StakeDAOVaultBase.WithdrawFee");

  /// @dev The address of CRV Token.
  address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

  /// @dev The address of SDT Token.
  address private constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;

  // The address of 3CRV token.
  address private constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

  /// @dev The address of legacy sdveCRV Token.
  address private constant SD_VE_CRV = 0x478bBC744811eE8310B461514BDc29D03739084D;

  /// @dev The address of sdCRV Token.
  // solhint-disable-next-line const-name-snakecase
  address private constant sdCRV = 0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5;

  /// @dev The address of StakeDAOCRVVault contract.
  address private immutable vault;

  /// @dev The address of ZAP contract, will be used to swap tokens.
  address public zap;

  /********************************** Constructor **********************************/

  constructor(address _vault) {
    vault = _vault;
  }

  function initialize(address _zap) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    ERC20Upgradeable.__ERC20_init("Aladdin sdCRV", "asdCRV");

    require(_zap != address(0), "zero zap address");
    zap = _zap;

    IERC20Upgradeable(CRV).safeApprove(vault, uint256(-1));
    IERC20Upgradeable(SD_VE_CRV).safeApprove(vault, uint256(-1));
    IERC20Upgradeable(sdCRV).safeApprove(vault, uint256(-1));
  }

  // receive ETH from zap
  receive() external payable {}

  /********************************** View Functions **********************************/

  /// @inheritdoc IAladdinCompounder
  function asset() public pure override returns (address) {
    return sdCRV;
  }

  /// @inheritdoc SdCRVLocker
  function withdrawLockTime() public view override returns (uint256) {
    return SdCRVLocker(vault).withdrawLockTime();
  }

  /********************************** Mutated Functions **********************************/

  /// @notice Deposit CRV into the contract.
  /// @dev Use `_assets=uint256(-1)` if you want to deposit all CRV.
  /// @param _assets The amount of CRV to desposit.
  /// @param _receiver The address of account who will receive the pool share.
  /// @param _minShareOut The minimum amount of share to receive.
  /// @return _shares The amount of pool shares received.
  function depositWithCRV(
    uint256 _assets,
    address _receiver,
    uint256 _minShareOut
  ) external nonReentrant returns (uint256 _shares) {
    _distributePendingReward();

    if (_assets == uint256(-1)) {
      _assets = IERC20Upgradeable(CRV).balanceOf(msg.sender);
    }
    IERC20Upgradeable(CRV).safeTransferFrom(msg.sender, address(this), _assets);

    _assets = IStakeDAOCRVVault(vault).depositWithCRV(_assets, address(this), 0);

    _shares = _mintShare(_assets, _receiver);
    require(_shares >= _minShareOut, "asdCRV: insufficient share received");
  }

  /// @notice Deposit sdveCRV into the contract.
  /// @dev Use `_assets=uint256(-1)` if you want to deposit all sdveCRV.
  /// @param _assets The amount of sdveCRV to desposit.
  /// @param _receiver The address of account who will receive the pool share.
  /// @return _shares The amount of pool shares received.
  function depositWithSdVeCRV(uint256 _assets, address _receiver) external nonReentrant returns (uint256 _shares) {
    _distributePendingReward();

    if (_assets == uint256(-1)) {
      _assets = IERC20Upgradeable(SD_VE_CRV).balanceOf(msg.sender);
    }
    IERC20Upgradeable(SD_VE_CRV).safeTransferFrom(msg.sender, address(this), _assets);

    IStakeDAOCRVVault(vault).depositWithSdVeCRV(_assets, address(this));

    _shares = _mintShare(_assets, _receiver);
  }

  /// @inheritdoc IAladdinCompounder
  function harvest(address _recipient, uint256 _minAssets) external override nonReentrant returns (uint256 assets) {
    _distributePendingReward();

    // 1. claim rewards and sell to sdCRV
    {
      // 1.1 claim SDT/CRV/3CRV rewards
      uint256 _amountSDT = IERC20Upgradeable(SDT).balanceOf(address(this));
      uint256 _amountCRV = IERC20Upgradeable(CRV).balanceOf(address(this));
      uint256 _amount3CRV = IERC20Upgradeable(THREE_CRV).balanceOf(address(this));
      IStakeDAOCRVVault(vault).claim(address(this), address(this));
      _amountSDT = IERC20Upgradeable(SDT).balanceOf(address(this)) - _amountSDT;
      _amountCRV = IERC20Upgradeable(CRV).balanceOf(address(this)) - _amountCRV;
      _amount3CRV = IERC20Upgradeable(THREE_CRV).balanceOf(address(this)) - _amount3CRV;

      // 1.2 sell SDT/3CRV to ETH

      uint256 _amountETH;
      address _zap = zap;
      if (_amountSDT > 0) {
        IERC20Upgradeable(SDT).safeTransfer(_zap, _amountSDT);
        _amountETH += IZap(_zap).zap(SDT, _amountSDT, address(0), 0);
      }
      if (_amount3CRV > 0) {
        IERC20Upgradeable(THREE_CRV).safeTransfer(_zap, _amount3CRV);
        _amountETH += IZap(_zap).zap(THREE_CRV, _amount3CRV, address(0), 0);
      }

      // 1.3 sell ETH to CRV
      if (_amountETH > 0) {
        _amountCRV += IZap(_zap).zap{ value: _amountETH }(address(0), _amountETH, CRV, 0);
      }

      // 1.4 deposit CRV as sdCRV
      assets = IStakeDAOCRVVault(vault).depositWithCRV(_amountCRV, address(this), 0);
      require(assets >= _minAssets, "asdCRV: insufficient harvested sdCRV");
    }

    // 2. calculate fee and distribute
    FeeInfo memory _fee = feeInfo;
    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    uint256 _platformFee = _fee.platformPercentage;
    if (_platformFee > 0) {
      _platformFee = (_platformFee * assets) / FEE_PRECISION;
      // share will be a little more than the actual percentage since minted before distribute rewards
      _mint(_fee.platform, _platformFee.mul(_totalShare) / _totalAssets);
    }
    uint256 _harvestBounty = _fee.bountyPercentage;
    if (_harvestBounty > 0) {
      _harvestBounty = (_harvestBounty * assets) / FEE_PRECISION;
      // share will be a little more than the actual percentage since minted before distribute rewards
      _mint(_recipient, _harvestBounty.mul(_totalShare) / _totalAssets);
    }
    totalAssetsStored = _totalAssets.add(_platformFee).add(_harvestBounty);

    emit Harvest(msg.sender, _recipient, assets, _platformFee, _harvestBounty);

    _notifyHarvestedReward(assets - _platformFee - _harvestBounty);
  }

  /********************************** Restricted Functions **********************************/

  /// @dev Update the zap contract
  /// @param _zap The address of the zap contract.
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "asdCRV: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc AladdinCompounder
  function _deposit(uint256 _assets, address _receiver) internal override returns (uint256) {
    IStakeDAOCRVVault(vault).deposit(_assets, address(this));

    return _mintShare(_assets, _receiver);
  }

  /// @dev Internal function to mint share to user.
  /// @param _assets The amount of asset to deposit.
  /// @param _receiver The address of account who will receive the pool share.
  /// @return Return the amount of pool shares to be received.
  function _mintShare(uint256 _assets, address _receiver) internal returns (uint256) {
    require(_assets > 0, "asdCRV: deposit zero amount");

    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    uint256 _shares;
    if (_totalAssets == 0) _shares = _assets;
    else _shares = _assets.mul(_totalShare) / _totalAssets;

    _mint(_receiver, _shares);

    totalAssetsStored = _totalAssets + _assets;

    emit Deposit(msg.sender, _receiver, _assets, _shares);

    return _shares;
  }

  /// @inheritdoc AladdinCompounder
  function _withdraw(
    uint256 _shares,
    address _receiver,
    address _owner
  ) internal override returns (uint256) {
    require(_shares > 0, "asdCRV: withdraw zero share");
    require(_shares <= balanceOf(_owner), "asdCRV: insufficient owner shares");
    uint256 _totalAssets = totalAssetsStored; // the value is correct
    uint256 _totalShare = totalSupply();
    uint256 _amount = _shares.mul(_totalAssets) / _totalShare;
    _burn(_owner, _shares);

    if (_totalShare != _shares) {
      // take withdraw fee if it is not the last user.
      uint256 _withdrawPercentage = getFeeRate(WITHDRAW_FEE_TYPE, _owner);
      uint256 _withdrawFee = (_amount * _withdrawPercentage) / FEE_PRECISION;
      _amount = _amount - _withdrawFee; // never overflow here
    } else {
      // @note If it is the last user, some extra rewards still pending.
      // We just ignore it for now.
    }

    totalAssetsStored = _totalAssets - _amount; // never overflow here

    // vault has withdraw fee, we need to subtract from it
    IStakeDAOCRVVault(vault).withdraw(_amount, address(this));
    uint256 _vaultWithdrawFee = FeeCustomization(vault).getFeeRate(VAULT_WITHDRAW_FEE_TYPE, address(this));
    if (_vaultWithdrawFee > 0) {
      _vaultWithdrawFee = (_amount * _vaultWithdrawFee) / FEE_PRECISION;
      _amount = _amount - _vaultWithdrawFee;
    }

    _lockToken(_amount, _receiver);

    emit Withdraw(msg.sender, _receiver, _owner, _amount, _shares);

    return _amount;
  }

  /// @inheritdoc SdCRVLocker
  function _unlockToken(uint256 _amount, address _recipient) internal override {
    SdCRVLocker(vault).withdrawExpired(address(this), address(this));
    IERC20Upgradeable(sdCRV).safeTransfer(_recipient, _amount);
  }
}