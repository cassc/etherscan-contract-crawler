// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Renderer {
    function render(
        uint256 tokenId,
        address owner,
        uint256 timestamp
    ) public view virtual returns (string memory tokenURI) {
        string memory name = Strings.toString(uint256(uint160(owner)));
        tokenURI = string(abi.encodePacked(Strings.toString(tokenId),'-',name,'-',Strings.toString(timestamp)));
    }
}