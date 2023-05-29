// SPDX-License-Identifier: MIT
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

contract MetaAggregationRouterV2 is Permitable, Ownable {
  using SafeERC20 for IERC20;

  address public immutable WETH;
  address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  uint256 private constant _PARTIAL_FILL = 0x01;
  uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
  uint256 private constant _SHOULD_CLAIM = 0x04;
  uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
  uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;
  uint256 private constant _SIMPLE_SWAP = 0x20;
  uint256 private constant _FEE_ON_DST = 0x40;
  uint256 private constant _FEE_IN_BPS = 0x80;
  uint256 private constant _APPROVE_FUND = 0x100;

  uint256 private constant BPS = 10000;

  mapping(address => bool) public isWhitelist;

  struct SwapDescriptionV2 {
    IERC20 srcToken;
    IERC20 dstToken;
    address[] srcReceivers; // transfer src token to these addresses, default
    uint256[] srcAmounts;
    address[] feeReceivers;
    uint256[] feeAmounts;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  /// @dev  use for swapGeneric and swap to avoid stack too deep
  struct SwapExecutionParams {
    address callTarget; // call this address
    address approveTarget; // approve this address if _APPROVE_FUND set
    bytes targetData;
    SwapDescriptionV2 desc;
    bytes clientData;
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

  event Fee(address token, uint256 totalAmount, uint256 totalFee, address[] recipients, uint256[] amounts, bool isBps);

  constructor(address _WETH) {
    WETH = _WETH;
  }

  receive() external payable {}

  function rescueFunds(address token, uint256 amount) external onlyOwner {
    if (_isETH(IERC20(token))) {
      TransferHelper.safeTransferETH(msg.sender, amount);
    } else {
      TransferHelper.safeTransfer(token, msg.sender, amount);
    }
  }

  function updateWhitelist(address[] memory addr, bool[] memory value) external onlyOwner {
    require(addr.length == value.length);
    for (uint256 i; i < addr.length; ++i) {
      isWhitelist[addr[i]] = value[i];
    }
  }

  function swapGeneric(SwapExecutionParams calldata execution)
    external
    payable
    returns (uint256 returnAmount, uint256 gasUsed)
  {
    uint256 gasBefore = gasleft();
    require(isWhitelist[execution.callTarget], 'Address not whitelisted');
    if (execution.approveTarget != execution.callTarget && execution.approveTarget != address(0)) {
      require(isWhitelist[execution.approveTarget], 'Address not whitelisted');
    }
    SwapDescriptionV2 memory desc = execution.desc;
    require(desc.minReturnAmount > 0, 'Invalid min return amount');

    // if extra eth is needed, in case srcToken is ETH
    _collectExtraETHIfNeeded(desc);
    _permit(desc.srcToken, desc.amount, desc.permit);

    bool feeInBps = _flagsChecked(desc.flags, _FEE_IN_BPS);
    uint256 spentAmount;
    address dstReceiver = desc.dstReceiver == address(0) ? msg.sender : desc.dstReceiver;
    if (!_flagsChecked(desc.flags, _FEE_ON_DST)) {
      // fee on src token
      // take fee on srcToken

      // take fee and deduct total amount
      desc.amount = _takeFee(desc.srcToken, msg.sender, desc.feeReceivers, desc.feeAmounts, desc.amount, feeInBps);

      bool collected;
      if (!_isETH(desc.srcToken) && _flagsChecked(desc.flags, _SHOULD_CLAIM)) {
        (collected, desc.amount) = _collectTokenIfNeeded(desc, msg.sender, address(this));
      }

      _transferFromOrApproveTarget(msg.sender, execution.approveTarget, desc, collected);
      // execute swap
      (spentAmount, returnAmount) = _executeSwap(
        execution.callTarget,
        execution.targetData,
        desc,
        _isETH(desc.srcToken) ? desc.amount : 0,
        dstReceiver
      );
    } else {
      bool collected;
      if (!_isETH(desc.srcToken) && _flagsChecked(desc.flags, _SHOULD_CLAIM)) {
        (collected, desc.amount) = _collectTokenIfNeeded(desc, msg.sender, address(this));
      }

      uint256 initialDstReceiverBalance = _getBalance(desc.dstToken, dstReceiver);
      _transferFromOrApproveTarget(msg.sender, execution.approveTarget, desc, collected);
      // fee on dst token
      // router get dst token first
      (spentAmount, returnAmount) = _executeSwap(
        execution.callTarget,
        execution.targetData,
        desc,
        _isETH(desc.srcToken) ? msg.value : 0,
        address(this)
      );
      {
        // then take fee on dst token
        uint256 leftAmount = _takeFee(
          desc.dstToken,
          address(this),
          desc.feeReceivers,
          desc.feeAmounts,
          returnAmount,
          feeInBps
        );
        _doTransferERC20(desc.dstToken, address(this), dstReceiver, leftAmount);
      }

      returnAmount = _getBalance(desc.dstToken, dstReceiver) - initialDstReceiverBalance;
    }
    // check return amount
    _checkReturnAmount(spentAmount, returnAmount, desc);
    //revoke allowance
    if (!_isETH(desc.srcToken) && execution.approveTarget != address(0)) {
      desc.srcToken.safeApprove(execution.approveTarget, 0);
    }

    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, spentAmount, returnAmount);
    emit Exchange(execution.callTarget, returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(execution.clientData);
    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function swap(SwapExecutionParams calldata execution)
    external
    payable
    returns (uint256 returnAmount, uint256 gasUsed)
  {
    uint256 gasBefore = gasleft();
    SwapDescriptionV2 memory desc = execution.desc;

    require(desc.minReturnAmount > 0, 'Min return should not be 0');
    require(execution.targetData.length > 0, 'executorData should be not zero');

    // simple mode swap
    if (_flagsChecked(desc.flags, _SIMPLE_SWAP)) {
      return
        swapSimpleMode(IAggregationExecutor(execution.callTarget), desc, execution.targetData, execution.clientData);
    }

    _collectExtraETHIfNeeded(desc);
    _permit(desc.srcToken, desc.amount, desc.permit);

    bool feeInBps = _flagsChecked(desc.flags, _FEE_IN_BPS);
    uint256 spentAmount;
    address dstReceiver = desc.dstReceiver == address(0) ? msg.sender : desc.dstReceiver;
    if (!_flagsChecked(desc.flags, _FEE_ON_DST)) {
      // fee on src token
      {
        // take fee on srcToken
        // deduct total swap amount
        desc.amount = _takeFee(
          desc.srcToken,
          msg.sender,
          desc.feeReceivers,
          desc.feeAmounts,
          _isETH(desc.srcToken) ? msg.value : desc.amount,
          feeInBps
        );

        // transfer fund from msg.sender to our executor
        _transferFromOrApproveTarget(msg.sender, address(0), desc, false);

        // execute swap
        (spentAmount, returnAmount) = _executeSwap(
          execution.callTarget,
          abi.encodeWithSelector(IAggregationExecutor.callBytes.selector, execution.targetData),
          desc,
          _isETH(desc.srcToken) ? desc.amount : 0,
          dstReceiver
        );
      }
    } else {
      // fee on dst token
      // router get dst token first
      uint256 initialDstReceiverBalance = _getBalance(desc.dstToken, dstReceiver);

      // transfer fund from msg.sender to our executor
      _transferFromOrApproveTarget(msg.sender, address(0), desc, false);

      // swap to receive dstToken on this router
      (spentAmount, returnAmount) = _executeSwap(
        execution.callTarget,
        abi.encodeWithSelector(IAggregationExecutor.callBytes.selector, execution.targetData),
        desc,
        _isETH(desc.srcToken) ? msg.value : 0,
        address(this)
      );

      {
        // then take fee on dst token
        uint256 leftAmount = _takeFee(
          desc.dstToken,
          address(this),
          desc.feeReceivers,
          desc.feeAmounts,
          returnAmount,
          feeInBps
        );
        _doTransferERC20(desc.dstToken, address(this), dstReceiver, leftAmount);
      }

      returnAmount = _getBalance(desc.dstToken, dstReceiver) - initialDstReceiverBalance;
    }
    _checkReturnAmount(spentAmount, returnAmount, desc);

    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, spentAmount, returnAmount);
    emit Exchange(execution.callTarget, returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(execution.clientData);

    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function swapSimpleMode(
    IAggregationExecutor caller,
    SwapDescriptionV2 memory desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) public returns (uint256 returnAmount, uint256 gasUsed) {
    uint256 gasBefore = gasleft();

    require(!_isETH(desc.srcToken), 'src is eth, should use normal swap');

    _permit(desc.srcToken, desc.amount, desc.permit);

    address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
    {
      bool isBps = _flagsChecked(desc.flags, _FEE_IN_BPS);
      if (!_flagsChecked(desc.flags, _FEE_ON_DST)) {
        // take fee and deduct total swap amount
        desc.amount = _takeFee(desc.srcToken, msg.sender, desc.feeReceivers, desc.feeAmounts, desc.amount, isBps);
      } else {
        dstReceiver = address(this);
      }
    }

    uint256 initialDstBalance = _getBalance(desc.dstToken, dstReceiver);
    uint256 initialSrcBalance = _getBalance(desc.srcToken, msg.sender);
    _swapMultiSequencesWithSimpleMode(
      caller,
      address(desc.srcToken),
      desc.amount,
      address(desc.dstToken),
      dstReceiver,
      executorData
    );

    // amount returned to this router
    returnAmount = _getBalance(desc.dstToken, dstReceiver) - initialDstBalance;
    {
      // take fee
      if (_flagsChecked(desc.flags, _FEE_ON_DST)) {
        {
          bool isBps = _flagsChecked(desc.flags, _FEE_IN_BPS);
          returnAmount = _takeFee(
            desc.dstToken,
            address(this),
            desc.feeReceivers,
            desc.feeAmounts,
            returnAmount,
            isBps
          );
        }

        IERC20 dstToken = desc.dstToken;
        dstReceiver = desc.dstReceiver == address(0) ? msg.sender : desc.dstReceiver;
        // dst receiver initial balance
        initialDstBalance = _getBalance(dstToken, dstReceiver);

        // transfer remainning token to dst receiver
        _doTransferERC20(dstToken, address(this), dstReceiver, returnAmount);

        // amount returned to dst receiver
        returnAmount = _getBalance(dstToken, dstReceiver) - initialDstBalance;
      }
    }
    uint256 spentAmount = initialSrcBalance - _getBalance(desc.srcToken, msg.sender);
    _checkReturnAmount(spentAmount, returnAmount, desc);
    emit Swapped(msg.sender, desc.srcToken, desc.dstToken, dstReceiver, spentAmount, returnAmount);
    emit Exchange(address(caller), returnAmount, _isETH(desc.dstToken) ? WETH : address(desc.dstToken));
    emit ClientData(clientData);

    unchecked {
      gasUsed = gasBefore - gasleft();
    }
  }

  function _doTransferERC20(
    IERC20 token,
    address from,
    address to,
    uint256 amount
  ) internal {
    require(from != to, 'sender != recipient');
    if (amount > 0) {
      if (_isETH(token)) {
        if (from == address(this)) TransferHelper.safeTransferETH(to, amount);
      } else {
        if (from == address(this)) {
          TransferHelper.safeTransfer(address(token), to, amount);
        } else {
          TransferHelper.safeTransferFrom(address(token), from, to, amount);
        }
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
      {
        uint256 balanceBefore = _getBalance(IERC20(tokenIn), msg.sender);
        _doTransferERC20(IERC20(tokenIn), msg.sender, swapData.firstPools[i], swapData.firstSwapAmounts[i]);
        require(swapData.firstSwapAmounts[i] <= totalSwapAmount, 'invalid swap amount');
        uint256 spentAmount = balanceBefore - _getBalance(IERC20(tokenIn), msg.sender);
        totalSwapAmount -= spentAmount;
      }
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

  /// @dev this function calls to external contract to execute swap and also validate the returned amounts
  function _executeSwap(
    address callTarget,
    bytes memory targetData,
    SwapDescriptionV2 memory desc,
    uint256 value,
    address dstReceiver
  ) internal returns (uint256 spentAmount, uint256 returnAmount) {
    uint256 initialDstBalance = _getBalance(desc.dstToken, dstReceiver);
    uint256 routerInitialSrcBalance = _getBalance(desc.srcToken, address(this));
    uint256 routerInitialDstBalance = _getBalance(desc.dstToken, address(this));
    {
      // call to external contract
      (bool success, ) = callTarget.call{value: value}(targetData);
      require(success, 'Call failed');
    }

    // if the `callTarget` returns amount to `msg.sender`, meaning this contract
    if (dstReceiver != address(this)) {
      uint256 stuckAmount = _getBalance(desc.dstToken, address(this)) - routerInitialDstBalance;
      _doTransferERC20(desc.dstToken, address(this), dstReceiver, stuckAmount);
    }

    // safe check here
    returnAmount = _getBalance(desc.dstToken, dstReceiver) - initialDstBalance;
    spentAmount = desc.amount;

    //should refund tokens router collected when partial fill
    if (
      _flagsChecked(desc.flags, _PARTIAL_FILL) && (_isETH(desc.srcToken) || _flagsChecked(desc.flags, _SHOULD_CLAIM))
    ) {
      uint256 currBalance = _getBalance(desc.srcToken, address(this));
      if (currBalance != routerInitialSrcBalance) {
        spentAmount = routerInitialSrcBalance - currBalance;
        _doTransferERC20(desc.srcToken, address(this), msg.sender, desc.amount - spentAmount);
      }
    }
  }

  function _collectExtraETHIfNeeded(SwapDescriptionV2 memory desc) internal {
    bool srcETH = _isETH(desc.srcToken);
    if (_flagsChecked(desc.flags, _REQUIRES_EXTRA_ETH)) {
      require(msg.value > (srcETH ? desc.amount : 0), 'Invalid msg.value');
    } else {
      require(msg.value == (srcETH ? desc.amount : 0), 'Invalid msg.value');
    }
  }

  function _collectTokenIfNeeded(
    SwapDescriptionV2 memory desc,
    address from,
    address to
  ) internal returns (bool collected, uint256 amount) {
    require(!_isETH(desc.srcToken), 'Claim token is ETH');
    uint256 initialRouterSrcBalance = _getBalance(desc.srcToken, address(this));
    _doTransferERC20(desc.srcToken, from, to, desc.amount);
    collected = true;
    amount = _getBalance(desc.srcToken, address(this)) - initialRouterSrcBalance;
  }

  /// @dev transfer fund to `callTarget` or approve `approveTarget`
  function _transferFromOrApproveTarget(
    address from,
    address approveTarget,
    SwapDescriptionV2 memory desc,
    bool collected
  ) internal {
    // if token is collected
    require(desc.srcReceivers.length == desc.srcAmounts.length, 'invalid srcReceivers length');
    if (collected) {
      if (_flagsChecked(desc.flags, _APPROVE_FUND) && approveTarget != address(0)) {
        // approve to approveTarget since some systems use an allowance proxy contract
        desc.srcToken.safeIncreaseAllowance(approveTarget, desc.amount);
        return;
      }
    }
    uint256 total;
    for (uint256 i; i < desc.srcReceivers.length; ++i) {
      total += desc.srcAmounts[i];
      _doTransferERC20(desc.srcToken, collected ? address(this) : from, desc.srcReceivers[i], desc.srcAmounts[i]);
    }
    require(total <= desc.amount, 'Exceeded desc.amount');
  }

  /// @dev token transferred from `from` to `feeData.recipients`
  function _takeFee(
    IERC20 token,
    address from,
    address[] memory recipients,
    uint256[] memory amounts,
    uint256 totalAmount,
    bool inBps
  ) internal returns (uint256 leftAmount) {
    leftAmount = totalAmount;
    uint256 recipientsLen = recipients.length;
    if (recipientsLen > 0) {
      bool isETH = _isETH(token);
      uint256 balanceBefore = _getBalance(token, isETH ? address(this) : from);
      require(amounts.length == recipientsLen, 'Invalid length');
      for (uint256 i; i < recipientsLen; ++i) {
        uint256 amount = inBps ? (totalAmount * amounts[i]) / BPS : amounts[i];
        _doTransferERC20(token, isETH ? address(this) : from, recipients[i], amount);
      }
      uint256 totalFee = balanceBefore - _getBalance(token, isETH ? address(this) : from);
      leftAmount = totalAmount - totalFee;
      emit Fee(address(token), totalAmount, totalFee, recipients, amounts, inBps);
    }
  }

  function _checkReturnAmount(
    uint256 spentAmount,
    uint256 returnAmount,
    SwapDescriptionV2 memory desc
  ) internal pure {
    if (_flagsChecked(desc.flags, _PARTIAL_FILL)) {
      require(returnAmount * desc.amount >= desc.minReturnAmount * spentAmount, 'Return amount is not enough');
    } else {
      require(returnAmount >= desc.minReturnAmount, 'Return amount is not enough');
    }
  }

  function _flagsChecked(uint256 number, uint256 flag) internal pure returns (bool) {
    return number & flag != 0;
  }
}