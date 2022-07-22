// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IDiamondCut } from "./IDiamondCut.sol";

struct DiamondFactoryInit {
    address _wrappedToken;
    IDiamondCut.FacetCut[] facetAddresses;
}

struct DiamondFactoryContract {
    mapping(string => address) tokenAddresses;
    string[] tokenSymbols;
    IDiamondCut.FacetCut[] facetsToAdd;
    mapping(address => bool) allowedReporters;
    address wrappedToken_;
    address diamondInit_;
    bytes calldata_;
}

interface IDiamondFactory {
    function initialize(
        address _wrappedToken,
        address _diamondInit,
        bytes calldata _calldata,
        IDiamondCut.FacetCut[] memory facetAddresses
    ) external;
}