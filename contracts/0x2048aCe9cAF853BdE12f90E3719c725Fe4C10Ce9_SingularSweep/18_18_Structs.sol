// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Sweep {
    struct ERC20Detail {
        address tokenAddr;
        uint256 amount;
    }

    struct ERC721Detail {
        address tokenAddr;
        uint256[] ids;
    }

    struct ERC1155Detail {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct TradeDetails {
        uint256 marketId;
        uint256 value; // value used only for a call
        bytes tradeData;
    }
}