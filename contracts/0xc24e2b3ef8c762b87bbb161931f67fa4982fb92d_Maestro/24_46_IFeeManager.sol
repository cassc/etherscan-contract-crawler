//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/DataTypes.sol";
import "./IFeeModel.sol";
import "./IReferralManager.sol";

interface IFeeManagerEvents {

    event FeePaid(
        PositionId indexed positionId,
        address indexed trader,
        address indexed referrer,
        uint256 referrerAmount,
        uint256 traderRebate,
        uint256 protocolFee,
        Currency feeCcy
    );

}

interface IFeeManager is IFeeManagerEvents {

    function feeModel() external view returns (IFeeModel);
    function referralManager() external view returns (IReferralManager);

    /// @notice Applies fees for a given trade. Assumes necessary funds are approved by msg.sender
    /// @param trader The trade trader
    /// @param positionId The trade position id
    /// @param quantity The trade quantity
    /// @return fee Amount of fees paid
    /// @return feeCcy Currency of fee paid
    function applyFee(address trader, PositionId positionId, uint256 quantity) external returns (uint256 fee, Currency feeCcy);

}