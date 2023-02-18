// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICOKContracts is IERC721 {
    function walletOfOwner(
        address owner
    ) external view returns (uint256[] memory);

    function totalTokens() external view returns (uint16);
}