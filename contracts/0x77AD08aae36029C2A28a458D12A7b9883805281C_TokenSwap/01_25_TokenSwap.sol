//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 

import "./TokenPaymaster.sol";

contract TokenSwap is BaseRelayRecipient {

  event Received(uint256 value, address sender);

  IUniswapV2Router02 internal immutable _router;
  TokenPaymaster internal _paymaster;

  address private _sender;

  bool onSwap;

  modifier updateSender {
    require(!onSwap, "On swap");
    onSwap = true;
    // require(isTrustedForwarder(msg.sender), "Not forwarder");
    _sender = BaseRelayRecipient._msgSender();
    _;
  }
  
  constructor(address _forwarder, address uniswapRouter, address payable tokenPaymaster) {
    _setTrustedForwarder(_forwarder);
    _router = IUniswapV2Router02(uniswapRouter);
    _paymaster = TokenPaymaster(tokenPaymaster);
  }

  function _getPath(address token1, address token2) private pure returns(address[] memory path) {
    path = new address[](2);
    path[0] = token1;
    path[1] = token2;
  }

  function swapTokensForEth(address token, uint256 amountIn) external updateSender { 
    IERC20 erc20 = IERC20(token);
    erc20.transferFrom(_sender, address(this), amountIn);
    erc20.approve(address(_router), amountIn);

    _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amountIn,
      0,
      _getPath(token, _router.WETH()),
      address(this),
      block.timestamp
    );

    (address paymentToken, uint256 fee) = _paymaster.getPaymentData();
    if (fee > 0) {
      IERC20(paymentToken).transferFrom(_sender, address(0xdead), fee);
    }
  }  

  function versionRecipient() external override pure returns(string memory) {
    return "2.2.0+opengsn.swap.irelayrecipient";
  }

  receive() external payable {
    uint256 value = msg.value;
    (bool sent, ) = address(_paymaster).call{value: value}("");
    require(sent, "Failed to send Ether");
    emit Received(msg.value, _sender);
    onSwap = false;
  }

}