// SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

import "layerzerolabs/contracts/token/oft/OFT.sol";

contract unshETHOFT is OFT {
    constructor(address _lzEndpoint) OFT("unshETH Ether", "unshETH", _lzEndpoint) {}
}