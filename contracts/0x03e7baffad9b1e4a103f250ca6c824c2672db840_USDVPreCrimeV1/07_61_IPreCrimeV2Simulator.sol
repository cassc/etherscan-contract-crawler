// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import {InboundPacket} from "../libs/Packet.sol";

interface IPreCrimeV2Simulator {
    // this error is only used to return the simulation result
    error SimulationResult(bytes result);

    function lzReceiveAndRevert(InboundPacket[] calldata _packets) external payable;

    function isPeer(uint32 _eid, bytes32 _peer) external view returns (bool);

    function oapp() external view returns (address);
}