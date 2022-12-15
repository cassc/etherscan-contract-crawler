// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { PositionCreatedData } from "../../core/types/Common.sol";
import { POSITION_CREATED_ACTION } from "../../core/constants/Common.sol";
import "../../core/types/Common.sol";

/**
 * @title PositionCreated Action contract
 * @notice Emits PositionCreated event
 */
contract PositionCreated is Executable {
  /**
   * @dev Emitted once a position is created
   * @param proxyAddress The address of the proxy where that's a DSProxy or DeFi Positions manager proxy
   * @param protocol The name of the protocol the position is being created on
   * @param positionType The nature of the position EG Earn / Multiply.. etc.this
   * @param collateralToken The address of the collateral used in the position. ETH positions will use WETH by default.
   * @param debtToken The address of the debt used in the position.
   **/
  event CreatePosition(
    address indexed proxyAddress,
    string protocol,
    string positionType,
    address collateralToken,
    address debtToken
  );

  /**
   * @dev Is intended to pull tokens in to a user's proxy (the calling context)
   * @param data Encoded calldata that conforms to the PositionCreatedData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    PositionCreatedData memory positionCreated = parseInputs(data);

    emit CreatePosition(
      address(this),
      positionCreated.protocol,
      positionCreated.positionType,
      positionCreated.collateralToken,
      positionCreated.debtToken
    );
  }

  function parseInputs(bytes memory _callData)
    public
    pure
    returns (PositionCreatedData memory params)
  {
    return abi.decode(_callData, (PositionCreatedData));
  }
}