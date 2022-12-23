//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./VixenParts.sol";

contract Vixen {
    function viewVixen() public pure returns (string memory) {
        return string(abi.encodePacked(Vixen_1.getVixen(), Vixen_2.getVixen()));
    }
}