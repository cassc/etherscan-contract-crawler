// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

import "../interfaces/IClearingHouseV2.sol";
import "../library/SigRecovery.sol";

contract ClearingHouseV2 is IClearingHouseV2, Ownable, Pausable {
  using SafeERC20 for ERC20;
  using SafeERC20 for IWETH;
  using PRBMathUD60x18 for uint256;

  //###############
  //#### STATE ####
  //Cause token address => CauseInformation
  mapping(ERC20Singleton => CauseInformation) public override causeInformation;
  //Cause ID => KYC ID => Running total of amount per user (by KYC ID)
  mapping(uint256 => mapping(bytes => uint256)) public override withdrawnAmount;
  //Message hash => boolean. To track if a message has been used for purchase previously
  mapping(bytes32 => bool) public override usedSignatures;

  DonationsRouter public override donationsRouter;
  BuyInTokenData public override buyInToken;
  StakingRewards public override staking;
  IWETH public override WETH;
  address public override zeroXSwapTarget;
  address public override governor;

  constructor(
    address _owner,
    address _donationsRouter,
    address _buyInToken,
    address _staking,
    address _WETH,
    address _swapTarget // address _governor
  ) {
    _checkZeroAddress(_owner);
    _checkZeroAddress(_donationsRouter);
    _checkZeroAddress(_buyInToken);
    _checkZeroAddress(_staking);
    _checkZeroAddress(_WETH);
    _checkZeroAddress(_swapTarget);
    // _checkZeroAddress(_governor);
    donationsRouter = DonationsRouter(_donationsRouter);
    buyInToken = BuyInTokenData({
      tokenAddress: ERC20(_buyInToken),
      decimals: ERC20(_buyInToken).decimals()
    });
    staking = StakingRewards(_staking);
    WETH = IWETH(_WETH);
    zeroXSwapTarget = _swapTarget;
    // governor = _governor;
    _transferOwnership(_owner);
  }

  receive() external payable {}

  //############################
  //#### INTERNAL FUNCTIONS ####

  function _checkZeroAddress(address _address) internal pure {
    if (_address == address(0)) {
      revert CannotBeZeroAddress();
    }
  }

  function _checkIfCauseOwner(ERC20Singleton _childDaoToken) internal view {
    (address causeOwner, , , ) = donationsRouter.causeRecords(
      donationsRouter.tokenCauseIds(address(_childDaoToken))
    );
    if (msg.sender != causeOwner) {
      revert AccountNotDaoOwner();
    }
  }

  function _verifySignature(
    bytes memory _KYCId,
    address _user,
    uint256 _causeId,
    uint256 _expiry,
    bytes memory _signature
  ) internal {
    if (block.timestamp > _expiry) {
      revert ApprovalExpired();
    }
    (address messageSigner, bytes32 messageHash) = SigRecovery.recoverApproval(
      _KYCId,
      _user,
      _causeId,
      _expiry,
      _signature
    );
    if (messageSigner != owner()) {
      revert InvalidSignature();
    }
    if (usedSignatures[messageHash]) {
      revert InvalidSignature();
    }
    usedSignatures[messageHash] = true;
  }

  function _checkChildDaoRegistered(uint256 _causeId) internal pure {
    if (_causeId == 0) {
      revert ChildDaoNotRegistered();
    }
  }

  function _checkReleaseStarted(uint256 _release) internal view {
    if (block.timestamp < _release) {
      revert ChildDaoReleaseNotStarted();
    }
  }

  function _checkMaxPerUser(
    uint256 _amount,
    uint256 _maxPerUser,
    uint256 _withdrawnAmount
  ) internal view {
    if (_withdrawnAmount + _amount > _maxPerUser && msg.sender != owner()) {
      revert UserAmountExceeded();
    }
  }

  function _mintDaoToken(
    uint256 _daoAmount,
    ERC20Singleton _childDaoToken,
    bool _autoStaking
  ) internal {
    if (_autoStaking) {
      _childDaoToken.mint(address(this), _daoAmount);
      staking.stakeOnBehalf(msg.sender, address(_childDaoToken), _daoAmount);
    }
    _childDaoToken.mint(msg.sender, _daoAmount);
  }

  function _transferBuyInToken(
    uint256 _daoAmount,
    uint256 _daoExchangeRate,
    address _treasuryAddress,
    BuyInTokenData memory _buyInToken,
    bool _fromSwap
  ) internal {
    uint256 buyAmount;
    if (_buyInToken.decimals < 18) {
      buyAmount = _daoAmount.mul(_daoExchangeRate).mul(
        10**_buyInToken.decimals
      );
    } else {
      buyAmount = _daoAmount.mul(_daoExchangeRate);
    }
    if (_fromSwap) {
      _buyInToken.tokenAddress.safeTransfer(_treasuryAddress, buyAmount);
    } else {
      _buyInToken.tokenAddress.safeTransferFrom(
        msg.sender,
        _treasuryAddress,
        buyAmount
      );
    }
  }

  function _returnExtraBuy(SwapData calldata _swapData, uint256 _amountBought)
    internal
  {
    if (_amountBought > _swapData.buyAmount) {
      _swapData.buyToken.safeTransfer(
        msg.sender,
        _amountBought - _swapData.buyAmount
      );
    }
  }

  function _callZeroXSwap(SwapData calldata _swapData)
    internal
    returns (uint256 amountBought)
  {
    if (_swapData.swapTarget != zeroXSwapTarget) {
      revert WrongSwapTarget();
    }
    (bool success, bytes memory returnData) = _swapData.swapTarget.call(
      _swapData.swapTxData
    );
    if (!success) {
      revert ZeroXSwapFailed();
    }
    amountBought = abi.decode(returnData, ((uint256)));
  }

  function _swapToken(SwapData calldata _swapData) internal {
    _swapData.sellToken.safeTransferFrom(
      msg.sender,
      address(this),
      _swapData.sellAmount
    );
    uint256 sellBalanceBefore = _swapData.sellToken.balanceOf(address(this)) -
      _swapData.sellAmount;
    _swapData.sellToken.approve(_swapData.swapTarget, type(uint256).max);
    uint256 amountBought = _callZeroXSwap(_swapData);
    uint256 sellBalanceAfter = _swapData.sellToken.balanceOf(address(this));
    if (sellBalanceAfter > 0) {
      _swapData.sellToken.safeTransfer(
        msg.sender,
        sellBalanceAfter - sellBalanceBefore
      );
    }
    _returnExtraBuy(_swapData, amountBought);
  }

  function _swapETH(SwapData calldata _swapData) internal {
    uint256 sellBalanceBefore = WETH.balanceOf(address(this));
    WETH.deposit{value: msg.value}();
    WETH.approve(_swapData.swapTarget, type(uint256).max);

    uint256 amountBought = _callZeroXSwap(_swapData);
    uint256 sellBalanceAfter = _swapData.sellToken.balanceOf(address(this));

    if (sellBalanceAfter > 0) {
      WETH.withdraw(sellBalanceAfter);

      (bool transferSuccess, ) = msg.sender.call{
        value: sellBalanceAfter - sellBalanceBefore
      }("");

      if (!transferSuccess) {
        revert EthTransferFailed();
      }
    }
    _returnExtraBuy(_swapData, amountBought);
  }

  function _checkInvariants(
    ERC20Singleton _childDaoToken,
    uint256 _amount,
    bytes calldata _KYCId,
    uint256 _expiry,
    bytes memory _signature
  )
    internal
    returns (CauseInformation memory causeInfo, address defaultWallet)
  {
    uint256 causeId = donationsRouter.tokenCauseIds(address(_childDaoToken));
    _checkChildDaoRegistered(causeId);

    causeInfo = causeInformation[_childDaoToken];
    if (causeInfo.paused) {
      revert CausePaused();
    }
    _verifySignature(_KYCId, msg.sender, causeId, _expiry, _signature);
    _checkReleaseStarted(causeInfo.release);

    uint256 withdrawnTotal = withdrawnAmount[causeId][_KYCId];
    if (causeInfo.kycEnabled) {
      _checkMaxPerUser(_amount, causeInfo.maxPerUser, withdrawnTotal);
    } else {
      _checkMaxPerUser(_amount, causeInfo.maxPerUser, 0);
    }
    withdrawnAmount[causeId][_KYCId] = withdrawnTotal + _amount;

    (, defaultWallet, , ) = donationsRouter.causeRecords(causeId);
  }

  function _normaliseExchangeRate(uint256 _rate)
    internal
    view
    returns (uint256 normalisedRate)
  {
    BuyInTokenData memory buyInTokenData = buyInToken;
    if (buyInTokenData.decimals < 18) {
      normalisedRate = (_rate * 10**(18 - buyInTokenData.decimals));
    } else {
      normalisedRate = _rate;
    }
  }

  function _checkIfGovernor() internal view {
    if (msg.sender != governor) {
      revert AccountNotGovernor();
    }
  }

  //###################
  //#### MODIFIERS ####

  modifier onlyCauseOwner(ERC20Singleton _childDaoToken) {
    _checkIfCauseOwner(_childDaoToken);
    _;
  }

  modifier onlyGovernor() {
    _checkIfGovernor();
    _;
  }

  //###################
  //#### FUNCTIONS ####

  function registerChildDao(
    ERC20Singleton _childDaoToken,
    bool _autoStaking,
    bool _kycEnabled,
    uint256 _maxSupply,
    uint256 _maxSwap,
    uint256 _release,
    uint256 _exchangeRate
  ) external override onlyGovernor whenNotPaused {
    causeInformation[_childDaoToken] = CauseInformation({
      release: _release,
      maxSupply: _maxSupply,
      maxPerUser: _maxSwap,
      exchangeRate: _normaliseExchangeRate(_exchangeRate),
      childDaoRegistry: true,
      autoStaking: _autoStaking,
      kycEnabled: _kycEnabled,
      paused: false
    });

    emit ChildDaoRegistered(address(_childDaoToken));
    _childDaoToken.approve(address(staking), type(uint256).max);
  }

  function purchaseToken(
    ERC20Singleton _childDaoToken,
    uint256 _amount,
    bytes calldata _KYCId,
    uint256 _expiry,
    bytes memory _signature
  ) external override whenNotPaused {
    (
      CauseInformation memory causeInfo,
      address defaultWallet
    ) = _checkInvariants(_childDaoToken, _amount, _KYCId, _expiry, _signature);
    _mintDaoToken(_amount, _childDaoToken, causeInfo.autoStaking);
    BuyInTokenData memory buyInTokenData = buyInToken;
    _transferBuyInToken(
      _amount,
      causeInfo.exchangeRate,
      defaultWallet,
      buyInTokenData,
      false
    );
    emit DaoTokenPurchased(_amount, msg.sender, causeInfo.autoStaking);
  }

  function swapAndPurchaseToken(
    ERC20Singleton _childDaoToken,
    uint256 _amount,
    bytes calldata _KYCId,
    uint256 _expiry,
    bytes memory _signature,
    SwapData calldata _swapData
  ) external override whenNotPaused {
    BuyInTokenData memory buyInTokenData = buyInToken;

    (
      CauseInformation memory causeInfo,
      address defaultWallet
    ) = _checkInvariants(_childDaoToken, _amount, _KYCId, _expiry, _signature);
    _swapToken(_swapData);
    _mintDaoToken(_amount, _childDaoToken, causeInfo.autoStaking);
    _transferBuyInToken(
      _amount,
      causeInfo.exchangeRate,
      defaultWallet,
      buyInTokenData,
      true
    );
    emit DaoTokenPurchased(_amount, msg.sender, causeInfo.autoStaking);
  }

  function swapETHAndPurchaseToken(
    ERC20Singleton _childDaoToken,
    uint256 _amount,
    bytes calldata _KYCId,
    uint256 _expiry,
    bytes memory _signature,
    SwapData calldata _swapData
  ) external payable override whenNotPaused {
    BuyInTokenData memory buyInTokenData = buyInToken;

    if (_swapData.buyToken != buyInTokenData.tokenAddress) {
      revert WrongBuyToken();
    }
    if (address(_swapData.sellToken) != address(WETH)) {
      revert WrongSellToken();
    }
    (
      CauseInformation memory causeInfo,
      address defaultWallet
    ) = _checkInvariants(_childDaoToken, _amount, _KYCId, _expiry, _signature);
    _swapETH(_swapData);
    _mintDaoToken(_amount, _childDaoToken, causeInfo.autoStaking);
    _transferBuyInToken(
      _amount,
      causeInfo.exchangeRate,
      defaultWallet,
      buyInTokenData,
      true
    );
    emit DaoTokenPurchased(_amount, msg.sender, causeInfo.autoStaking);
  }

  //##########################
  //#### SETTER FUNCTIONS ####

  function setAutoStake(ERC20Singleton _childDaoToken, bool _state)
    external
    override
    onlyCauseOwner(_childDaoToken)
  {
    causeInformation[_childDaoToken].autoStaking = _state;
  }

  function enableKyc(ERC20Singleton _childDaoToken)
    external
    override
    onlyCauseOwner(_childDaoToken)
  {
    causeInformation[_childDaoToken].kycEnabled = true;
  }

  function setMaxPerUser(ERC20Singleton _childDaoToken, uint256 _max)
    external
    override
    onlyCauseOwner(_childDaoToken)
  {
    causeInformation[_childDaoToken].maxPerUser = _max;
  }

  function setExchangeRate(ERC20Singleton _childDaoToken, uint256 _rate)
    external
    override
    onlyCauseOwner(_childDaoToken)
  {
    causeInformation[_childDaoToken].exchangeRate = _normaliseExchangeRate(
      _rate
    );
  }

  function pauseCause(ERC20Singleton _childDaoToken)
    external
    override
    onlyCauseOwner(_childDaoToken)
  {
    causeInformation[_childDaoToken].paused = true;
  }

  function unpauseCause(ERC20Singleton _childDaoToken)
    external
    override
    onlyCauseOwner(_childDaoToken)
  {
    causeInformation[_childDaoToken].paused = false;
  }

  function setDonationsRouter(DonationsRouter _implementation)
    external
    override
    onlyOwner
  {
    _checkZeroAddress(address(_implementation));
    donationsRouter = _implementation;
  }

  function setBuyInToken(ERC20 _implementation) external override onlyOwner {
    _checkZeroAddress(address(_implementation));
    buyInToken = BuyInTokenData({
      tokenAddress: _implementation,
      decimals: _implementation.decimals()
    });
  }

  function setStakingRewards(StakingRewards _implementation)
    external
    override
    onlyOwner
  {
    _checkZeroAddress(address(_implementation));
    staking = _implementation;
  }

  function setSwapTarget(address _implementation) external override onlyOwner {
    _checkZeroAddress(_implementation);
    zeroXSwapTarget = _implementation;
  }

  function setGovernor(address _implementation) external onlyOwner {
    _checkZeroAddress(_implementation);
    governor = _implementation;
  }

  function pause() external override onlyOwner {
    _pause();
  }

  function unpause() external override onlyOwner {
    _unpause();
  }
}