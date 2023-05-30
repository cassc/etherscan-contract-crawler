// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataFeedServer.sol";
import "./interfaces/IBeaconUpdatesWithSignedData.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Contract that updates Beacons using signed data
contract BeaconUpdatesWithSignedData is
    DataFeedServer,
    IBeaconUpdatesWithSignedData
{
    using ECDSA for bytes32;

    /// @notice Updates a Beacon using data signed by the Airnode
    /// @dev The signed data here is intentionally very general for practical
    /// reasons. It is less demanding on the signer to have data signed once
    /// and use that everywhere.
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @param timestamp Signature timestamp
    /// @param data Update data (an `int256` encoded in contract ABI)
    /// @param signature Template ID, timestamp and the update data signed by
    /// the Airnode
    /// @return beaconId Updated Beacon ID
    function updateBeaconWithSignedData(
        address airnode,
        bytes32 templateId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override returns (bytes32 beaconId) {
        require(
            (
                keccak256(abi.encodePacked(templateId, timestamp, data))
                    .toEthSignedMessageHash()
            ).recover(signature) == airnode,
            "Signature mismatch"
        );
        beaconId = deriveBeaconId(airnode, templateId);
        int224 updatedValue = processBeaconUpdate(beaconId, timestamp, data);
        emit UpdatedBeaconWithSignedData(
            beaconId,
            updatedValue,
            uint32(timestamp)
        );
    }
}