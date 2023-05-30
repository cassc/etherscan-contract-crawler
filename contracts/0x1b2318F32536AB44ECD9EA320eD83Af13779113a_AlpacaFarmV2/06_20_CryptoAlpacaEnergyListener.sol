// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/introspection/ERC165.sol";
import "./ICryptoAlpacaEnergyListener.sol";

abstract contract CryptoAlpacaEnergyListener is
    ERC165,
    ICryptoAlpacaEnergyListener
{
    constructor() public {
        _registerInterface(
            CryptoAlpacaEnergyListener(0).onCryptoAlpacaEnergyChanged.selector
        );
    }
}