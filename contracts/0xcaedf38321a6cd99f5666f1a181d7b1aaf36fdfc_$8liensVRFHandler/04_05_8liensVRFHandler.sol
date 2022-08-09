// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFHandler} from "./utils/VRFHandler.sol";

/// @title 8liensVRFHandler
/// @author 8liens (https://twitter.com/8liensNFT)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract $8liensVRFHandler is Ownable, VRFHandler {
    error SeedInRequest();
    error SeedExists();

    string public constant name = "8liens Magic";

    uint256 public seed;

    uint256 public requestId;

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to start the reveal process by getting a seed
    /// @param vrfConfig the config to use with ChainLink
    function startReveal(VRFConfig memory vrfConfig) external onlyOwner {
        if (seed != 0) {
            revert SeedExists();
        }

        if (requestId != 0) {
            revert SeedInRequest();
        }

        requestId = _requestRandomWords(vrfConfig);
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    /// @dev needs to be overrode in the consumer contract
    function _fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory words
    ) internal virtual override {
        seed = words[0];
    }
}