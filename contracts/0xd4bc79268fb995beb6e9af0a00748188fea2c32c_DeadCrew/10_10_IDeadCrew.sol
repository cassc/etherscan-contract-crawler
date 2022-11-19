// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721A} from "@erc721a/extensions/ERC721AQueryable.sol";

interface IDeadCrew is IERC721A {
    function mint(address dest, uint256 quantity) external;

    function burn(uint256[] memory tokenIds) external;
}