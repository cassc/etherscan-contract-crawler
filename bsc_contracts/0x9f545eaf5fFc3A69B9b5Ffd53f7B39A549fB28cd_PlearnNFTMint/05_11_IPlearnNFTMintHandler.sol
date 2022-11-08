// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../structs/NFTMetadata.sol";

interface IPlearnNFTMintHandler {
    function mint(
        address receiver,
        uint256 roundId,
        uint256[] memory itemIndices
    ) external;

    function getRound(uint256 roundId)
        external
        view
        returns (
            uint8 status,
            NFTMetadata[] memory nfts,
            uint16[][][] memory items,
            uint256 mintPrice,
            uint256 maxMintPerWallet,
            uint256 roundConflict,
            uint256 minTierRequired
        );

    function dealToken() external view returns (IERC20);
}