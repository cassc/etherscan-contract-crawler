// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/ArrayLibrary.sol";

contract $ArrayLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $capLength(address payable[] calldata data,uint256 maxLength) external pure {
        return ArrayLibrary.capLength(data,maxLength);
    }

    function $capLength(uint256[] calldata data,uint256 maxLength) external pure {
        return ArrayLibrary.capLength(data,maxLength);
    }

    receive() external payable {}
}