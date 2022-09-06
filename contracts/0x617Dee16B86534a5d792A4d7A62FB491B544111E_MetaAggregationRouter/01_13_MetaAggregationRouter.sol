// SPDX-License-Identifier: MIT

/// Copyright (c) 2019-2021 1inch
/// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
/// and associated documentation files (the "Software"), to deal in the Software without restriction,
/// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
/// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
/// subject to the following conditions:
/// The above copyright notice and this permission notice shall be included in all copies or
/// substantial portions of the Software.
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
/// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
/// AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
/// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
/// OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './dependency/Permitable.sol';
import './interfaces/IAggregationExecutor.sol';
import './interfaces/IAggregationExecutor1Inch.sol';
import './libraries/TransferHelper.sol';
import './libraries/RevertReasonParser.sol';

contract MetaAggregationRouter is Permitable, Ownable {
  using SafeERC20 for IERC20;

  address public immutable WETH;
  address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  uint256 private constant _PARTIAL_FILL = 0x01;
  uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
  uint256 private constant _SHOULD_CLAIM = 0x04;
  uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
  uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;
  uint256 private constant _SIMPLE_SWAP = 0x20;

  mapping(address => bool) public isWhitelist;

  struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address[] srcReceivers;
    uint256[] srcAmounts;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  struct SimpleSwapData {
    address[] firstPools;
    uint256[] firstSwapAmounts;
    bytes[] swapDatas;
    uint256 deadline;
    bytes destTokenFeeData;
  }

  event Swapped(
    address sender,
    IERC20 srcToken,
    IERC20 dstToken,
    address dstReceiver,
    uint256 spentAmount,
    uint256 returnAmount
  );

  event ClientData(bytes clientData);

  event Exchange(address pair, uint256 amountOut, address output);

  constructor(address _WETH) {
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH);
    // only accept ETH via fallback from the WETH contract
  }

  function rescueFunds(address token, uint256 amount) external onlyOwner {
    if (_isETH(IERC20(token))) {
      TransferHelper.safeTransferETH(msg.sender, amount);
    } else {
      TransferHelper.safeTransfer(token, msg.sender, amount);
    }
  }

  function updateWhitelist(address addr, bool value) external onlyOwner {
    isWhitelist[addr] = value;
  }

  function swapRouter1Inch(
    address router1Inch,
    bytes calldata router1InchData,
    SwapDescription calldata desc,
    bytes calldata clientData
  ) external payable returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();
    require(isWhitelist[router1Inch], 'not whitelist router');
    require(desc.minReturnAmount > 0, 'Min return should not be 0');
    require(
      desc.srcReceivers.length == desc.srcAmounts.length && desc.srcAmounts.length <= 1,
      'Invalid lengths for receiving src tokens'
    );

    uint256 val = msg.value;
    if (!_isETH(desc.srcToken)) {
      // transfer token to kyber router
      _permit(desc.srcToken, desc.amount, desc.permit);
      TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, address(this), desc.amount);

      // approve token to 1inch router
      uint256 amount = _getBalance(desc.srcToken, address(this));
      desc.srcToken.safeIncreaseAllowance(router1Inch, amount);

      // transfer fee to feeTaker
      for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
        TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, desc.srcReceivers[i], desc.srcAmounts[i]);
      }
    } else {
      for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
        val -= desc.srcAmounts[i];
        TransferHelper.safeTransferETH(desc.srcReceivers[i], desc.srcAmounts[i]);
      }
    }

    address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
    uint256 initialSrcBalance = (desc.flags & _PARTIAL_FILL != 0) ? _getBalance(desc.srcToken, msg.sender) : 0;
    uint256 initialDstBalance = _getBalance(desc.dstToken, dstReceiver);
    {
      // call to 1inch router contract
      (bool success, ) = router1Inch.call{value: val}(router1InchData);
      require(success, 'call to 1inch router fail');
    }

    // 1inch router return to msg.sender (mean fund will return to this address)
    uint256 stuckAmount = _getBalance(desc.dstToken, address(this));
    _doTransferERC20(desc.dstToken, dstReceiver, stuckAmount);

    // safe check here
    returnAmount = _getBalance(desc.dstToken, dstReceiver) - initialDstBalance;
    uint256 spentAmount = desc.amount;
    if (desc.flags & _PARTIAL_FILL != 0) {
      spentAmount = initialSrcBalance + desc.amount - _getBalance(desc.srcToken, msg.sender);
      require(returnAmount * desc.amount >= desc.minReturnAmount * spentAmount, 'Return amount is not enough');
    } else {
      require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
    }

    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, spentAmount, returnAmount);
    emit Exchange(router1Inch, returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(clientData);
    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function swapExecutor1Inch(
    IAggregationExecutor1Inch caller,
    SwapDescriptionExecutor1Inch calldata desc,
    bytes calldata executor1InchData,
    bytes calldata clientData
  ) external payable returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();
    require(desc.minReturnAmount > 0, 'Min return should not be 0');
    require(executor1InchData.length > 0, 'data should not be empty');
    require(desc.srcReceivers.length == desc.srcAmounts.length, 'invalid src receivers length');

    bool srcETH = _isETH(desc.srcToken);
    if (desc.flags & _REQUIRES_EXTRA_ETH != 0) {
      require(msg.value > (srcETH ? desc.amount : 0), 'Invalid msg.value');
    } else {
      require(msg.value == (srcETH ? desc.amount : 0), 'Invalid msg.value');
    }
    uint256 val = msg.value;
    if (!srcETH) {
      _permit(desc.srcToken, desc.amount, desc.permit);

      // transfer to fee taker
      uint256 srcReceiversLength = desc.srcReceivers.length;
      for (uint256 i = 0; i < srcReceiversLength; ) {
        TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, desc.srcReceivers[i], desc.srcAmounts[i]);
        unchecked {
          ++i;
        }
      }

      // transfer to 1inch srcReceiver
      TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, desc.srcReceiver1Inch, desc.amount);
    } else {
      // transfer to 1inch srcReceiver
      uint256 srcReceiversLength = desc.srcReceivers.length;
      for (uint256 i = 0; i < srcReceiversLength; ) {
        val -= desc.srcAmounts[i];
        TransferHelper.safeTransferETH(desc.srcReceivers[i], desc.srcAmounts[i]);
        unchecked {
          ++i;
        }
      }
    }

    {
      bytes memory callData = abi.encodePacked(caller.callBytes.selector, bytes12(0), msg.sender, executor1InchData);
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory result) = address(caller).call{value: val}(callData);
      if (!success) {
        revert(RevertReasonParser.parse(result, 'callBytes failed: '));
      }
    }

    uint256 spentAmount = desc.amount;
    returnAmount = _getBalance(desc.dstToken, address(this));

    if (desc.flags & _PARTIAL_FILL != 0) {
      uint256 unspentAmount = _getBalance(desc.srcToken, address(this));
      if (unspentAmount > 0) {
        spentAmount = spentAmount - unspentAmount;
        _doTransferERC20(desc.srcToken, msg.sender, unspentAmount);
      }

      require(returnAmount * desc.amount >= desc.minReturnAmount * spentAmount, 'Return amount is not enough');
    } else {
      require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
    }

    address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
    _doTransferERC20(desc.dstToken, dstReceiver, returnAmount);

    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, spentAmount, returnAmount);
    emit Exchange(address(caller), returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(clientData);
    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function swap(
    IAggregationExecutor caller,
    SwapDescription calldata desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) external payable returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();
    require(desc.minReturnAmount > 0, 'Min return should not be 0');
    require(executorData.length > 0, 'executorData should be not zero');

    uint256 flags = desc.flags;

    // simple mode swap
    if (flags & _SIMPLE_SWAP != 0) return swapSimpleMode(caller, desc, executorData, clientData);

    {
      IERC20 srcToken = desc.srcToken;
      if (flags & _REQUIRES_EXTRA_ETH != 0) {
        require(msg.value > (_isETH(srcToken) ? desc.amount : 0), 'Invalid msg.value');
      } else {
        require(msg.value == (_isETH(srcToken) ? desc.amount : 0), 'Invalid msg.value');
      }

      require(desc.srcReceivers.length == desc.srcAmounts.length, 'Invalid lengths for receiving src tokens');

      if (flags & _SHOULD_CLAIM != 0) {
        require(!_isETH(srcToken), 'Claim token is ETH');
        _permit(srcToken, desc.amount, desc.permit);
        for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
          TransferHelper.safeTransferFrom(address(srcToken), msg.sender, desc.srcReceivers[i], desc.srcAmounts[i]);
        }
      }

      if (_isETH(srcToken)) {
        // normally in case taking fee in srcToken and srcToken is the native token
        for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
          TransferHelper.safeTransferETH(desc.srcReceivers[i], desc.srcAmounts[i]);
        }
      }
    }

    {
      address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
      uint256 initialSrcBalance = (flags & _PARTIAL_FILL != 0) ? _getBalance(desc.srcToken, msg.sender) : 0;
      IERC20 dstToken = desc.dstToken;
      uint256 initialDstBalance = _getBalance(dstToken, dstReceiver);

      _callWithEth(caller, executorData);

      uint256 spentAmount = desc.amount;
      returnAmount = _getBalance(dstToken, dstReceiver) - initialDstBalance;

      if (flags & _PARTIAL_FILL != 0) {
        spentAmount = initialSrcBalance + desc.amount - _getBalance(desc.srcToken, msg.sender);
        require(returnAmount * desc.amount >= desc.minReturnAmount * spentAmount, 'Return amount is not enough');
      } else {
        require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
      }

      emit Swapped(msg.sender, desc.srcToken, dstToken, dstReceiver, spentAmount, returnAmount);
      emit Exchange(address(caller), returnAmount, _isETH(dstToken) ? WETH : address(dstToken));
      emit ClientData(clientData);
    }

    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function swapSimpleMode(
    IAggregationExecutor caller,
    SwapDescription calldata desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) public returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();

    require(!_isETH(desc.srcToken), 'src is eth, should use normal swap');
    _permit(desc.srcToken, desc.amount, desc.permit);

    uint256 totalSwapAmount = desc.amount;
    if (desc.srcReceivers.length > 0) {
      // take fee in tokenIn
      require(
        desc.srcReceivers.length == 1 && desc.srcReceivers.length == desc.srcAmounts.length,
        'Wrong number of src receivers'
      );
      TransferHelper.safeTransferFrom(address(desc.srcToken), msg.sender, desc.srcReceivers[0], desc.srcAmounts[0]);
      require(desc.srcAmounts[0] <= totalSwapAmount, 'invalid fee amount in src token');
      totalSwapAmount -= desc.srcAmounts[0];
    }
    address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
    uint256 initialDstBalance = _getBalance(desc.dstToken, dstReceiver);

    _swapMultiSequencesWithSimpleMode(
      caller,
      address(desc.srcToken),
      totalSwapAmount,
      address(desc.dstToken),
      dstReceiver,
      executorData
    );

    returnAmount = _getBalance(desc.dstToken, dstReceiver) - initialDstBalance;

    require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, desc.amount, returnAmount);
    emit Exchange(address(caller), returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(clientData);

    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function _doTransferERC20(
    IERC20 token,
    address to,
    uint256 amount
  ) internal {
    if (amount > 0) {
      if (_isETH(token)) {
        TransferHelper.safeTransferETH(to, amount);
      } else {
        TransferHelper.safeTransfer(address(token), to, amount);
      }
    }
  }

  // Only use this mode if the first pool of each sequence can receive tokenIn directly into the pool
  function _swapMultiSequencesWithSimpleMode(
    IAggregationExecutor caller,
    address tokenIn,
    uint256 totalSwapAmount,
    address tokenOut,
    address dstReceiver,
    bytes calldata data
  ) internal {
    SimpleSwapData memory swapData = abi.decode(data, (SimpleSwapData));
    require(swapData.deadline >= block.timestamp, 'ROUTER: Expired');
    require(
      swapData.firstPools.length == swapData.firstSwapAmounts.length &&
        swapData.firstPools.length == swapData.swapDatas.length,
      'invalid swap data length'
    );
    uint256 numberSeq = swapData.firstPools.length;
    for (uint256 i = 0; i < numberSeq; i++) {
      // collect amount to the first pool
      TransferHelper.safeTransferFrom(tokenIn, msg.sender, swapData.firstPools[i], swapData.firstSwapAmounts[i]);
      require(swapData.firstSwapAmounts[i] <= totalSwapAmount, 'invalid swap amount');
      totalSwapAmount -= swapData.firstSwapAmounts[i];
      {
        // solhint-disable-next-line avoid-low-level-calls
        // may take some native tokens for commission fee
        (bool success, bytes memory result) = address(caller).call(
          abi.encodeWithSelector(caller.swapSingleSequence.selector, swapData.swapDatas[i])
        );
        if (!success) {
          revert(RevertReasonParser.parse(result, 'swapSingleSequence failed: '));
        }
      }
    }
    {
      // solhint-disable-next-line avoid-low-level-calls
      // may take some native tokens for commission fee
      (bool success, bytes memory result) = address(caller).call(
        abi.encodeWithSelector(
          caller.finalTransactionProcessing.selector,
          tokenIn,
          tokenOut,
          dstReceiver,
          swapData.destTokenFeeData
        )
      );
      if (!success) {
        revert(RevertReasonParser.parse(result, 'finalTransactionProcessing failed: '));
      }
    }
  }

  function _getBalance(IERC20 token, address account) internal view returns (uint256) {
    if (_isETH(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function _isETH(IERC20 token) internal pure returns (bool) {
    return (address(token) == ETH_ADDRESS);
  }

  function _callWithEth(IAggregationExecutor caller, bytes calldata executorData) internal {
    // solhint-disable-next-line avoid-low-level-calls
    // may take some native tokens for commission fee
    uint256 ethAmount = _getBalance(IERC20(ETH_ADDRESS), address(this));
    if (ethAmount > msg.value) ethAmount = msg.value;
    (bool success, bytes memory result) = address(caller).call{value: ethAmount}(
      abi.encodeWithSelector(caller.callBytes.selector, executorData)
    );
    if (!success) {
      revert(RevertReasonParser.parse(result, 'callBytes failed: '));
    }
  }
}