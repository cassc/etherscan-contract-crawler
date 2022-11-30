//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/DataTypes.sol";
import "./IFeeModel.sol";

/// @title Interface to allow for position querying
/// @dev This is meant to be implemented by the Contango contract
interface IContangoView {
    function position(PositionId positionId) external view returns (Position memory _position);

    function feeModel(Symbol symbol) external view returns (IFeeModel);
}