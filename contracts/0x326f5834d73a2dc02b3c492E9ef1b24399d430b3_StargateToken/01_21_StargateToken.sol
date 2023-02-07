// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/OFTV2.sol";

contract StargateToken is OFTV2 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _sharedDecimals,
        address _lzEndpoint,
        uint256 _initialSupply
    ) OFTV2(_name, _symbol, _sharedDecimals, _lzEndpoint) {
        _mint(msg.sender, _initialSupply);
    }
}