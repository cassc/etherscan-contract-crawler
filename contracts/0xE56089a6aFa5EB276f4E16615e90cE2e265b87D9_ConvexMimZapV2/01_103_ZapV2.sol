// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {ConvexMimConstants} from "./Constants.sol";
import {
    MetaPoolDepositorZapV2
} from "contracts/protocols/convex/metapool/Imports.sol";

contract ConvexMimZapV2 is MetaPoolDepositorZapV2, ConvexMimConstants {
    constructor()
        public
        MetaPoolDepositorZapV2(META_POOL, address(LP_TOKEN), PID, 10000, 10000) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](2);
        allocationNames[0] = "curve-mim";
        allocationNames[1] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(1);
        allocations[4] = PRIMARY_UNDERLYER;
        return allocations;
    }
}