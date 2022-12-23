//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./BlitzenParts.sol";
contract Blitzen {
    function viewBlitzen() public pure returns (string memory) {
        return string(abi.encodePacked(Blitzen_1.getBlitzen(), Blitzen_2.getBlitzen()));
    }
}