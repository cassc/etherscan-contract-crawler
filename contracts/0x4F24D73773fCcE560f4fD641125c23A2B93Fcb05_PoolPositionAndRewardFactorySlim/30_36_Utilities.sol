// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";

library Utilities {
    function nameMaker(IPool _pool, uint256 factoryCount, bool fullName) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    fullName ? "Maverick Position-" : "MP-",
                    IERC20Metadata(address(_pool.tokenA())).symbol(),
                    "-",
                    IERC20Metadata(address(_pool.tokenB())).symbol(),
                    "-",
                    Strings.toString(factoryCount)
                )
            );
    }
}