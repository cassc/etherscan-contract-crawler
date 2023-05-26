// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/nft/BaseNft.sol";

contract Water is BaseNft {
    constructor(address controller_) BaseNft(controller_, "Water", "WATER") {
        _baseUri = "https://35u76-4yaaa-aaaan-qdhva-cai.raw.ic0.app/nft/meta/water/";
        _burnedUri = "https://wtohs-hyaaa-aaaan-qdg7a-cai.raw.ic0.app/burned/water.json";
        _winUri = "https://wtohs-hyaaa-aaaan-qdg7a-cai.raw.ic0.app/winner/water.json";
    }
}