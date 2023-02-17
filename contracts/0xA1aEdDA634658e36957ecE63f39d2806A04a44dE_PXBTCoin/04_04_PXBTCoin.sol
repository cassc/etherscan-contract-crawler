// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract PXBTCoin is ERC20 {
    constructor() ERC20("PXBTCoin", "PXBT") {
        _mint(msg.sender, 1000000000 * 10**decimals());

        // Contributor
        transfer(
            0x65573Fd4f107Db5EC4d95989d8Fd323690586E1e,
            150000000 * 10**decimals()
        );
        // Corporation
        transfer(
            0x48422317a0a7eA51bD1A093b5ae8eFC0f1C9Ee75,
            120000000 * 10**decimals()
        );
        // DAO
        transfer(
            0xe118748e5dd18e3E796E07A5796e9945Cd446497,
            500000000 * 10**decimals()
        );
        // Founder
        transfer(
            0x6F4EfecBA1015EF5F472200575948DD41BE2F0eF,
            80000000 * 10**decimals()
        );
        // NFT Ecosystem
        transfer(
            0x0d842D6834B824AB3281928115E59BBd6DC48b56,
            150000000 * 10**decimals()
        );
    }
}