//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IEvilCoin is IERC721Enumerable {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
}