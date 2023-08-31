// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IDiamond} from "./IDiamond.sol";

/**
 * @title DiamondCutFacet
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Required function selector modification to support EIP-2535
 */
interface IDiamondCut is IDiamond {
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}