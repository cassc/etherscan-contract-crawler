// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct CreateParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    bool isZeroIndexed;
    uint24 royaltyAmount;
    uint256 endTime;
}

struct MintParams {
    address collection;
    uint24 quantity;
    bytes32[] merkleProof;
    uint8 phaseId;
}

struct OmnichainMintParams {
    address collection;
    uint24 quantity;
    uint256 paid;
    uint8 phaseId;
    address minter;
}

struct Phase {
    uint256 from;
    uint256 to;
    uint24 maxPerAddress;
    uint256 price;
    bytes32 merkleRoot;
}