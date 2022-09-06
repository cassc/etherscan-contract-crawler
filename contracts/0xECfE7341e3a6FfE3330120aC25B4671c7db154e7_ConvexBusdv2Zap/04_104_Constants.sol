// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    IBaseRewardPool
} from "contracts/protocols/convex/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract ConvexBusdv2Constants is INameIdentifier {
    string public constant override NAME = "convex-busdv2";

    uint256 public constant PID = 34;

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);

    IMetaPool public constant META_POOL =
        IMetaPool(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a);

    IBaseRewardPool public constant REWARD_CONTRACT =
        IBaseRewardPool(0xbD223812d360C9587921292D0644D18aDb6a2ad0);
}