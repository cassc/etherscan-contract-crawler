// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

/**
 * @notice Bundle of PROOF ecosystem token addresses.
 */
struct PROOFTokens {
    IERC721 proof;
    IERC721 moonbirds;
    IERC721 oddities;
}