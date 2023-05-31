// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

library ApeDropStorage {
    bytes32 private constant STORAGE_SLOT =
        keccak256("niftykit.apps.ape.storage");

    struct Layout {
        IERC20Upgradeable _apeCoinContract;
        uint256 _apePrice;
        uint256 _apeRevenue;
        bool _apeInitialized;
        bool _apeSaleActive;
        bool _apePresaleActive;
    }

    function layout() internal pure returns (Layout storage ds) {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}