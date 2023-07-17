// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { MultiCall, MultiCallOps } from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";
import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

struct RouterResult {
    uint256 amount;
    uint256 gasUsage;
    MultiCall[] calls;
}

library RouterResultOps {
    using MultiCallOps for MultiCall[];

    function trim(RouterResult memory r)
        internal
        pure
        returns (RouterResult memory)
    {
        r.calls = r.calls.trim();
        return r;
    }

    function isBetter(
        RouterResult memory pfr1,
        RouterResult memory pfr2,
        uint256 gasPriceTargetRAY
    ) internal pure returns (bool) {
        return
            (pfr1.amount - (pfr1.gasUsage * gasPriceTargetRAY) / RAY) >
            (pfr2.amount - (pfr2.gasUsage * gasPriceTargetRAY) / RAY);
    }
}