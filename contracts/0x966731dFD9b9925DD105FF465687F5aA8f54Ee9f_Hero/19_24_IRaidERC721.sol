// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRaidERC721 is IERC721 {
    function getSeeder() external view returns (address);

    function burn(uint256 tokenId) external;

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}