// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDiamondCut.sol";

interface IDiamondInit {
    function initialize(
        address _owner, 
        IDiamondCut.FacetCut[] memory _facets,
        address _init,
        bytes calldata _calldata) external;
}