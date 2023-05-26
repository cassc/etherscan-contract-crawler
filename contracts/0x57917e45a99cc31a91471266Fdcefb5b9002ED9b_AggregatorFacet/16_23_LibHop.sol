// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";

struct Hop {
    address addr;
    uint256 amountIn;
    address recipient;
    bytes[] poolDataList;
    address[] path;
}

error InvalidSingleHop();

library LibHop {
    using LibAsset for address;

    function enforceSingleHop(Hop memory self) internal pure {
        if (self.path.length != 2) {
            revert InvalidSingleHop();
        }
    }

    function enforceTransferToRecipient(Hop memory self) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        address path = self.path[self.path.length - 1];

        if (self.recipient != address(this)) {
            path.transfer(self.recipient, path.getBalance() - s.deposits[path]);
        }
    }
}