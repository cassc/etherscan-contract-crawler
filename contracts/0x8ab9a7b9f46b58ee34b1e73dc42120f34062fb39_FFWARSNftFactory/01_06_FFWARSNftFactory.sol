// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/lib/IMintableNft.sol";
import "contracts/lib/Ownable.sol";

contract FFWARSNftFactory is Ownable {
    IMintableNft public nft;
    bool public enabled;
    uint256 public constant maxmintCount = 20;

    constructor(address nftAddress) {
        nft = IMintableNft(nftAddress);
    }

    function mint(address to, uint256 count) external payable {
        require(enabled, "mint disabled");
        require(count <= maxmintCount, "max mint limit");
        for (uint256 i = 0; i < count; ++i) nft.mint(to);
    }

    function setEnabled(bool newEnabled) external onlyOwner {
        enabled = newEnabled;
    }
}