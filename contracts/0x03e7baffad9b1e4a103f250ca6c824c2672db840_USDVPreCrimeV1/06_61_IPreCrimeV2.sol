// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

struct PreCrimePeer {
    uint32 eid;
    bytes32 precrime;
    bytes32 oapp;
}

interface IPreCrimeV2 {
    error OnlyOffChain();

    // for simulate()
    error PacketOversize(uint max, uint actual);
    error PacketUnsorted();
    error SimulationFailed(bytes reason);

    // for precrime()
    error SimulationResultNotFound(uint32 eid);
    error InvalidSimulationResult(uint32 eid, bytes reason);
    error CrimeFound(bytes crime);

    function getConfig(bytes[] calldata _packets) external returns (bytes memory);

    function simulate(bytes[] calldata _packets) external payable returns (bytes memory);

    function buildSimulationResult() external view returns (bytes memory);

    function precrime(bytes[] calldata _packets, bytes[] calldata _simulations) external;

    function version() external view returns (uint64 major, uint8 minor);
}