// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {DTBT} from './DTBT.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeERC20} from '../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

interface IETF is IERC20Detailed {
  enum Etypes {
    OPENED,
    CLOSED
  }

  function execute(
    address _target,
    uint _value,
    bytes calldata _data,
    bool isUnderlying
  ) external returns (bytes memory _returnValue);

  function isCompletedCollect() external view returns (bool);

  function etype() external view returns (Etypes);

  function adminList(address) external view returns (bool);

  function getController() external view returns (address);

  function etfStatus()
    external
    view
    returns (
      uint256 collectPeriod,
      uint256 collectEndTime,
      uint256 closurePeriod,
      uint256 closureEndTime,
      uint256 upperCap,
      uint256 floorCap,
      uint256 managerFee,
      uint256 redeemFee,
      uint256 issueFee,
      uint256 perfermanceFee,
      uint256 startClaimFeeTime
    );

  function bPool() external view virtual returns (LiquidityPoolActions);
}

interface LiquidityPoolActions {
  function getCurrentTokens() external view virtual returns (address[] memory);

  function isBound(address t) external view returns (bool);
}

interface IFactory {
  function isPaused() external view returns (bool);
}

contract TBillSimple is Ownable {
  using SafeERC20 for IERC20Detailed;

  address public stableCoinReceiver = 0x5a47DF2aaec5ad2F95A6a353c906559075f94186; // return stbt
  address public sTBTReceiver = 0xDEE9Ed3B19d104ADBbE255B6bEFC680b4eaAAda3; // return usdc

  IETF public etf;
  IFactory public factory;

  DTBT public dtbt;
  IERC20Detailed stbt = IERC20Detailed(0x530824DA86689C9C17CdC2871Ff29B058345b44a);
  IERC20Detailed stableCoin = IERC20Detailed(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

  event SendStaleCoin(address caller, address etf, address sendToken, uint sendAmount);
  event SendSTBT(address caller, address etf, address snedToken, uint sendAmount);
  event UpdateDTBTAmount(address caller, address etf, address dtbt, uint newAmount);

  event UpdateETFAddr(address caller, address oldValue, address newValue);
  event UpdateStbtAddr(address caller, address oldValue, address newValue);
  event UpdateStableCoinAddr(address caller, address oldValue, address newValue);
  event UpdateStableCoinReceiverAddr(address caller, address oldValue, address newValue);
  event UpdateStbtReceiverAddr(address caller, address oldValue, address newValue);

  constructor(IETF etf_, IFactory factory_, address dtbt_) public {
    require(etf_.etype() == IETF.Etypes.CLOSED, 'ERR_ONLY_SUPPORT_CLOSED_ETF');
    require(
      address(etf_) != address(0) && address(factory_) != address(0) && dtbt_ != address(0),
      'ERR_ZERO_ADDRESS'
    );
    factory = factory_;
    etf = etf_;
    dtbt = DTBT(dtbt_);
  }

  enum CurrentPeriod {
    WaitSendStableCoin,
    WaitSendSTBT
  }

  CurrentPeriod public currentPeriod = CurrentPeriod.WaitSendStableCoin;

  // only entry to make stable coin and stbt swap
  function swap() external {
    if (currentPeriod == CurrentPeriod.WaitSendStableCoin) {
      (, uint256 collectEndTime, , uint256 closureEndTime, , , , , , , ) = etf.etfStatus();
      require(collectEndTime < block.timestamp && closureEndTime > block.timestamp, 'ERR_PERIOD');
      _sendStableCoin();
      currentPeriod = CurrentPeriod.WaitSendSTBT;
    } else {
      _sendSTBT();
      currentPeriod = CurrentPeriod.WaitSendStableCoin;
    }
  }

  // update stable coin on etf and burn dtbt
  function rebalance() external _checkTx {
    require(currentPeriod == CurrentPeriod.WaitSendStableCoin, 'ERR_NOT_WAIT_SEND_STABLECOIN');
    (, , , uint256 closureEndTime, , , , , , , ) = etf.etfStatus();
    require(closureEndTime < block.timestamp, 'ERR_ETF_HAS_NOT_CLOSURE');

    uint bal = stableCoin.balanceOf(address(etf.bPool()));
    require(bal > 0, 'ERR_STABLECOIN_AMOUNT_IS_ZERO');
    _updateDtbtAmount(0);
    _invokeRebind(address(stableCoin), bal, 50e18);
  }

  // send stable coin to swap stbt coin
  function _sendStableCoin() internal _checkTx {
    uint bal = stableCoin.balanceOf(address(etf.bPool()));
    require(bal > 0, 'ERR_STABLECOIN_AMOUNT_IS_ZERO');

    bytes memory callData = abi.encodeWithSignature(
      'transfer(address,uint256)',
      stableCoinReceiver,
      bal
    );
    etf.execute(address(stableCoin), 0, callData, true);

    uint decimalsDtbt = dtbt.decimals();
    uint decimalsStableCoin = stableCoin.decimals();
    uint tbtNewBal = _decimalsHandle(bal, decimalsStableCoin, decimalsDtbt);

    _updateDtbtAmount(tbtNewBal);
    _invokeUnbind(etf, address(stableCoin));
    _invokeRebind(address(stbt), tbtNewBal, 50e18);

    emit SendStaleCoin(msg.sender, address(etf), address(stableCoin), bal);
  }

  // send stbt coin to swap stable coin
  function _sendSTBT() internal _checkTx {
    uint bal = stbt.balanceOf(address(etf.bPool()));
    require(bal > 0, 'ERR_STBT_AMOUNT_IS_ZERO');

    bytes memory callData = abi.encodeWithSignature('transfer(address,uint256)', sTBTReceiver, bal);
    etf.execute(address(stbt), 0, callData, true);

    uint decimalsStbt = stbt.decimals();
    uint decimalsStableCoin = stableCoin.decimals();
    uint stableCoinNewBal = _decimalsHandle(bal, decimalsStbt, decimalsStableCoin);

    _updateDtbtAmount(0);
    _invokeUnbind(etf, address(stbt));
    _invokeRebind(address(stableCoin), stableCoinNewBal, 50e18);

    emit SendSTBT(msg.sender, address(etf), address(stbt), bal);
  }

  function _updateDtbtAmount(uint amount) internal {
    address bpool = address(etf.bPool());
    uint balDtbt = dtbt.balanceOf(bpool);

    if (balDtbt > 0) dtbt.burn(bpool, balDtbt);
    if (amount > 0) dtbt.mint(bpool, amount);

    emit UpdateDTBTAmount(msg.sender, address(etf), address(dtbt), amount);
  }

  // convert token amount based on decimals
  function _decimalsHandle(
    uint256 currentValue,
    uint currentDecimals,
    uint targetDecimals
  ) internal pure returns (uint256) {
    if (currentDecimals >= targetDecimals)
      return currentValue / 10 ** (currentDecimals - targetDecimals);
    if (currentDecimals < targetDecimals)
      return currentValue * 10 ** (targetDecimals - currentDecimals);
  }

  function _invokeRebind(address _token, uint256 _balance, uint256 _weight) internal {
    bool isBound = etf.bPool().isBound(_token);
    bytes memory callData = abi.encodeWithSignature(
      'rebindPure(address,uint256,uint256,bool)',
      _token,
      _balance,
      _weight,
      isBound
    );

    etf.execute(address(etf.bPool()), 0, callData, false);
  }

  function _invokeUnbind(IETF _etf, address _token) internal {
    bool isBound = etf.bPool().isBound(_token);
    if (isBound) {
      bytes memory callData = abi.encodeWithSignature('unbindPure(address)', _token);
      _etf.execute(address(_etf.bPool()), 0, callData, false);
    }
  }

  // config: ETF coin address
  function updateETFaddr(IETF etf_) external onlyOwner _config_ {
    require(address(etf_) != address(0), 'ERR_ZERO_ADDRESS');
    emit UpdateETFAddr(msg.sender, address(etf), address(etf_));
    etf = etf_;
  }

  // config: stbt coin address
  function updateStbtAddr(IERC20Detailed stbt_) external onlyOwner _config_ {
    require(address(stbt_) != address(0), 'ERR_ZERO_ADDRESS');
    emit UpdateStbtAddr(msg.sender, address(stbt), address(stbt_));
    stbt = stbt_;
    dtbt.updateDecimals(stbt.decimals());
  }

  // config: stable coin address
  function updateStableCoinAddr(IERC20Detailed stableCoin_) external onlyOwner _config_ {
    require(address(stableCoin_) != address(0), 'ERR_ZERO_ADDRESS');
    emit UpdateStableCoinAddr(msg.sender, address(stableCoin), address(stableCoin_));
    stableCoin = stableCoin_;
  }

  // config: stable coin receiver address
  function updateStableCoinReceiverAddr(address stableCoinReceiver_) external onlyOwner _config_ {
    require(stableCoinReceiver_ != address(0), 'ERR_ZERO_ADDRESS');
    emit UpdateStableCoinReceiverAddr(msg.sender, stableCoinReceiver, stableCoinReceiver_);
    stableCoinReceiver = stableCoinReceiver_;
  }

  // config: stbt coin receiver address
  function updateStbtReceiverAddr(address sTBTReceiver_) external onlyOwner _config_ {
    require(sTBTReceiver_ != address(0), 'ERR_ZERO_ADDRESS');
    emit UpdateStbtReceiverAddr(msg.sender, sTBTReceiver, sTBTReceiver_);
    sTBTReceiver = sTBTReceiver_;
  }

  modifier _checkTx() {
    require(!factory.isPaused(), 'PAUSED');
    require(etf.isCompletedCollect(), 'COLLECTION_FAILED');
    require(etf.adminList(msg.sender) || msg.sender == etf.getController(), 'NOT_CONTROLLER');
    _;
  }

  modifier _config_() {
    (, uint256 collectEndTime, , , , , , , , , ) = etf.etfStatus();
    require(block.timestamp < collectEndTime, 'ERR_ETF_HAS_BEEN_CREATE');
    _;
  }
}