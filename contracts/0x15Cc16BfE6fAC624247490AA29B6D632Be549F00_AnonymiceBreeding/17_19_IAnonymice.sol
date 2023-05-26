// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IAnonymice is IERC721Enumerable {
    function _tokenIdToHash(uint256 _tokenId)
        external
        view
        returns (string memory);

    function hashToSVG(string memory _hash)
        external
        view
        returns (string memory);
}