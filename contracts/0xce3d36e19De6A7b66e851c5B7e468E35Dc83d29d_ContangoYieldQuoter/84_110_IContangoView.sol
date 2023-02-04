//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/DataTypes.sol";
import "./IFeeModel.sol";

/// @title Interface to state querying
interface IContangoView {
    function position(PositionId positionId) external view returns (Position memory _position);

    function feeModel(Symbol symbol) external view returns (IFeeModel);

    function closingOnly() external view returns (bool);
}