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

abstract contract ConvexFraxConstants is INameIdentifier {
    string public constant override NAME = "convex-frax";

    uint256 public constant PID = 32;

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);

    IERC20 public constant FXS =
        IERC20(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

    IMetaPool public constant META_POOL =
        IMetaPool(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);

    IBaseRewardPool public constant REWARD_CONTRACT =
        IBaseRewardPool(0xB900EF131301B307dB5eFcbed9DBb50A3e209B2e);
}