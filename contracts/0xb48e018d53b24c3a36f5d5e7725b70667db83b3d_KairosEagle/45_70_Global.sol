// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Protocol, SupplyPosition} from "./Storage.sol";
import {Ray} from "./Objects.sol";

/* rationale of the naming of the hash is to use kairos loan's ENS as domain, the subject of the storage struct as
subdomain and the version to anticipate upgrade. Order is revered compared to urls as it's the usage in code such as in
java imports */
bytes32 constant PROTOCOL_SP = keccak256("eth.kairosloan.protocol.v1.0");
bytes32 constant SUPPLY_SP = keccak256("eth.kairosloan.supply-position.v1.0");

/* Ray is chosed as the only fixed-point decimals approach as it allow extreme and versatile precision accross erc20s
and timeframes */
uint256 constant RAY = 1e27;
Ray constant ONE = Ray.wrap(RAY);
Ray constant ZERO = Ray.wrap(0);

/* solhint-disable func-visibility */

/// @dev getters of storage regions of the contract for specified usage

/* we access storage only through functions in facets following the diamond storage pattern */

function protocolStorage() pure returns (Protocol storage protocol) {
    bytes32 position = PROTOCOL_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        protocol.slot := position
    }
}

function supplyPositionStorage() pure returns (SupplyPosition storage sp) {
    bytes32 position = SUPPLY_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        sp.slot := position
    }
}