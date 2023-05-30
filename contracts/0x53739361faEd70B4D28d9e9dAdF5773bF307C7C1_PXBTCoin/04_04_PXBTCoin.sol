// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract PXBTCoin is ERC20 {
    constructor() ERC20("PAXB Token", "PXBT") {
        _mint(msg.sender, 1000000000 * 10**decimals());

        // Contributor
        transfer(
            0x0633b1Ebe9f373170dea136C4EeD507ad2665185,
            150000000 * 10**decimals()
        );
        // Corporation
        transfer(
            0x2A6c031A5E2dDda878F034D243F6735fC11B8484,
            120000000 * 10**decimals()
        );
        // DAO
        transfer(
            0x2943071d357ACC4Fe1Eb96e8ffE1D17C65417cde,
            500000000 * 10**decimals()
        );
        // Founder
        transfer(
            0x1E92F1E53f37CC32e47ccAc82A5B011464175A1e,
            80000000 * 10**decimals()
        );
        // NFT Ecosystem
        transfer(
            0x299d920926f65144C282282586f3E045cD80E234,
            150000000 * 10**decimals()
        );
    }
}