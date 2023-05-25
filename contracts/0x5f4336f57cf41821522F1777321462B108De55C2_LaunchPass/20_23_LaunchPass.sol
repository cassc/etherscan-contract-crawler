// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {NFTPass} from '../NFTPass/NFTPass.sol';

contract LaunchPass is NFTPass {
    constructor(address tokenRendererAddress, address whitelistSigningKey, string memory contractUriJSON)
    public NFTPass(tokenRendererAddress, whitelistSigningKey, contractUriJSON, "Launch Pass", "LAUNCH") {}
}