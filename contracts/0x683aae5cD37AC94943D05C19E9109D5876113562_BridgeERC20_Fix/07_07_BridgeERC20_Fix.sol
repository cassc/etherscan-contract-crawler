// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./BridgeERC20.sol";

contract BridgeERC20_Fix is BridgeERC20 {
    constructor(string memory name_, string memory symbol_, uint8 decimals_, address bridgeAddress_,
        address[] memory oldAddresses, uint[] memory oldBalances
    )
    BridgeERC20(name_, symbol_, decimals_, bridgeAddress_) {
        for (uint i = 0; i < oldAddresses.length; i++)
            _mint(oldAddresses[i], oldBalances[i]);
    }
}