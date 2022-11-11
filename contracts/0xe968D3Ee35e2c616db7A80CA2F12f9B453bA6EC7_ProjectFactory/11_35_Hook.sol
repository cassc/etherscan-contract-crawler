// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IRegistry.sol";

interface hookey {

    function Process(bytes memory data) external;
}


contract hook {

    IRegistry reg = IRegistry(0x1e8150050A7a4715aad42b905C08df76883f396F);
 
    function TJHooker(string memory key, bytes calldata data) external {
        hookey hookAddress = hookey(reg.getRegistryAddress(key));
        if (address(hookAddress) == address(0)) return;
        hookAddress.Process(data);
    }

}