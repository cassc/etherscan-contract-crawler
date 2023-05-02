// SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

import "layerzerolabs/contracts/token/oft/OFT.sol";

contract USHOFT is OFT {
    constructor(
        address _lzEndpoint //0x3c2269811836af69497E5F486A85D7316753cf62 as per https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    ) OFT("unshETHing_Token", "USH", _lzEndpoint){}
}