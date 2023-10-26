/**
 *Submitted for verification at Etherscan.io on 2023-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface NounsTokenLike {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function seeds(uint256 nounId) external view returns (Seed calldata);
}

interface DescriptorLike {
    function tokenURI(uint256 tokenId, NounsTokenLike.Seed memory seed) external view returns (string memory);
}

contract DescriptorV2ExistingArtTester {
    NounsTokenLike private constant nouns = NounsTokenLike(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03);
    DescriptorLike private constant descriptorV2 = DescriptorLike(0x25fF2FdE7df1A433E09749C952f7e09aD3C27951);

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return descriptorV2.tokenURI(tokenId, nouns.seeds(tokenId));
    }
}