// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

struct Config {
    bool Initialised;
    bool NumericOnly;
    bool CanOverwriteSubdomains;
    string[] DomainArray;
}