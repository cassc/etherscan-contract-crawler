// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IStargateRouter.sol";
import "./Interchain.sol";

/// @title An interface to RangoStargate.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoStargate {
    enum StargateBridgeType { TRANSFER, TRANSFER_WITH_MESSAGE }

    struct StargateRequest {
        StargateBridgeType _bridgeType;
        uint16 _dstChainId;
        uint256 _srcPoolId;
        uint256 _dstPoolId;
        address payable _refundAddress;
        uint256 _minAmountLD;

        uint256 _dstGasForCall;
        uint256 _dstNativeAmount;
        bytes _dstNativeAddr;

        bytes _to;
        uint _stgFee;
        
        Interchain.RangoInterChainMessage _payload;
    }

    /// @notice Executes a Stargate call
    /// @param _fromToken The address of source token to bridge
    /// @param _inputAmount The amount of input to be bridged
    /// @param _stargateRequest Required bridge params + interchain message that contains all the required info for the RangoStargate.sol on the destination
    function stargateSwap(
        address _fromToken,
        uint _inputAmount,
        StargateRequest memory _stargateRequest
    ) external payable;
}