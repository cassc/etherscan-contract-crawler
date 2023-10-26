// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@layerzerolabs/lz-evm-oapp-v2/contracts/standards/precrime/PreCrimeV2.sol";
import "../messaging/Messaging.sol";
import "../usdv/USDVBase.sol";
import {VaultManager} from "../vault/VaultManager.sol";

contract USDVPreCrimeV2 is PreCrimeV2 {
    using BytesLib for bytes;
    using SafeCast for uint;

    bool internal immutable isMain;
    address internal immutable usdv;

    constructor(address _endpoint, address _usdvSimulator, bool _isMain) PreCrimeV2(_endpoint, _usdvSimulator) {
        isMain = _isMain;
        usdv = Messaging(_usdvSimulator).usdv();
    }

    function buildSimulationResult() external view override returns (bytes memory result) {
        uint64 totalSupply = IERC20(usdv).totalSupply().toUint64();
        if (isMain) {
            address vaultManager = USDVBase(usdv).getRole(Role.VAULT);
            (, uint64 globalSupply) = VaultManager(vaultManager).usdvVault();
            result = abi.encodePacked(isMain, totalSupply, globalSupply);
        } else {
            result = abi.encodePacked(isMain, totalSupply);
        }
    }

    function _getPreCrimePeers(
        InboundPacket[] memory _packets
    ) internal view override returns (PreCrimePeer[] memory peers) {
        for (uint i = 0; i < _packets.length; i++) {
            InboundPacket memory packet = _packets[i];
            if (IPreCrimeV2Simulator(simulator).isPeer(packet.origin.srcEid, packet.origin.sender)) {
                return precrimePeers;
            }
        }
        return new PreCrimePeer[](0);
    }

    function _precrime(
        InboundPacket[] memory /*_packets*/,
        uint32[] memory _eids,
        bytes[] memory _simulations
    ) internal pure override {
        uint64 expected = 0;
        uint64 actual = 0;
        for (uint i = 0; i < _simulations.length; i++) {
            uint32 eid = _eids[i];
            bytes memory simulation = _simulations[i];

            bool main = simulation.toUint8(0) == 1;
            uint64 supply = simulation.toUint64(1);
            actual += supply;

            if (main) {
                uint64 globalSupply = simulation.toUint64(9);
                if (expected > 0) revert InvalidSimulationResult(eid, "more than one main usdv simulation");
                expected = globalSupply;
            }
        }

        if (actual > expected) revert CrimeFound("invalid supply");
    }
}