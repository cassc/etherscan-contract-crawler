// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    IBaseRewardPool
} from "contracts/protocols/convex/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract ConvexAlusdConstants is INameIdentifier {
    string public constant override NAME = "convex-alusd";

    uint256 public constant PID = 36;

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9);

    IERC20 public constant ALCX =
        IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);

    IMetaPool public constant META_POOL =
        IMetaPool(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);

    IBaseRewardPool public constant REWARD_CONTRACT =
        IBaseRewardPool(0x02E2151D4F351881017ABdF2DD2b51150841d5B3);
}