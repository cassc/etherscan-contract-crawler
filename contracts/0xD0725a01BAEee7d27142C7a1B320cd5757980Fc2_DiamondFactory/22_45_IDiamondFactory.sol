// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IDiamondCut } from "./IDiamondCut.sol";

struct DiamondFactoryInit {
    string setName;
    IDiamondCut.FacetCut[] facetAddresses;
}

struct DiamondFactoryContract {
    string[] diamondSymbols;
    mapping(string => address) diamondAddresses;
    mapping(string => IDiamondCut.FacetCut[]) facetsToAdd;
    string defaultFacetSet;
    address diamondInit_;
    bytes calldata_;
}


struct DiamondFactoryStorage {
  DiamondFactoryContract contractData;
}