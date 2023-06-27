// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGuild is IERC721 {
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function mint(address to) external;

    function totalSupply() external view returns (uint256);

    function getHandler() external view returns (address);
}