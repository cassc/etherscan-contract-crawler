// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INiftyKit is IERC721 {
    function transferOwnership(address newOwner) external;
    function batchAirdrop(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external;
    function startSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external;

    function price() external view returns (uint256);
}