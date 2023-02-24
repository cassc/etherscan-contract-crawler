// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IERC20Minimal.sol";

library TokenTransfer {
    
    function transferToken(
        address tokenAddr,
        address toAddr,
        uint256 amount
    ) internal {
        (bool ok, bytes memory retData) =
            tokenAddr.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, toAddr, amount));
        require(ok && (retData.length == 0 || abi.decode(retData, (bool))), 'TNS');
    }
    
}