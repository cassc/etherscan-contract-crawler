// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVaultKey is IERC721 {
    function mintKey(address to) external;

    function lastMintedKeyId(address to) external view returns (uint256);
}