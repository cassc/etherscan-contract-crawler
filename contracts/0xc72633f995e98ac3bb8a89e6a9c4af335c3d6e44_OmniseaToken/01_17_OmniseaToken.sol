pragma solidity ^0.8.7;

import "../oft/OFT.sol";

contract OmniseaToken is OFT {
    constructor(address _layerZeroEndpoint) OFT("Omnisea", "OSEA", _layerZeroEndpoint) {}
}