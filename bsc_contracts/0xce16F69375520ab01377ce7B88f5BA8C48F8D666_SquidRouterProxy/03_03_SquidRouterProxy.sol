// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Proxy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Proxy.sol";

contract SquidRouterProxy is Proxy {
    function contractId() internal pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }
}