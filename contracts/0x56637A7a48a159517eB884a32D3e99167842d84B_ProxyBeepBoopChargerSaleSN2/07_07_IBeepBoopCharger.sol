// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721A} from "@erc721a/IERC721A.sol";

interface IBeepBoopCharger is IERC721A {
    function adminMint(address recipient, uint256 quantity) external;

    function transferOwnership(address newOwner) external;

    function setMintPrice(uint256 price) external;

    function mintPrice() external returns (uint256);

    function owner() external view returns (address);

    function withdraw() external;
}