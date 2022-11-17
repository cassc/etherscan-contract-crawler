// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { Charge, Signature } from "../../../../static/Structs.sol";

/**
 * @title  ICharge contract interface
 * @author Diagonal Finance
 * @notice Organization module. Encapsulates charge logic
 */
interface ICharge {
    function charge(Charge calldata chargeRequest, Signature calldata signature) external;

    function chargeWithPermit(
        Charge calldata chargeRequest,
        Signature calldata signature,
        bytes calldata permit
    ) external;
}