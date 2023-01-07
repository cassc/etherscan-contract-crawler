// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import "./../interface/IUniswapRouterETH.sol";
import "./../interface/IWETH.sol";

import "./../interface/stargate/IStargateRouter.sol";

contract StgBridgeZapv1 is Ownable {
  using SafeERC20 for IERC20;

  mapping (address => bool) public managers;

  address public treasury;
  address public stargaterouter;
  uint256 public stargateSwapFeeMultipler = 1400000;
  uint256 public stargateSwapFeeDivider = 1000000;
  uint256 public stargateSwapFee = 600;

  constructor(
    address _stargaterouter,
    address _treasury
  ) {
    managers[msg.sender] = true;
    treasury = _treasury;
    stargaterouter = _stargaterouter;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "LiquidC Basket v3: !manager");
    _;
  }

  receive() external payable {
  }

  function getStgSwapFee(uint16 _desChain) public view returns(uint256) {
    (uint256 swFee, ) = IStargateRouter(stargaterouter).quoteLayerZeroFee(
      _desChain,
      1,
      bytes("0x"),
      bytes("0x"),
      IStargateRouter.lzTxObj(0, 0, "0x")
    );
    return swFee * stargateSwapFeeMultipler / stargateSwapFeeDivider;
  }

  function swap(address _token, uint256 _amount, address _unirouter, address[] memory _path, address _to, uint16 _desChain, uint256 _srcPoolId, uint256 _desPoolId) public payable {
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 iamount = _cutBridgingFee(_amount, _unirouter, _path);
    if (iamount > 0) {
      _stgSwapAndRefundChange(_token, iamount, _to, _desChain, _srcPoolId, _desPoolId, msg.value);
    }
  }

  function swapFromCoin(address _unirouter, address[] memory _path, uint16 _desChain, address _to, uint256 _srcPoolId, uint256 _desPoolId) public payable {
    uint256 iamount = _cutBridgingFeeFromCoin(msg.value);

    uint256 fee = getStgSwapFee(_desChain);

    if (iamount > fee) {
      iamount -= fee;
      IWETH(_path[0]).deposit{value: iamount}();
      _approveTokenIfNeeded(_path[0], _unirouter);
      uint256[] memory amounts = IUniswapRouterETH(_unirouter).swapExactTokensForTokens(iamount, 0, _path, address(this), block.timestamp);
      _removeAllowances(_path[0], _unirouter);
      
      _stgSwapAndRefundChange(_path[_path.length-1], amounts[amounts.length-1], _to, _desChain, _srcPoolId, _desPoolId, fee);
    }
    else {
      _refundChange();
    }
  }

  function _stgSwapAndRefundChange(address _token, uint256 _amount, address _to, uint16 _desChain, uint256 _srcPoolId, uint256 _desPoolId, uint256 _fee) private {
    _approveTokenIfNeeded(_token, stargaterouter);
    IStargateRouter(stargaterouter).swap{value: _fee}(
      _desChain,
      _srcPoolId,
      _desPoolId,
      payable(msg.sender),
      _amount,
      0,
      IStargateRouter.lzTxObj(0, 0, "0x"),
      abi.encodePacked(_to),
      bytes("")
    );
    _removeAllowances(_token, stargaterouter);

    _refundChange();
  }

  function _refundChange() private {
    if (address(this).balance > 0) {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "StgBridgeZapv1: Failed refund change");
    }
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

  function _removeAllowances(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) > 0) {
      IERC20(token).approve(spender, 0);
    }
  }

  function _cutBridgingFee(uint256 _amount, address _unirouter, address[] memory _path) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * stargateSwapFee / stargateSwapFeeDivider;
      if (fee > 0) {
        _approveTokenIfNeeded(_path[0], _unirouter);
        uint256[] memory amounts = IUniswapRouterETH(_unirouter).swapExactTokensForTokens(fee, 0, _path, address(this), block.timestamp);
        _removeAllowances(_path[0], _unirouter);
        IWETH(_path[_path.length-1]).withdraw(amounts[amounts.length-1]);
        (bool success, ) = payable(treasury).call{value: amounts[amounts.length-1]}("");
        require(success, "StgBridgeZapv1: send fee");
      }
      return _amount - fee;
    }
    return 0;
  }

  function _cutBridgingFeeFromCoin(uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * stargateSwapFee / stargateSwapFeeDivider;
      if (fee > 0) {
        (bool success, ) = payable(treasury).call{value: fee}("");
        require(success, "StgBridgeZapv1: send fee");
      }
      return _amount - fee;
    }
    return 0;
  }
}