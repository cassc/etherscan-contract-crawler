// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/nft/BaseNft.sol";

contract Troll is BaseNft {
    constructor(address controller_) BaseNft(controller_, "Troll", "TROLL") {
        _baseUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/troll/";
        _burnedUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/troll/burned.json";
        _winUri = "https://3sboo-waaaa-aaaan-qdmfa-cai.raw.ic0.app/troll/winner.json";
    }
}