// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OFT} from "layer0/token/oft/OFT.sol";

import {LostToken} from "../LostToken.sol";

/**
 * @author @theo6890
 * @notice Layer ZEro bridged SFUND
 */
contract SFUND_OFTv1 is OFT, LostToken {
    constructor(
        string memory _name,
        string memory _symbol,
        address _layerZero
    ) OFT(_name, _symbol, _layerZero) {}
}