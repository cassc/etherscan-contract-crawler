// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";
import {ReentrancyGuard} from "@timeswap-labs/v2-pool/contracts/libraries/ReentrancyGuard.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2Token} from "./interfaces/ITimeswapV2Token.sol";

import {ITimeswapV2TokenMintCallback} from "./interfaces/callbacks/ITimeswapV2TokenMintCallback.sol";
import {ITimeswapV2TokenBurnCallback} from "./interfaces/callbacks/ITimeswapV2TokenBurnCallback.sol";

import {ERC1155Enumerable} from "./base/ERC1155Enumerable.sol";

import {TimeswapV2TokenPosition, PositionLibrary} from "./structs/Position.sol";
import {TimeswapV2TokenMintParam, TimeswapV2TokenBurnParam, ParamLibrary} from "./structs/Param.sol";
import {TimeswapV2TokenMintCallbackParam, TimeswapV2TokenBurnCallbackParam} from "./structs/CallbackParam.sol";
import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @title
/// @author Timeswap Labs
/// @notice TimeswapV2Token tokenizes the TimeswapV2 native option positions (long0, long1, short)
contract TimeswapV2Token is ITimeswapV2Token, ERC1155Enumerable {
  using ReentrancyGuard for uint96;

  using PositionLibrary for TimeswapV2TokenPosition;

  address public immutable optionFactory;

  mapping(bytes32 => uint96) private reentrancyGuards;

  mapping(uint256 => TimeswapV2TokenPosition) private _timeswapV2TokenPositions;
  mapping(bytes32 => uint256) private _timeswapV2TokenPositionIds;

  uint256 private counter;

  constructor(address chosenOptionFactory) ERC1155("Timeswap V2 address") {
    optionFactory = chosenOptionFactory;
  }

  /// @dev internal function to change interaction level if any
  function changeInteractedIfNecessary(address token0, address token1, uint256 strike, uint256 maturity) private {
    bytes32 key = keccak256(abi.encode(token0, token1, strike, maturity));

    if (reentrancyGuards[key] == ReentrancyGuard.NOT_INTERACTED) reentrancyGuards[key] = ReentrancyGuard.NOT_ENTERED;
  }

  /// @dev internal function to start the reentrancy guard
  function raiseGuard(address token0, address token1, uint256 strike, uint256 maturity) private {
    bytes32 key = keccak256(abi.encode(token0, token1, strike, maturity));

    reentrancyGuards[key].check();
    reentrancyGuards[key] = ReentrancyGuard.ENTERED;
  }

  /// @dev internal function to end the reentrancy guard
  function lowerGuard(address token0, address token1, uint256 strike, uint256 maturity) private {
    bytes32 key = keccak256(abi.encode(token0, token1, strike, maturity));
    reentrancyGuards[key] = ReentrancyGuard.NOT_ENTERED;
  }

  /// @inheritdoc ITimeswapV2Token
  function positionOf(
    address owner,
    TimeswapV2TokenPosition calldata timeswapV2TokenPosition
  ) public view returns (uint256 amount) {
    amount = ERC1155.balanceOf(owner, _timeswapV2TokenPositionIds[timeswapV2TokenPosition.toKey()]);
  }

  /// @inheritdoc ITimeswapV2Token
  function transferTokenPositionFrom(
    address from,
    address to,
    TimeswapV2TokenPosition calldata timeswapV2TokenPosition,
    uint256 amount
  ) external override {
    safeTransferFrom(from, to, _timeswapV2TokenPositionIds[timeswapV2TokenPosition.toKey()], (amount), bytes(""));
  }

  /// @inheritdoc ITimeswapV2Token
  function mint(TimeswapV2TokenMintParam calldata param) external override returns (bytes memory data) {
    ParamLibrary.check(param);
    changeInteractedIfNecessary(param.token0, param.token1, param.strike, param.maturity);
    raiseGuard(param.token0, param.token1, param.strike, param.maturity);

    address optionPair = OptionFactoryLibrary.getWithCheck(optionFactory, param.token0, param.token1);

    uint256 long0BalanceTarget;
    // mints TimeswapV2Token in case of the long0 position
    if (param.long0Amount != 0) {
      // get the initial balance of the long0 position and add the long0 amount to mint
      long0BalanceTarget =
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long0
        ) +
        param.long0Amount;

      TimeswapV2TokenPosition memory timeswapV2TokenPosition = TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: TimeswapV2OptionPosition.Long0
      });

      bytes32 key = timeswapV2TokenPosition.toKey();
      // get the unique id of the TimeswapV2Token position
      uint256 id = _timeswapV2TokenPositionIds[key];

      // if the id is 0, it means that the position has not been minted yet
      if (id == 0) {
        id = (++counter);
        _timeswapV2TokenPositions[id] = timeswapV2TokenPosition;
        _timeswapV2TokenPositionIds[key] = id;
      }

      // mint the TimeswapV2Token long0 position
      _mint(param.long0To, id, (param.long0Amount), bytes(""));
    }

    uint256 long1BalanceTarget;
    // mints TimeswapV2Token in case of the long1 position
    if (param.long1Amount != 0) {
      // get the initial balance of the long1 position and add the long1 amount to mint
      long1BalanceTarget =
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long1
        ) +
        param.long1Amount;

      TimeswapV2TokenPosition memory timeswapV2TokenPosition = TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: TimeswapV2OptionPosition.Long1
      });

      bytes32 key = timeswapV2TokenPosition.toKey();
      // get the unique id of the TimeswapV2Token position
      uint256 id = _timeswapV2TokenPositionIds[key];

      // if the id is 0, it means that the position has not been minted yet
      if (id == 0) {
        id = (++counter);
        _timeswapV2TokenPositions[id] = timeswapV2TokenPosition;
        _timeswapV2TokenPositionIds[key] = id;
      }

      // mint the TimeswapV2Token long1 position
      _mint(param.long1To, id, (param.long1Amount), bytes(""));
    }

    uint256 shortBalanceTarget;
    // mints TimeswapV2Token in case of the short position
    if (param.shortAmount != 0) {
      // get the initial balance of the short position and add the short amount to mint
      shortBalanceTarget =
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Short
        ) +
        param.shortAmount;

      TimeswapV2TokenPosition memory timeswapV2TokenPosition = TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: TimeswapV2OptionPosition.Short
      });

      bytes32 key = timeswapV2TokenPosition.toKey();
      // get the unique id of the TimeswapV2Token position
      uint256 id = _timeswapV2TokenPositionIds[key];

      // if the id is 0, it means that the position has not been minted yet
      if (id == 0) {
        id = (++counter);
        _timeswapV2TokenPositions[id] = timeswapV2TokenPosition;
        _timeswapV2TokenPositionIds[key] = id;
      }

      // mint the TimeswapV2Token short position
      _mint(param.shortTo, id, (param.shortAmount), bytes(""));
    }

    // ask the msg.sender to transfer the long0/long1/short amount to the this contract
    data = ITimeswapV2TokenMintCallback(msg.sender).timeswapV2TokenMintCallback(
      TimeswapV2TokenMintCallbackParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        long0Amount: param.long0Amount,
        long1Amount: param.long1Amount,
        shortAmount: param.shortAmount,
        data: param.data
      })
    );

    // check if the long0 position token balance target is achieved. If not, revert the transaction
    if (param.long0Amount != 0)
      Error.checkEnough(
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long0
        ),
        long0BalanceTarget
      );

    // check if the long1 position token balance target is achieved. If not, revert the transaction
    if (param.long1Amount != 0)
      Error.checkEnough(
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long1
        ),
        long1BalanceTarget
      );

    // check if the short position token balance target is achieved. If not, revert the transaction
    if (param.shortAmount != 0)
      Error.checkEnough(
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Short
        ),
        shortBalanceTarget
      );

    lowerGuard(param.token0, param.token1, param.strike, param.maturity);
  }

  /// @inheritdoc ITimeswapV2Token
  function burn(TimeswapV2TokenBurnParam calldata param) external override returns (bytes memory data) {
    ParamLibrary.check(param);
    raiseGuard(param.token0, param.token1, param.strike, param.maturity);

    address optionPair = OptionFactoryLibrary.getWithCheck(optionFactory, param.token0, param.token1);

    // case when the long0 position is to be burned
    if (param.long0Amount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.long0To,
        TimeswapV2OptionPosition.Long0,
        param.long0Amount
      );

    // case when the long1 position is to be burned
    if (param.long1Amount != 0)
      // transfer the underlying equivalent long1 position amount to address of the recipient of long1 position.
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.long1To,
        TimeswapV2OptionPosition.Long1,
        param.long1Amount
      );

    // case when the short position is to be burned
    if (param.shortAmount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.shortTo,
        TimeswapV2OptionPosition.Short,
        param.shortAmount
      );

    if (param.data.length != 0)
      data = ITimeswapV2TokenBurnCallback(msg.sender).timeswapV2TokenBurnCallback(
        TimeswapV2TokenBurnCallbackParam({
          token0: param.token0,
          token1: param.token1,
          strike: param.strike,
          maturity: param.maturity,
          long0Amount: param.long0Amount,
          long1Amount: param.long1Amount,
          shortAmount: param.shortAmount,
          data: param.data
        })
      );

    // case when the long0 position is to be burned
    if (param.long0Amount != 0) {
      TimeswapV2TokenPosition memory timeswapV2TokenPosition = TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: TimeswapV2OptionPosition.Long0
      });

      // burn the TimeswapV2Token representing long0 position
      _burn(msg.sender, _timeswapV2TokenPositionIds[timeswapV2TokenPosition.toKey()], param.long0Amount);
    }

    // case when the long1 position is to be burned
    if (param.long1Amount != 0) {
      TimeswapV2TokenPosition memory timeswapV2TokenPosition = TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: TimeswapV2OptionPosition.Long1
      });

      // burn the TimeswapV2Token representing long1 position
      _burn(msg.sender, _timeswapV2TokenPositionIds[timeswapV2TokenPosition.toKey()], param.long1Amount);
    }

    // case when the short position is to be burned
    if (param.shortAmount != 0) {
      TimeswapV2TokenPosition memory timeswapV2TokenPosition = TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: TimeswapV2OptionPosition.Short
      });

      // burn the TimeswapV2Token representing short position
      _burn(msg.sender, _timeswapV2TokenPositionIds[timeswapV2TokenPosition.toKey()], param.shortAmount);
    }

    // stop the guard of reentrancy
    lowerGuard(param.token0, param.token1, param.strike, param.maturity);
  }
}