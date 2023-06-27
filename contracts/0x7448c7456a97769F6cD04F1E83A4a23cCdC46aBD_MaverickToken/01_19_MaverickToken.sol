// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OFT} from "@layerzerolabs/solidity-examples/contracts/token/oft/OFT.sol";

contract MaverickToken is OFT {
    constructor(address _layerZeroEndpoint, address mintToAddress) OFT("Maverick Token", "MAV", _layerZeroEndpoint) {
        if (mintToAddress != address(0)) _mint(mintToAddress, 2_000_000_000 * 1e18);
    }
}