// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import "./../interface/IUniswapRouterETH.sol";
import "./../interface/IWETH.sol";

import "./../interface/celerbridge/IBridge.sol";

contract CBridgeZapv1 is Ownable {
  using SafeERC20 for IERC20;

  mapping (address => bool) public managers;

  address public treasury;
  address public cbridge;
  uint32 public swapFee;
  uint32 public feeDecimal;

  event Amount(uint256 amount);

  constructor(
    address _cbridge,
    address _treasury
  ) {
    managers[msg.sender] = true;
    treasury = _treasury;
    cbridge = _cbridge;
    swapFee = 5000;
    feeDecimal = 1000000;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "CBridgeZapv1: !manager");
    _;
  }

  receive() external payable {
  }

  function swap(address _token, uint256 _amount, address _unirouter, address[] memory _path, address[] memory _feepath, address _to, uint64 _desChain) public payable {
    if (_token != address(0)) {
      IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    uint256 fee = _amount * swapFee / feeDecimal;
    if (fee > 0) {
      if (_token == address(0)) {
        (bool success, ) = treasury.call{value: fee}("");
        require(success, "CBridgeZapv1: cut fee");
        IWETH(_path[0]).deposit{value: address(this).balance}();
      }
      else {
        if (_feepath.length > 1) {
          _approveTokenIfNeeded(_token, _unirouter);
          uint256[] memory amounts = IUniswapRouterETH(_unirouter).swapExactTokensForTokens(fee, 0, _feepath, address(this), block.timestamp);
          fee = amounts[amounts.length-1];
        }
        IWETH(_feepath[_feepath.length-1]).withdraw(fee);
        (bool success, ) = treasury.call{value: fee}("");
        require(success, "CBridgeZapv1: cut fee");
      }
    }

    if (_token == address(0) && address(this).balance > 0) {
      IWETH(_path[0]).deposit{value: address(this).balance}();
    }

    if (_path.length > 1) {
      _approveTokenIfNeeded(_path[0], _unirouter);
      IUniswapRouterETH(_unirouter).swapExactTokensForTokens(IERC20(_path[0]).balanceOf(address(this)), 0, _path, address(this), block.timestamp);
    }
    _amount = IERC20(_path[_path.length-1]).balanceOf(address(this));

    uint64 nonce = uint64(block.timestamp);
    _approveTokenIfNeeded(_path[_path.length-1], cbridge);
    IBridge(cbridge).send(_to, _path[_path.length-1], _amount, _desChain, nonce, feeDecimal);
  }

  function refund(
    bytes calldata _wdmsg,
    bytes[] calldata _sigs,
    address[] calldata _signers,
    uint256[] calldata _powers,
    address _token
  ) public {
    IBridge(cbridge).withdraw(_wdmsg, _sigs, _signers, _powers);

    if (_token == address(0)) {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "CBridgeZapv1: refund");
    }
    else {
      IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
  }

  function setCbridge(address _cbridge) public onlyManager {
    cbridge = _cbridge;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }
  
  function setSwapFee(uint32 _swapFee) public onlyManager {
    swapFee = _swapFee;
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
}