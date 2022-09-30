// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDomani} from "../../interfaces/IDomani.sol";
import {IController} from "../../interfaces/IController.sol";
import {IBasicIssuanceModule} from "../../interfaces/IBasicIssuanceModule.sol";
import {IWNative} from "../interfaces/IWNative.sol";
import {IDomaniDexGeneral} from "./IDomaniDexGeneral.sol";

interface IDomaniDex is IDomaniDexGeneral {
  struct Swap {
    // Identifier of the dex to be used
    string identifier;
    // Info (like routes) to be used in a dex for the swap execution
    bytes swapData;
  }

  struct InputDexParams {
    // Address of the fund
    IDomani fund;
    // Quantity of the fund to buy/sell
    uint256 fundQuantity;
    // Address of the token to send/receive
    IERC20 swapToken;
    // Max amount to spend in a buying or min amount to receive in a selling (anti-slippage)
    uint256 maxOrMinSwapTokenAmount;
    // Info contained the choice of dex to use for single component swap
    Swap[] swaps;
    // Expiration time (in seconds)
    uint256 expiration;
    // Address receiving fund in a buying and the ERC20 in a selling
    address recipient;
  }

  event DomaniSwap(
    address indexed sender,
    address inputToken,
    uint256 inputAmount,
    address indexed recipient,
    address outputToken,
    uint256 outputAmount
  );

  function buyDomaniFund(InputDexParams calldata _inputDexParams)
    external
    payable
    returns (uint256 inputAmountUsed);

  function sellDomaniFund(InputDexParams calldata _inputDexParams)
    external
    returns (uint256 outputAmountReceived);

  function sweepToken(IERC20 token, address payable recipient) external returns (uint256);

  function controller() external view returns (IController);

  function wNative() external view returns (IWNative);

  function basicIssuanceModule() external view returns (IBasicIssuanceModule);

  function getRequiredComponents(
    IDomani _fund,
    uint256 _quantity,
    bool _isIssue
  ) external view returns (address[] memory, uint256[] memory);

  function nativeTokenAddress() external pure returns (address);
}