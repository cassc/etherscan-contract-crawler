// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../interfaces/ITradingCore.sol";
import "../interfaces/ISwapRouter.sol";
import "../interfaces/AbstractOracleAggregator.sol";
import "../libs/math/FixedPoint.sol";
import "../libs/ERC20Fixed.sol";
import "../libs/Errors.sol";
import "../libs/TradingCoreLib.sol";
import "../utils/Allowlistable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract TradingCoreWithRouter is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  Allowlistable
{
  using FixedPoint for uint256;
  using SafeCast for uint256;
  using ERC20Fixed for ERC20;

  ITradingCore tradingCore;
  address baseToken;
  AbstractOracleAggregator oracleAggregator;
  IRegistryCore registry;

  ISwapRouter public swapRouter; //settable

  mapping(address => bool) public approvedToken;

  event SetSwapRouterEvent(ISwapRouter swapRouter);
  event SetApprovedTokenEvent(address token, bool approved);

  function initialize(
    address _owner,
    ITradingCore _tradingCore,
    IRegistryCore _registryCore,
    ISwapRouter _swapRouter
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    __Allowlistable_init();
    _transferOwnership(_owner);
    tradingCore = _tradingCore;
    baseToken = address(tradingCore.baseToken());
    oracleAggregator = tradingCore.oracleAggregator();
    registry = _registryCore;
    swapRouter = _swapRouter;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // governance functions

  function onAllowlist() external onlyOwner {
    _onAllowlist();
  }

  function offAllowlist() external onlyOwner {
    _offAllowlist();
  }

  function addAllowlist(address[] memory _allowed) external onlyOwner {
    _addAllowlist(_allowed);
  }

  function removeAllowlist(address[] memory _removed) external onlyOwner {
    _removeAllowlist(_removed);
  }

  function approveToken(address token, bool approved) external onlyOwner {
    approvedToken[token] = approved;
    emit SetApprovedTokenEvent(token, approved);
  }

  function setSwapRouter(ISwapRouter _swapRouter) external onlyOwner {
    swapRouter = _swapRouter;
    emit SetSwapRouterEvent(swapRouter);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  // external functions

  function canOpenMarketOrder(
    IBook.OpenTradeInput calldata openData,
    ISwapRouter.SwapGivenOutInput memory input,
    uint128 openPrice
  ) external view returns (IRegistry.Trade memory trade, IFee.Fee memory _fee) {
    _require(input.tokenOut == baseToken, Errors.TOKEN_MISMATCH);
    _require(approvedToken[input.tokenIn], Errors.APPROVED_TOKEN_ONLY);
    input.amountOut = openData.margin;
    uint256 amountIn = swapRouter.getAmountGivenOut(input);
    _require(
      ERC20(input.tokenIn).balanceOfFixed(msg.sender) >= amountIn,
      Errors.INVALID_MARGIN
    );

    (trade, _fee) = TradingCoreLib.canOpenMarketOrder(
      tradingCore,
      registry,
      openData,
      openPrice
    );
  }

  function openMarketOrder(
    IBook.OpenTradeInput calldata openData,
    bytes[] calldata priceData,
    ISwapRouter.SwapGivenOutInput memory input
  ) external payable whenNotPaused nonReentrant onlyAllowlisted {
    _require(input.tokenOut == baseToken, Errors.TOKEN_MISMATCH);
    _require(approvedToken[input.tokenIn], Errors.APPROVED_TOKEN_ONLY);
    input.amountOut = openData.margin;

    ERC20(input.tokenIn).transferFromFixed(
      msg.sender,
      address(this),
      input.amountInMaximum
    );
    // audit(B): H02
    uint256 _amountInMaximum = input.amountInMaximum.min(
      ERC20(input.tokenIn).balanceOfFixed(address(this))
    );
    ERC20(input.tokenIn).approveFixed(address(swapRouter), _amountInMaximum);
    uint256 amountIn = swapRouter.swapGivenOut(input);
    if (amountIn < input.amountInMaximum) {
      // audit(B): H02
      uint256 _amountOut = input.amountInMaximum.sub(amountIn).min(
        ERC20(input.tokenIn).balanceOfFixed(address(this))
      );
      ERC20(input.tokenIn).transferFixed(msg.sender, _amountOut);
    }
    ERC20(baseToken).approveFixed(address(tradingCore), openData.margin);

    tradingCore.openMarketOrder{
      value: oracleAggregator.getUpdateFee(priceData.length)
    }(openData, priceData);
  }

  function closeMarketOrder(
    IBook.CloseTradeInput calldata closeData,
    bytes[] calldata priceData,
    ISwapRouter.SwapGivenInInput memory input
  ) external payable whenNotPaused nonReentrant onlyAllowlisted {
    IRegistry.Trade memory t = registry.openTradeByOrderHash(
      closeData.orderHash
    );

    _require(t.user == msg.sender, Errors.USER_SENDER_MISMATCH);
    _require(input.tokenIn == baseToken, Errors.TOKEN_MISMATCH);
    _require(approvedToken[input.tokenOut], Errors.APPROVED_TOKEN_ONLY);

    uint256 settled = tradingCore.closeMarketOrder{
      value: oracleAggregator.getUpdateFee(priceData.length)
    }(closeData, priceData);

    ERC20(baseToken).approveFixed(address(swapRouter), settled);
    input.amountIn = settled;
    ERC20(input.tokenOut).transferFixed(
      msg.sender,
      swapRouter.swapGivenIn(input)
    );
  }

  function addMargin(
    bytes32 orderHash,
    bytes[] memory priceData,
    ISwapRouter.SwapGivenOutInput memory input
  ) external payable whenNotPaused nonReentrant onlyAllowlisted {
    IRegistry.Trade memory t = registry.openTradeByOrderHash(orderHash);
    _require(t.user == msg.sender, Errors.USER_SENDER_MISMATCH);
    _require(input.tokenOut == baseToken, Errors.TOKEN_MISMATCH);
    _require(approvedToken[input.tokenIn], Errors.APPROVED_TOKEN_ONLY);

    ERC20(input.tokenIn).transferFromFixed(
      msg.sender,
      address(this),
      input.amountInMaximum
    );
    // audit(B): H02
    uint256 _amountInMaximum = input.amountInMaximum.min(
      ERC20(input.tokenIn).balanceOfFixed(address(this))
    );
    ERC20(input.tokenIn).approveFixed(address(swapRouter), _amountInMaximum);
    uint256 amountIn = swapRouter.swapGivenOut(input);
    if (amountIn < input.amountInMaximum) {
      // audit(B): H02
      uint256 _amountOut = input.amountInMaximum.sub(amountIn).min(
        ERC20(input.tokenIn).balanceOfFixed(address(this))
      );
      ERC20(input.tokenIn).transferFixed(msg.sender, _amountOut);
    }
    ERC20(baseToken).approveFixed(address(tradingCore), input.amountOut);

    tradingCore.addMargin{
      value: oracleAggregator.getUpdateFee(priceData.length)
    }(orderHash, priceData, input.amountOut.toUint128());
  }

  function removeMargin(
    bytes32 orderHash,
    bytes[] memory priceData,
    ISwapRouter.SwapGivenInInput memory input
  ) external payable whenNotPaused nonReentrant onlyAllowlisted {
    IRegistry.Trade memory t = registry.openTradeByOrderHash(orderHash);
    _require(t.user == msg.sender, Errors.USER_SENDER_MISMATCH);
    _require(input.tokenIn == baseToken, Errors.TOKEN_MISMATCH);
    _require(approvedToken[input.tokenOut], Errors.APPROVED_TOKEN_ONLY);

    tradingCore.removeMargin{
      value: oracleAggregator.getUpdateFee(priceData.length)
    }(orderHash, priceData, input.amountIn.toUint128());

    ERC20(input.tokenIn).approveFixed(address(swapRouter), input.amountIn);
    uint256 amountOut = swapRouter.swapGivenIn(input);
    // audit(B): H02
    uint256 _amountOut = amountOut.min(
      ERC20(input.tokenOut).balanceOfFixed(address(this))
    );
    ERC20(input.tokenOut).transferFixed(msg.sender, _amountOut);
  }
}