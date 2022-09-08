// SPDX-License-Identifier: Unlicensed
//
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

abstract contract ERC721EnumerableEx is ERC721Enumerable {

    function totalOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokens = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokens);
        for (uint256 i = 0; i < tokens; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }
}