// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { OrderTypes } from "./OrderTypes.sol";

/**
 * @title FlowMatchExecutorTyoes
 * @author Joe
 * @notice This library contains the match executor types
 */
library FlowMatchExecutorTypes {
    struct Call {
        bytes data;
        uint256 value;
        address payable to;
    }

    struct ExternalFulfillments {
        Call[] calls;
        OrderTypes.OrderItem[] nftsToTransfer;
    }

    enum MatchOrdersType {
        OneToOneSpecific,
        OneToOneUnspecific,
        OneToMany
    }

    struct MatchOrders {
        OrderTypes.MakerOrder[] buys;
        OrderTypes.MakerOrder[] sells;
        OrderTypes.OrderItem[][] constructs;
        MatchOrdersType matchType;
    }

    struct Batch {
        ExternalFulfillments externalFulfillments;
        MatchOrders[] matches;
    }
}