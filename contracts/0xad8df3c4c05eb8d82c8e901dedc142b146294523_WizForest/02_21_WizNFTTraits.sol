// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract WizNFTTraits is Ownable {
    function isEvil(uint256 tokenId) public view returns (bool) {
        return tokenId >= 10000;
    }
}