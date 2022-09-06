// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWNative} from "../interfaces/IWNative.sol";
import {IDomaniDexGeneral} from "./IDomaniDexGeneral.sol";

interface IDomaniMultiTokenDex is IDomaniDexGeneral {
  struct Swap {
    // Token used in the swap with the swapToken
    IERC20 token;
    // Exact amount of token to buy/sell
    uint256 amount;
    // Identifier of the dex to be used
    string identifier;
    // Info (like routes) to be used in a dex for the swap execution
    bytes swapData;
  }

  struct InputMultiTokenDexParams {
    // Address of the token to send/receive
    IERC20 swapToken;
    // Max amount to spend in a buying or min amount to receive in a selling (anti-slippage)
    uint256 maxOrMinSwapTokenAmount;
    // Info contained the choice of dex for executing multi-token swap
    Swap[] swaps;
    // Expiration time (in seconds)
    uint256 expiration;
    // Address receiving fund in a buying or selling
    address recipient;
  }

  struct SwapToken {
    address token;
    uint256 amount;
  }

  event FeeSet(uint64 prevFee, uint64 newFee);

  event FeeRecipientSet(address prevRecipient, address newRecipient);

  event MultiTokenBought(
    address indexed sender,
    SwapToken tokenSold,
    address indexed recipient,
    SwapToken[] tokensBought,
    uint256 feePaid
  );

  event MultiTokenSold(
    address indexed sender,
    SwapToken[] tokensSold,
    address indexed recipient,
    SwapToken tokenBought,
    uint256 feePaid
  );

  function buyMultiToken(InputMultiTokenDexParams calldata _inputMultiTokenDexParams)
    external
    payable
    returns (uint256 inputAmountUsed, uint256 feeAmount);

  function sellMultiToken(InputMultiTokenDexParams calldata _inputMultiTokenDexParams)
    external
    payable
    returns (uint256 outputAmountReceived, uint256 feeAmount);

  function sweepToken(IERC20 token, address payable recipient) external returns (uint256);

  function wNative() external view returns (IWNative);

  function nativeTokenAddress() external pure returns (address);

  function getFee() external view returns (uint64);

  function getFeeRecipient() external view returns (address);
}