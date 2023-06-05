// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/oft/extension/BasedOFT.sol";

contract Kek is BasedOFT {
    constructor(address _layerZeroEndpoint, uint _initialSupply) BasedOFT("KekkCoin", "KEKK", _layerZeroEndpoint) {
        _mint(_msgSender(), _initialSupply);
    }
}