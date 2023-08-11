// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

import { IWormholeRelayer } from "wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";

/**************************************

    Wormhole sender

 **************************************/

/// @notice Wormhole message sender contract
contract WormholeSender {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    uint256 public GAS_LIMIT = 100_000;

    // -----------------------------------------------------------------------
    //                              State variables
    // -----------------------------------------------------------------------

    IWormholeRelayer public relayer = IWormholeRelayer(0x27428DD2d3DD32A4D7f7C497eAaa23130d894911);

    // -----------------------------------------------------------------------
    //                              Estimate
    // -----------------------------------------------------------------------

    function estimateGas(uint16 _chain) public view returns (uint256 cost_) {
        (cost_,) = relayer.quoteEVMDeliveryPrice(_chain, 0, GAS_LIMIT);
    }

    // -----------------------------------------------------------------------
    //                              Send message
    // -----------------------------------------------------------------------

    function sendMessage(uint16 _chain, address _receiver) public payable {
        uint256 cost_ = estimateGas(_chain);
        require(msg.value == cost_);
        relayer.sendPayloadToEvm{value: cost_}(
            _chain,
            _receiver,
            abi.encode("Test value"), // payload
            0, // msg.value for receiver
            GAS_LIMIT
        );
    }

}