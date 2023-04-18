// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/nft/BaseNft.sol";

contract Mage is BaseNft {
    constructor(address controller_) BaseNft(controller_, "Mage", "MAGE") {
        _baseUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/mage/";
        _burnedUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/mage/burned.json";
        _winUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/mage/winner.json";
    }
}