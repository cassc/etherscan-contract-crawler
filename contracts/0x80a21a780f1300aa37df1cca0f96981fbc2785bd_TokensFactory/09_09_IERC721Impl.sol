// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721Impl is IERC721Upgradeable{
    function __ERC721Impl_init(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address owner
    ) external;
}