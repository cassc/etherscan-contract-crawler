// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/nft/BaseNft.sol";

contract Ice is BaseNft {
    constructor(address controller_) BaseNft(controller_, "Ice", "ICE") {
        _baseUri = "https://26ywy-iaaaa-aaaan-qdhtq-cai.raw.ic0.app/nft/meta/ice/";
        _burnedUri = "https://wtohs-hyaaa-aaaan-qdg7a-cai.raw.ic0.app/burned/ice.json";
        _winUri = "https://wtohs-hyaaa-aaaan-qdg7a-cai.raw.ic0.app/winner/ice.json";
    }
}