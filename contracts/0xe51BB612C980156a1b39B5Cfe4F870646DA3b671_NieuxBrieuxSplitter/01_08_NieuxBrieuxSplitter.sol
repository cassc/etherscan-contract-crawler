//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./AirdropNFTSplitter.sol";

contract NieuxBrieuxSplitter is AirdropNFTSplitter {

    address[] private payees;

    mapping(address => bool) private payeesMapping;

    constructor(
        address[] memory payees_,
        uint256[] memory shares
    ) AirdropNFTSplitter(payees_, shares)
    {
    }
}