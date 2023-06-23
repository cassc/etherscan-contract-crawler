pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/OFTV2.sol";

contract CantoOFTV2 is OFTV2 {
    constructor(address _lzEndpoint) OFTV2("Canto", "CANTO", 6, _lzEndpoint) {}
}