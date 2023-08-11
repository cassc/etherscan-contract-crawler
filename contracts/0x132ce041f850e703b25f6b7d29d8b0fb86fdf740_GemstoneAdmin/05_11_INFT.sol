// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface INFT {
    enum GemstoneTypes {
        None,
        AurumGemstoneOfTruth,
        DiamondMindGemstone,
        RubyHeartGemstone
    }

    struct WalletTier {
        address wallet;
        GemstoneTypes tier;
    }

    function addEligibleWallets(WalletTier[] memory eligibleWallets) external;

    function claim() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tierByToken(uint256 key) external view returns (GemstoneTypes);
}