pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/fee/OFTWithFee.sol";

contract BTCbOFT is OFTWithFee {
    constructor(address _lzEndpoint) OFTWithFee("Bitcoin", "BTC.b", 8, _lzEndpoint){}

    function decimals() public pure override returns (uint8){
        return 8;
    }
}