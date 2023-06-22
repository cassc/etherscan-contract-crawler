// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721E/ERC721EP.sol";

contract Osashimi is ERC721EP {
    constructor()
    ERC721EP("Osashimi", "OSSM", address(0x23407D999af3952b102eD2be3Da48320822c2506)) {
        enableAutoFreez();
        setMintFee(0.03 ether);
        
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;
        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }
}