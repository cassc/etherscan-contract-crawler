// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./../interface/basket/IBasketLedger.sol";
import "./../interface/bridge/ILiquidCryptoBridge_v2.sol";
import "./../interface/IUniswapRouterETH.sol";
import "./../interface/ILiquidCZapUniswapV2.sol";
import "./../interface/IWETH.sol";

import "./../interface/stargate/IStargateRouter.sol";

contract Basketv3 is Ownable {
  address public ledger;
  address public bridge;
  address public treasury;

  mapping (address => bool) public managers;

  address public stargaterouter;
  address public unirouter;
  address[] public nativeToStargateInput;
  address[] public stargateInputToNative;
  address public native;
  address public stargateInput;
  uint256 public stargateSourcePoolId;
  uint256 public stargateSwapFeeMultipler = 1400000;
  uint256 public stargateSwapFeeDivider = 1000000;
  uint256 public stargateSwapFee = 600;

  struct PoolInfo {
    address liquidCZap;
    address vault;
    address router;
    address[] path;
    uint256 amount; // deposit - reserved  withdraw - specific amount
  }

  struct BridgeSwapInfo {
    uint256 chain;
    address bridgeAddress;
    uint256 poolCnts;
  }

  struct StragateSwapInfo {
    uint16 chain;
    address basketAddress;
    uint256 srcPoolID;
    uint256 dstPoolID;
    uint256 poolCnts;
  }

  constructor(
    address _ledger,
    address _bridge,
    address _unirouter,
    address _stargaterouter,
    uint256 _stargateSourcePoolId,
    address[] memory _nativeToStargateInput,
    address[] memory _stargateInputToNative,
    address _treasury
  ) {
    managers[msg.sender] = true;
    ledger = _ledger;
    bridge = _bridge;
    treasury = _treasury;
    stargaterouter = _stargaterouter;
    unirouter = _unirouter;
    nativeToStargateInput = _nativeToStargateInput;
    stargateInputToNative = _stargateInputToNative;
    native = _nativeToStargateInput[0];
    stargateInput = _nativeToStargateInput[_nativeToStargateInput.length - 1];
    stargateSourcePoolId = _stargateSourcePoolId;

    _approveTokenIfNeeded(native, unirouter);
    _approveTokenIfNeeded(stargateInput, unirouter);
    _approveTokenIfNeeded(stargateInput, stargaterouter);
  }

  modifier onlyManager() {
    require(managers[msg.sender], "LiquidC Basket v3: !manager");
    _;
  }

  receive() external payable {
  }

  function deposit(address _account, PoolInfo[] memory _pools, StragateSwapInfo[] memory _sgSwaps, BridgeSwapInfo[] memory _lcbrgSwaps) public payable {
    uint256 inputAmount = msg.value;
    uint256 poolLen = _pools.length;
    uint256 sgSwapLen = _sgSwaps.length;
    uint256 lcbrgSwapLen = _lcbrgSwaps.length;
    uint256 sgSwapNum = 0;
    uint256 lcbrgSwapNum = 0;
    for (uint256 i=0; i<sgSwapLen; i++) {
      sgSwapNum += _sgSwaps[i].poolCnts;
    }
    for (uint256 i=0; i<lcbrgSwapLen; i++) {
      lcbrgSwapNum += _lcbrgSwaps[i].poolCnts;
    }
    uint256 totalNum = poolLen + sgSwapNum + lcbrgSwapNum;

    if (sgSwapLen > 0) {
      _stargateSwap(_sgSwaps, inputAmount * sgSwapNum / totalNum, sgSwapNum);
    }
    if (lcbrgSwapLen > 0) {
      _lcBridgeSwap(_account, _lcbrgSwaps, inputAmount * lcbrgSwapNum / totalNum, lcbrgSwapNum);
    }
    if (poolLen > 0) {
      if (address(this).balance > 0) {
        IWETH(native).deposit{value: address(this).balance}();
      }
      uint256 nativeBalance = IERC20(native).balanceOf(address(this));
      uint256 amount = nativeBalance / poolLen;
      for (uint256 i=0; i<poolLen; i++) {
        _deposit(_account, _pools[i], amount, false);
      }
    }

    if (address(this).balance > 0) {
      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(success, "Failed refund change");
    }
  }

  function depositFromBridge(address _account, PoolInfo[] memory _pools, uint256 _itokenAmount, uint256 _fee, uint8 _bridge) public {
    uint256 nativeBalance = 0;
    if (_bridge == 0) { // Stargate
      uint256 iTokenBalance = IERC20(stargateInput).balanceOf(address(this));
      require(_itokenAmount <= iTokenBalance, "LiquidC Basket v3: stargate bridge not completed");
      uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(_itokenAmount, 0, stargateInputToNative, address(this), block.timestamp);
      nativeBalance = amounts[amounts.length - 1];
    }
    else if (_bridge == 1) { // LCBridge
      nativeBalance = ILiquidCryptoBridge_v2(bridge).redeem(_itokenAmount, address(this), 0, true);
    }
    if (_fee > 0 && nativeBalance > _fee) {
      nativeBalance -= _fee;
      IWETH(native).withdraw(_fee);
      (bool success, ) = msg.sender.call{value: _fee}("");
      require(success, "LiquidC Basket v3: Failed cut operator fee");
    }

    if (nativeBalance > 0) {
      uint256 poolLen = _pools.length;
      uint256 amount = nativeBalance / poolLen;
      for (uint256 i=0; i<poolLen; i++) {
        _deposit(_account, _pools[i], amount, false);
      }
    }
  }

  function withdraw(address _account, PoolInfo[] memory _pools, StragateSwapInfo memory _stgSwap, BridgeSwapInfo memory _lcbrgSwap, uint256 _fee) public {
    uint256 poolLen = _pools.length;
    if (poolLen > 0) {
      for (uint256 i=0; i<poolLen; i++) {
        uint256 ledgerBalance = IBasketLedger(ledger).xlpSupply(_pools[i].vault, _account);
        require(ledgerBalance >= _pools[i].amount, "LiquidC Basket v3: exceed xlpbalance");
        if (ledgerBalance < _pools[i].amount) {
          _pools[i].amount = ledgerBalance;
        }
        if (_pools[i].amount > 0) {
          uint256 xlpOut = IBasketLedger(ledger).withdraw(_account, _pools[i].vault, _pools[i].amount);
          if (xlpOut > 0) {
            _approveTokenIfNeeded(_pools[i].vault, _pools[i].liquidCZap);
            ILiquidCZapUniswapV2(_pools[i].liquidCZap).LiquidCOutAndSwap(_pools[i].vault, xlpOut, _pools[i].path[0], 0);

            if (_pools[i].path.length > 1) {
              _approveTokenIfNeeded(_pools[i].path[0], _pools[i].router);
              uint256 t0amount = IERC20(_pools[i].path[0]).balanceOf(address(this));
              IUniswapRouterETH(_pools[i].router).swapExactTokensForTokens(t0amount, 0, _pools[i].path, address(this), block.timestamp);
            }
          }
        }
      }
    }

    uint256 nativeBalance = IERC20(native).balanceOf(address(this));
    if (nativeBalance > 0) {
      IWETH(native).withdraw(nativeBalance);
    }
    if (_fee > 0 && nativeBalance > _fee) {
      (bool success, ) = msg.sender.call{value: _fee}("");
      require(success, "LiquidC Basket v3: Failed cut operator fee");
    }

    uint256 coinAmount = address(this).balance;
    uint256 totalBrgCnt = _stgSwap.poolCnts + _lcbrgSwap.poolCnts;
    if (_stgSwap.poolCnts > 0) {
      uint256 stgAmount = coinAmount * _stgSwap.poolCnts / totalBrgCnt;
      (uint256 swFee, ) = IStargateRouter(stargaterouter).quoteLayerZeroFee(
        _stgSwap.chain,
        1,
        bytes("0x"),
        bytes("0x"),
        IStargateRouter.lzTxObj(0, 0, "0x")
      );
      swFee = swFee * stargateSwapFeeMultipler / stargateSwapFeeDivider;
      stgAmount -= swFee;
      IWETH(native).deposit{value: totalBrgCnt}();

      uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(stgAmount, 0, nativeToStargateInput, address(this), block.timestamp);
      _stgBridgeSwap(_stgSwap, swFee, amounts[amounts.length-1]);
    }
    if (_lcbrgSwap.poolCnts > 0) {
      uint256 lcbAmount = coinAmount * _lcbrgSwap.poolCnts / totalBrgCnt;
      IWETH(native).deposit{value: lcbAmount}();
      ILiquidCryptoBridge_v2(bridge).swap{value: lcbAmount}(_lcbrgSwap.bridgeAddress, _account, _lcbrgSwap.chain);
    }
    if (address(this).balance > 0) {
      (bool success, ) = payable(_account).call{value: address(this).balance}("");
      require(success, "LiquidC Basket v3: Failed wirhdraw");
    }
  }

  function _stargateSwap(StragateSwapInfo[] memory _swaps, uint256 _amount, uint256 _totalPools) internal {
    uint256 totalSwfee = 0;
    uint256 swapLen = _swaps.length;
    uint256[] memory swFees = new uint256[](swapLen);
    for (uint256 i=0; i<swapLen; i++) {
      (uint256 swFee, ) = IStargateRouter(stargaterouter).quoteLayerZeroFee(
        _swaps[i].chain,
        1,
        bytes("0x"),
        bytes("0x"),
        IStargateRouter.lzTxObj(0, 0, "0x")
      );
      swFee = swFee * stargateSwapFeeMultipler / stargateSwapFeeDivider;
      swFees[i] = swFee;
      totalSwfee = totalSwfee + swFee;
    }

    if (totalSwfee <= _amount) {
      _amount -= totalSwfee;
      IWETH(native).deposit{value: _amount}();
      IUniswapRouterETH(unirouter).swapExactTokensForTokens(_amount, 0, nativeToStargateInput, address(this), block.timestamp);
      for (uint256 i=0; i<swapLen; i++) {
        uint256 iamount = _amount * _swaps[i].poolCnts / _totalPools;
        if (iamount > 0) {
          _stgBridgeSwap(_swaps[i], swFees[i], iamount);
        }
      }
    }
  }

  function _stgBridgeSwap(StragateSwapInfo memory _swap, uint256 _swfee, uint256 _iamount) internal {
    uint256 iamount = _cutBridgingFee(_iamount);
    IStargateRouter(stargaterouter).swap{value: _swfee}(
      _swap.chain,
      stargateSourcePoolId,
      _swap.dstPoolID,
      payable(address(this)),
      iamount,
      0,
      IStargateRouter.lzTxObj(0, 0, "0x"),
      abi.encodePacked(_swap.basketAddress),
      bytes("")
    );
  }

  function _lcBridgeSwap(address _account, BridgeSwapInfo[] memory _swaps, uint256 _coinAmount, uint256 _totalPools) internal {
    uint256 swLen = _swaps.length;
    for (uint256 i=0; i<swLen; i++) {
      uint256 amount = _coinAmount * _swaps[i].poolCnts / _totalPools;
      if (amount > 0) {
        ILiquidCryptoBridge_v2(bridge).swap{value: amount}(_swaps[i].bridgeAddress, _account, _swaps[i].chain);
      }
    }
  }

  function _deposit(address account, PoolInfo memory pool, uint256 amount, bool move) private {
    _approveTokenIfNeeded(pool.path[0], pool.router);
    if (pool.path.length > 1) {
      uint256[] memory amounts = IUniswapRouterETH(pool.router).swapExactTokensForTokens(amount, 0, pool.path, address(this), block.timestamp);
      amount = amounts[amounts.length - 1];
    }
    _approveTokenIfNeeded(pool.path[pool.path.length-1], pool.liquidCZap);
    ILiquidCZapUniswapV2(pool.liquidCZap).LiquidCIn(pool.vault, 0, pool.path[pool.path.length-1], amount);
    uint256 xlpbalance = IERC20(pool.vault).balanceOf(address(this));
    if (move) {
      IERC20(pool.vault).transfer(account, xlpbalance);
    }
    else {
      _approveTokenIfNeeded(pool.vault, ledger);
      IBasketLedger(ledger).deposit(account, pool.vault, xlpbalance);
    }
  }

  function setLedger(address _ledger) public onlyManager {
    ledger = _ledger;
  }

  function setBridge(address _bridge) public onlyManager {
    bridge = _bridge;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }
  
  function setStargateSwapFee(uint256 _stargateSwapFee) public onlyManager {
    stargateSwapFee = _stargateSwapFee;
  }

  function setStargateSwapFeeMultipler(uint256 _stargateSwapFeeMultipler) public onlyManager {
    stargateSwapFeeMultipler = _stargateSwapFeeMultipler;
  }

  function setStargateSwapFeeDivider(uint256 _stargateSwapFeeDivider) public onlyManager {
    stargateSwapFeeDivider = _stargateSwapFeeDivider;
  }

  function setManager(address _account, bool _access) public onlyOwner {
    managers[_account] = _access;
  }

  function withdrawBridgeRefundFee(uint256 _fee) public onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: _fee}("");
    require(success, "Failed to withdraw");
  }

  function _approveTokenIfNeeded(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).approve(spender, type(uint256).max);
    }
  }

  function _cutBridgingFee(uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * stargateSwapFee / stargateSwapFeeDivider;
      if (fee > 0) {
        uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(fee, 0, stargateInputToNative, address(this), block.timestamp);
        IWETH(native).withdraw(amounts[amounts.length-1]);
        (bool success2, ) = payable(treasury).call{value: amounts[amounts.length-1]}("");
        require(success2, "Failed to refund fee");
      }
      return _amount - fee;
    }
    return 0;
  }
}