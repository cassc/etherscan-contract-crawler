// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Proxy.sol";

contract NFTProxy is Proxy {
    address private _implementationAddress;

    constructor(string memory name, string memory symbol) {
        _implementationAddress = 0xe09c64f2f4425e60aAD360F1Ee96F23982b1b564;

        _implementationAddress.delegatecall(
            abi.encodeWithSignature(
                "initialize(string,string,string,string,string,bytes32,address,uint96)",
                name,
                symbol,
                "ipfs://",
                "ipfs://",
                "ipfs://",
                "0xc205d366669a3e0dcde431f70df1d1953497c4c234cb20ef51629fe47083ff1a",
                "0x77Fb82f6CdB8cb3649C550283800F2aFb9dEE6A4",
                1000
            )
        );
    }

    function _implementation() internal view override returns (address) {
        return _implementationAddress;
    }

    function implementation() external view returns (address) {
        return _implementation();
    }

    function proxyType() external pure returns (uint256) {
        return 2;
    }
}