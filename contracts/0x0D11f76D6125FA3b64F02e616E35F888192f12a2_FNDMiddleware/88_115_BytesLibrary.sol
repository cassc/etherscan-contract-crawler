// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/BytesLibrary.sol";

contract $BytesLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $replaceAtIf(bytes calldata data,uint256 startLocation,address expectedAddress,address newAddress) external pure {
        return BytesLibrary.replaceAtIf(data,startLocation,expectedAddress,newAddress);
    }

    function $startsWith(bytes calldata callData,bytes4 functionSig) external pure returns (bool) {
        return BytesLibrary.startsWith(callData,functionSig);
    }

    receive() external payable {}
}