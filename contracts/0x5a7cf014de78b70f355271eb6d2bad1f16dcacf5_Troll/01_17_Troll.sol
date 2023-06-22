// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/nft/BaseNft.sol";

contract Troll is BaseNft {
    constructor(address controller_) BaseNft(controller_, "Troll", "TROLL") {
        _baseUri = "https://uahqq-jaaaa-aaaan-qdzua-cai.raw.icp0.io/troll/";
    }
}