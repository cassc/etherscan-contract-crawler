// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    IBaseRewardPool
} from "contracts/protocols/convex/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract ConvexDolaConstants is INameIdentifier {
    string public constant override NAME = "convex-dola";

    uint256 public constant PID = 62;

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0xAA5A67c256e27A5d80712c51971408db3370927D);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x865377367054516e17014CcdED1e7d814EDC9ce4);

    IMetaPool public constant META_POOL =
        IMetaPool(0xAA5A67c256e27A5d80712c51971408db3370927D);

    IBaseRewardPool public constant REWARD_CONTRACT =
        IBaseRewardPool(0x835f69e58087E5B6bffEf182fe2bf959Fe253c3c);
}