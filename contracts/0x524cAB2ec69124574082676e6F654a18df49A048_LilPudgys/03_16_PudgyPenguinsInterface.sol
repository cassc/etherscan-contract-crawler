// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface PudgyPenguinsInterface is IERC721{
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}