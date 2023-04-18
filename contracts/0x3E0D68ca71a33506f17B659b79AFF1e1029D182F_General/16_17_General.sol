// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/nft/BaseNft.sol";

contract General is BaseNft {
    constructor(address controller_) BaseNft(controller_, "General", "GENERAL") {
        _baseUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/general/";
        _burnedUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/general/burned.json";
        _winUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/general/winner.json";
    }
}