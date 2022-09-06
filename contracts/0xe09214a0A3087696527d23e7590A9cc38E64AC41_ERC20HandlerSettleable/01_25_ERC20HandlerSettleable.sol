// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC20Handler.sol";
import "../utils/rollup/Settleable.sol";

contract ERC20HandlerSettleable is ERC20Handler, Settleable {
    constructor(address bridgeAddress)
        ERC20Handler(bridgeAddress)
        Settleable(bridgeAddress)
    {}

    function _settle(KeyValuePair[] memory pairs, bytes32 resourceID)
        internal
        virtual
        override
    {
        address tokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(tokenAddress != address(0), "invalid dest resource ID");

        require(
            _contractWhitelist[tokenAddress],
            "not an allowed token address"
        );

        if (_burnList[tokenAddress]) {
            for (uint256 i = 0; i < pairs.length; i++) {
                address account = abi.decode(pairs[i].key, (address));
                uint256 amount = abi.decode(pairs[i].value, (uint256));
                mintERC20(tokenAddress, account, amount);
            }
        } else {
            for (uint256 i = 0; i < pairs.length; i++) {
                address account = abi.decode(pairs[i].key, (address));
                uint256 amount = abi.decode(pairs[i].value, (uint256));
                releaseERC20(tokenAddress, account, amount);
            }
        }
    }
}