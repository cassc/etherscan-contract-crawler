pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/fee/ProxyOFTWithFee.sol";

contract ProxyPepeToken is ProxyOFTWithFee {
    constructor(address _token, uint8 _sharedDecimals, address _layerZeroEndpoint) ProxyOFTWithFee(_token, _sharedDecimals, _layerZeroEndpoint){}
}