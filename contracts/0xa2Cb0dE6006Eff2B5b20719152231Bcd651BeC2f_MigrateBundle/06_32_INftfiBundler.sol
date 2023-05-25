// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INftfiBundler is IERC721 {
    function safeMint(address _to) external returns (uint256);

    function decomposeBundle(uint256 _tokenId, address _receiver) external;
}