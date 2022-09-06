// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    IBaseRewardPool
} from "contracts/protocols/convex/common/interfaces/Imports.sol";
import {
    IMetaPool,
    IOldDepositor
} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract ConvexMimConstants is INameIdentifier {
    string public constant override NAME = "convex-mim";

    uint256 public constant PID = 40;

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);

    IERC20 public constant SPELL =
        IERC20(0x090185f2135308BaD17527004364eBcC2D37e5F6);

    IMetaPool public constant META_POOL =
        IMetaPool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);

    IBaseRewardPool public constant REWARD_CONTRACT =
        IBaseRewardPool(0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771);
}