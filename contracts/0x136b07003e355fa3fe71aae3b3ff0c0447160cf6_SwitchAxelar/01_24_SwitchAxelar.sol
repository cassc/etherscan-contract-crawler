// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "../dexs/Switch.sol";
import "../lib/DataTypes.sol";

contract SwitchAxelar is Switch, AxelarExecutable {
  using UniversalERC20 for IERC20;
  using SafeERC20 for IERC20;

  IAxelarGasService public immutable gasReceiver;

  // Used when no swap required on dest chain
  struct TransferArgsAxelar {
    address srcToken;
    address destToken;
    address recipient;
    address depositAddr;
    address partner;
    uint256 amount;
    uint256 bridgeDstAmount;
    uint64 nonce;
    uint256[] srcDistribution;
    bytes32 id;
    bytes32 bridge;
    bytes srcParaswapData;
    DataTypes.ParaswapUsageStatus paraswapUsageStatus;
  }

  // Used when swap required on dest chain
  struct SwapArgsAxelar {
    DataTypes.SwapInfo srcSwap;
    DataTypes.SwapInfo dstSwap;
    string bridgeTokenSymbol;
    address recipient;
    string callTo; // The address of the destination app contract.
    bool useNativeGas; // Indicate ETH or bridge token to pay axelar gas
    uint256 gasAmount; // Gas amount for axelar gmp
    address partner;
    uint256 amount;
    uint256 expectedReturn; // expected bridge token amount on sending chain
    uint256 minReturn; // minimum amount of bridge token
    uint256 bridgeDstAmount; // estimated token amount of bridgeToken
    uint256 estimatedDstTokenAmount; // estimated dest token amount on receiving chain
    uint256[] srcDistribution;
    uint256[] dstDistribution;
    bytes srcPreSwapData; // pre swap data on src chain to swap axl assets. Ex. swap axlUSDC to USDC, or USDC to axlUSDC
    bytes dstPreSwapData; // pre swap data on dst chain to swap axl assets. Ex. swap axlUSDC to USDC, or USDC to axlUSDC
    string dstChain;
    uint64 nonce;
    bytes32 id;
    bytes32 bridge;
    bytes srcParaswapData;
    bytes dstParaswapData;
    DataTypes.ParaswapUsageStatus paraswapUsageStatus;
  }

  struct AxelarSwapRequest {
    bytes32 id;
    bytes32 bridge;
    address recipient;
    address bridgeToken;
    address dstToken;
    DataTypes.ParaswapUsageStatus paraswapUsageStatus;
    bytes dstParaswapData;
    uint256[] dstDistribution;
    bytes dstPreSwapData;
    uint256 bridgeDstAmount;
  }

  constructor(
    address _weth,
    address _otherToken,
    uint256[] memory _pathCountAndSplit,
    address[] memory _factories,
    address _switchViewAddress,
    address _switchEventAddress,
    address _gateway,
    address _gasReceiver,
    address _paraswapProxy,
    address _augustusSwapper
  )
    Switch(
      _weth,
      _otherToken,
      _pathCountAndSplit[0],
      _pathCountAndSplit[1],
      _factories,
      _switchViewAddress,
      _switchEventAddress,
      _paraswapProxy,
      _augustusSwapper
    )
    AxelarExecutable(_gateway)
  {
    gasReceiver = IAxelarGasService(_gasReceiver);
  }

  receive() external payable {}

  function transferByAxelar(TransferArgsAxelar calldata transferArgs)
    external
    payable
    nonReentrant
    returns (bytes32 transferId)
  {
    require(transferArgs.amount > 0, "The amount must be greater than zero");

    IERC20(transferArgs.srcToken).universalTransferFrom(
      msg.sender,
      address(this),
      transferArgs.amount
    );
    uint256 amountAfterFee = _getAmountAfterFee(
      IERC20(transferArgs.srcToken),
      transferArgs.amount,
      transferArgs.partner
    );

    uint256 returnAmount = _swapInternal(
      transferArgs.srcToken,
      transferArgs.destToken,
      amountAfterFee,
      transferArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both ||
        transferArgs.paraswapUsageStatus ==
        DataTypes.ParaswapUsageStatus.OnSrcChain,
      transferArgs.srcParaswapData,
      transferArgs.srcDistribution
    );

    IERC20(transferArgs.destToken).universalTransfer(
      transferArgs.depositAddr,
      returnAmount
    );

    transferId = keccak256(
      abi.encodePacked(
        address(this),
        transferArgs.recipient,
        transferArgs.srcToken,
        returnAmount,
        transferArgs.depositAddr,
        transferArgs.nonce,
        uint64(block.chainid)
      )
    );

    _emitCrossChainTransferRequest(
      transferArgs,
      transferId,
      returnAmount,
      msg.sender,
      DataTypes.SwapStatus.Succeeded
    );
  }

  function swapByAxelar(SwapArgsAxelar calldata _swapArgs)
    external
    payable
    nonReentrant
    returns (bytes32 transferId)
  {
    SwapArgsAxelar memory swapArgs = _swapArgs;

    require(
      swapArgs.expectedReturn >= swapArgs.minReturn,
      "expectedReturn must be equal or larger than minReturn"
    );
    require(
      !IERC20(swapArgs.srcSwap.dstToken).isETH(),
      "src dest token must not be ETH"
    );

    if (IERC20(swapArgs.srcSwap.srcToken).isETH()) {
      if (swapArgs.useNativeGas) {
        require(
          msg.value == swapArgs.gasAmount + swapArgs.amount,
          "Incorrect Value"
        );
      } else {
        require(msg.value == swapArgs.amount, "Incorrect Value");
      }
    } else if (swapArgs.useNativeGas) {
      require(msg.value == swapArgs.gasAmount, "Incorrect Value");
    }

    IERC20(swapArgs.srcSwap.srcToken).universalTransferFrom(
      msg.sender,
      address(this),
      swapArgs.amount
    );

    uint256 srcAmount = IERC20(swapArgs.srcSwap.srcToken).isETH() &&
      swapArgs.useNativeGas
      ? swapArgs.amount - swapArgs.gasAmount
      : swapArgs.amount;

    uint256 amountAfterFee = _getAmountAfterFee(
      IERC20(swapArgs.srcSwap.srcToken),
      srcAmount,
      swapArgs.partner
    );

    uint256 returnAmount = amountAfterFee;

    if (
      IERC20(swapArgs.srcSwap.srcToken).isETH() &&
      swapArgs.srcSwap.dstToken == address(weth)
    ) {
      weth.deposit{ value: amountAfterFee }();
    } else if (swapArgs.srcSwap.srcToken != swapArgs.srcSwap.dstToken) {
      returnAmount = _swapInternal(
        swapArgs.srcSwap.srcToken,
        swapArgs.srcSwap.dstToken,
        amountAfterFee,
        swapArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both ||
          swapArgs.paraswapUsageStatus ==
          DataTypes.ParaswapUsageStatus.OnSrcChain,
        swapArgs.srcParaswapData,
        swapArgs.srcDistribution
      );
    }

    if (!swapArgs.useNativeGas) {
      returnAmount -= swapArgs.gasAmount;
    }

    require(returnAmount > 0, "The amount too small");
    require(
      returnAmount >= swapArgs.expectedReturn,
      "return amount is lower than expected"
    );

    transferId = keccak256(
      abi.encodePacked(
        address(this),
        swapArgs.recipient,
        swapArgs.srcSwap.srcToken,
        returnAmount,
        swapArgs.dstChain,
        swapArgs.nonce,
        uint64(block.chainid)
      )
    );

    bytes memory payload = abi.encode(
      AxelarSwapRequest({
        id: swapArgs.id,
        bridge: swapArgs.bridge,
        recipient: swapArgs.recipient,
        bridgeToken: swapArgs.dstSwap.srcToken,
        dstToken: swapArgs.dstSwap.dstToken,
        paraswapUsageStatus: swapArgs.paraswapUsageStatus,
        dstParaswapData: swapArgs.dstParaswapData,
        dstDistribution: swapArgs.dstDistribution,
        bridgeDstAmount: swapArgs.bridgeDstAmount,
        dstPreSwapData: swapArgs.dstPreSwapData
      })
    );

    if (swapArgs.useNativeGas) {
      gasReceiver.payNativeGasForContractCallWithToken{
        value: swapArgs.gasAmount
      }(
        address(this),
        swapArgs.dstChain,
        swapArgs.callTo,
        payload,
        swapArgs.bridgeTokenSymbol,
        amountAfterFee,
        msg.sender
      );
    } else {
      gasReceiver.payGasForExpressCallWithToken(
        address(this),
        swapArgs.dstChain,
        swapArgs.callTo,
        payload,
        swapArgs.bridgeTokenSymbol,
        returnAmount,
        swapArgs.srcSwap.dstToken,
        swapArgs.gasAmount,
        msg.sender
      );
    }

    IERC20(swapArgs.srcSwap.dstToken).approve(address(gateway), amountAfterFee);

    gateway.callContractWithToken(
      swapArgs.dstChain,
      swapArgs.callTo,
      payload,
      swapArgs.bridgeTokenSymbol,
      returnAmount
    );

    _emitCrossChainSwapRequest(
      swapArgs,
      transferId,
      returnAmount,
      msg.sender,
      DataTypes.SwapStatus.Succeeded
    );
  }

  function _emitCrossChainSwapRequest(
    SwapArgsAxelar memory swapArgs,
    bytes32 transferId,
    uint256 returnAmount,
    address sender,
    DataTypes.SwapStatus status
  ) internal {
    // switchEvent.emitCrosschainSwapRequest(
    //   swapArgs.id,
    //   transferId,
    //   swapArgs.bridge,
    //   sender,
    //   swapArgs.srcSwap.srcToken,
    //   swapArgs.srcSwap.dstToken,
    //   swapArgs.dstSwap.dstToken,
    //   swapArgs.amount,
    //   returnAmount,
    //   swapArgs.estimatedDstTokenAmount,
    //   status
    // );
  }

  function _emitCrossChainTransferRequest(
    TransferArgsAxelar calldata transferArgs,
    bytes32 transferId,
    uint256 returnAmount,
    address sender,
    DataTypes.SwapStatus status
  ) internal {
    // switchEvent.emitCrosschainSwapRequest(
    //   transferArgs.id,
    //   transferId,
    //   transferArgs.bridge,
    //   sender,
    //   transferArgs.srcToken,
    //   transferArgs.destToken,
    //   transferArgs.destToken,
    //   transferArgs.amount,
    //   returnAmount,
    //   transferArgs.bridgeDstAmount,
    //   status
    // );
  }

  function _emitCrosschainSwapDone(
    AxelarSwapRequest memory swapRequest,
    address bridgeToken,
    uint256 srcAmount,
    uint256 dstAmount,
    DataTypes.SwapStatus status
  ) internal {
    // switchEvent.emitCrosschainSwapDone(
    //   swapRequest.id,
    //   swapRequest.bridge,
    //   swapRequest.recipient,
    //   bridgeToken,
    //   swapRequest.dstToken,
    //   srcAmount,
    //   dstAmount,
    //   status
    // );
  }

  function _executeWithToken(
    string calldata,
    string calldata,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  ) internal override {
    address bridgeToken = gateway.tokenAddresses(tokenSymbol);
    AxelarSwapRequest memory swapRequest = abi.decode(
      payload,
      (AxelarSwapRequest)
    );

    if (bridgeToken == address(0)) bridgeToken = swapRequest.bridgeToken;

    bool useParaswap = swapRequest.paraswapUsageStatus ==
      DataTypes.ParaswapUsageStatus.Both ||
      swapRequest.paraswapUsageStatus ==
      DataTypes.ParaswapUsageStatus.OnDestChain;

    uint256 tokenBal = IERC20(bridgeToken).balanceOf(address(this));

    uint256 returnAmount;

    DataTypes.SwapStatus status;

    if (bridgeToken == swapRequest.dstToken) {
      returnAmount = amount;
    } else {
      if (useParaswap && amount >= swapRequest.bridgeDstAmount) {
        returnAmount = _swapInternalWithParaSwap(
          IERC20(bridgeToken),
          IERC20(swapRequest.dstToken),
          amount,
          swapRequest.dstParaswapData
        );

        uint256 remainBal = IERC20(bridgeToken).balanceOf(address(this));
        if (remainBal > tokenBal - amount) {
          // Transfer rest bridge token to user
          IERC20(bridgeToken).universalTransfer(
            swapRequest.recipient,
            remainBal + amount - tokenBal
          );
        }
      } else {
        (address midToken, uint256 _amount) = _preSwap(
          bridgeToken,
          amount,
          swapRequest.dstPreSwapData
        );

        if (midToken != swapRequest.dstToken) {
          address dstToken = IERC20(swapRequest.dstToken).isETH()
            ? address(weth)
            : swapRequest.dstToken;

          (returnAmount, ) = _swapForSingleSwap(
            midToken,
            dstToken,
            _amount,
            swapRequest.dstDistribution
          );
          if (IERC20(swapRequest.dstToken).isETH() && returnAmount != 0) {
            weth.deposit{ value: returnAmount }();
          }
        } else {
          returnAmount = _amount;
        }
      }
    }

    if (returnAmount != 0) {
      IERC20(swapRequest.dstToken).universalTransfer(
        swapRequest.recipient,
        returnAmount
      );
    }

    _emitCrosschainSwapDone(
      swapRequest,
      bridgeToken,
      amount,
      returnAmount,
      status
    );
  }

  function _swapInternal(
    address srcToken,
    address destToken,
    uint256 amount,
    bool useParaswap,
    bytes memory paraswapData,
    uint256[] memory distribution
  ) internal returns (uint256 returnAmount) {
    if (srcToken == destToken) {
      returnAmount = amount;
    } else {
      if (useParaswap) {
        returnAmount = _swapInternalWithParaSwap(
          IERC20(srcToken),
          IERC20(destToken),
          amount,
          paraswapData
        );
      } else {
        (returnAmount, ) = _swapForSingleSwap(
          srcToken,
          destToken,
          amount,
          distribution
        );
      }
    }
  }

  function _preSwap(
    address srcToken,
    uint256 amount,
    bytes memory
  ) internal virtual returns (address token, uint256 returnAmount) {
    token = srcToken;
    returnAmount = amount;
  }

  function _swapForSingleSwap(
    address srcToken,
    address destToken,
    uint256 amount,
    uint256[] memory distribution
  ) private returns (uint256 returnAmount, uint256 parts) {
    uint256 lastNonZeroIndex = 0;
    uint256 len = distribution.length;
    for (uint256 i; i < len; ) {
      if (distribution[i] > 0) {
        parts += distribution[i];
        lastNonZeroIndex = i;
      }

      unchecked {
        i++;
      }
    }

    require(parts > 0, "invalid distribution param");

    // break function to avoid stack too deep error
    returnAmount = _swapInternalForSingleSwap(
      distribution,
      amount,
      parts,
      lastNonZeroIndex,
      IERC20(srcToken),
      IERC20(destToken)
    );
    require(returnAmount > 0, "Swap failed from dex");

    // switchEvent.emitSwapped(
    //   msg.sender,
    //   address(this),
    //   IERC20(srcToken),
    //   IERC20(destToken),
    //   amount,
    //   returnAmount,
    //   0
    // );
  }
}