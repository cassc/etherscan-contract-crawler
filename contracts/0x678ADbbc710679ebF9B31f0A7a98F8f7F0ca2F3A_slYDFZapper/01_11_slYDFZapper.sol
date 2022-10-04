/******************************************************************************************************
Staked Yieldification Liquidity Zapper

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IslYDF.sol';

contract slYDFZapper is IERC721Receiver {
  address _uniswapRouter;
  IERC20 ydf;
  IslYDF _slYDF;

  event ZapETHOnly(address indexed user, uint256 amountETH);
  event ZapYDFOnly(address indexed user, uint256 amountYDF);
  event ZapETHAndYDF(
    address indexed user,
    uint256 amountETH,
    uint256 amountYDF
  );

  constructor(
    address _router,
    address _ydf,
    address __slYDF
  ) {
    _uniswapRouter = _router;
    ydf = IERC20(_ydf);
    _slYDF = IslYDF(__slYDF);
  }

  function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256, /* tokenId */
    bytes calldata /* data */
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function zapAndStakeETHOnly(
    uint256 _minTokensToReceive, // should assume full msg.value is swapped
    uint256 _lockOptIndex
  ) external payable {
    require(msg.value > 0, 'need to provide ETH to zap');

    uint256 _ethBalBefore = address(this).balance - msg.value;
    uint256 _ydfBalanceBefore = ydf.balanceOf(address(this));
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);

    // swap half the ETH for YDF
    address[] memory path = new address[](2);
    path[0] = _uniswapV2Router.WETH();
    path[1] = address(ydf);
    _uniswapV2Router.swapExactETHForTokens{ value: msg.value / 2 }(
      _minTokensToReceive / 2,
      path,
      address(this),
      block.timestamp
    );

    _addAndStakeLp(
      msg.sender,
      ydf.balanceOf(address(this)) - _ydfBalanceBefore,
      msg.value / 2,
      _lockOptIndex
    );

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalanceBefore);

    emit ZapETHOnly(msg.sender, msg.value);
  }

  function zapAndStakeETHAndYDF(uint256 _amountYDF, uint256 _lockOptIndex)
    external
    payable
  {
    require(msg.value > 0, 'need to provide ETH to zap');

    uint256 _ethBalBefore = address(this).balance - msg.value;
    uint256 _ydfBalBefore = ydf.balanceOf(address(this));
    ydf.transferFrom(msg.sender, address(this), _amountYDF);
    uint256 _ydfToProcess = ydf.balanceOf(address(this)) - _ydfBalBefore;

    _addAndStakeLp(msg.sender, _ydfToProcess, msg.value, _lockOptIndex);

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalBefore);

    emit ZapETHAndYDF(msg.sender, msg.value, _amountYDF);
  }

  function zapAndStakeYDFOnly(
    uint256 _amountYDF,
    uint256 _minETHToReceive, // should assume full _amountYDF is swapped
    uint256 _lockOptIndex
  ) external {
    require(
      _lockOptIndex > 0,
      'cannot zap and stake YDF only without lockup period'
    );
    uint256 _ethBalBefore = address(this).balance;
    uint256 _ydfBalBefore = ydf.balanceOf(address(this));
    ydf.transferFrom(msg.sender, address(this), _amountYDF);
    uint256 _ydfToProcess = ydf.balanceOf(address(this)) - _ydfBalBefore;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);

    // swap half the YDF for ETH
    address[] memory path = new address[](2);
    path[0] = address(ydf);
    path[1] = _uniswapV2Router.WETH();
    ydf.approve(address(_uniswapV2Router), _ydfToProcess / 2);
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _ydfToProcess / 2,
      _minETHToReceive / 2,
      path,
      address(this),
      block.timestamp
    );

    _addAndStakeLp(
      msg.sender,
      _ydfToProcess / 2,
      address(this).balance - _ethBalBefore,
      _lockOptIndex
    );

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalBefore);

    emit ZapYDFOnly(msg.sender, _amountYDF);
  }

  function _addAndStakeLp(
    address _user,
    uint256 _amountYDF,
    uint256 _amounETH,
    uint256 _lockOptIndex
  ) internal {
    ydf.approve(address(_slYDF), _amountYDF);
    _slYDF.zapAndStakeETHAndYDF{ value: _amounETH }(_amountYDF, _lockOptIndex);
    uint256[] memory _tokenIds = _slYDF.getAllUserOwned(address(this));
    uint256 _tokenId = _tokenIds[0];
    _slYDF.transferFrom(address(this), _user, _tokenId);
  }

  function _returnExcessETH(address _user, uint256 _initialBal) internal {
    if (address(this).balance > _initialBal) {
      payable(_user).call{ value: address(this).balance - _initialBal }('');
      require(address(this).balance >= _initialBal, 'took too much');
    }
  }

  function _returnExcessYDF(address _user, uint256 _initialBal) internal {
    uint256 _currentBal = ydf.balanceOf(address(this));
    if (_currentBal > _initialBal) {
      ydf.transfer(_user, _currentBal - _initialBal);
      require(ydf.balanceOf(address(this)) >= _initialBal, 'took too much');
    }
  }

  receive() external payable {}
}