// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { BaseTypes } from "./BaseTypes.sol";

library RequestTypes {

    // structs: requests
    struct BaseRequest {
        address sender;
        uint256 expiry;
        uint256 nonce;
    }
    struct CreateRaiseRequest {
        BaseTypes.Raise raise;
        BaseTypes.Vested vested;
        BaseTypes.Milestone[] milestones;
        BaseRequest base;
    }
    struct InvestRequest {
        string raiseId;
        uint256 investment;
        uint256 maxTicketSize;
        BaseRequest base;
    }

}