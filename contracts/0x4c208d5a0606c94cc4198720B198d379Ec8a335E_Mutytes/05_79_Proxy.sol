// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ProxyController } from "./ProxyController.sol";

/**
 * @title Proxy delegatecall fallback implementation
 */
abstract contract Proxy is ProxyController {
    fallback() external payable virtual {
        fallback_();
    }

    receive() external payable virtual {
        fallback_();
    }
}