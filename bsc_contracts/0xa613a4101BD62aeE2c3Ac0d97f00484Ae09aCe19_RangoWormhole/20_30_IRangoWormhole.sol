// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IWormholeRouter.sol";
import "./Interchain.sol";

/// @title An interface to RangoWormhole.sol contract to improve type hinting
/// @author Marlon
interface IRangoWormhole {
    enum WormholeBridgeType { TRANSFER, TRANSFER_WITH_MESSAGE }

    struct WormholeRequest {
        WormholeBridgeType _bridgeType;
        address _fromAddress;
        uint16 _recipientChain;
        bytes32 _targetAddress;
        uint256 _fee;
        uint32 _nonce;
 
        Interchain.RangoInterChainMessage _payload;
    }

    /// @notice Executes a Wormhole call
    /// @param _fromToken The address of source token to bridge
    /// @param _inputAmount The amount of input to be bridged
    /// @param _wormholeRequest Required bridge params + interchain message that contains all the required info for the RangoWormhole.sol on the destination
    function wormholeSwap(
        address _fromToken,
        uint _inputAmount,
        WormholeRequest memory _wormholeRequest
    ) external payable;
}