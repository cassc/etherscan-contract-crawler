// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

interface IERC721Optimized {
    struct MintConfig {
        uint64 maxTotalMintAmount;
        uint64 maxMintAmountPerAddress;
        uint128 pricePerMint;
        uint256 mintStartTimestamp;
        uint256 mintEndTimestamp;
        uint64[] discountPerMintAmountKeys;
        uint128[] discountPerMintAmountValues;
    }

    function publicMintConfig() external view returns (MintConfig memory);

    function totalMinted() external view returns (uint256);

    function publicMint(address to, uint64 amount) external;
}