// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/ExtendedSelfMulticall.sol";
import "./aggregation/Median.sol";
import "./interfaces/IDataFeedServer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Contract that serves Beacons and Beacon sets
/// @notice A Beacon is a live data feed addressed by an ID, which is derived
/// from an Airnode address and a template ID. This is suitable where the more
/// recent data point is always more favorable, e.g., in the context of an
/// asset price data feed. Beacons can also be seen as one-Airnode data feeds
/// that can be used individually or combined to build Beacon sets.
contract DataFeedServer is ExtendedSelfMulticall, Median, IDataFeedServer {
    using ECDSA for bytes32;

    // Airnodes serve their fulfillment data along with timestamps. This
    // contract casts the reported data to `int224` and the timestamp to
    // `uint32`, which works until year 2106.
    struct DataFeed {
        int224 value;
        uint32 timestamp;
    }

    /// @notice Data feed with ID
    mapping(bytes32 => DataFeed) internal _dataFeeds;

    /// @dev Reverts if the timestamp is from more than 1 hour in the future
    modifier onlyValidTimestamp(uint256 timestamp) virtual {
        unchecked {
            require(
                timestamp < block.timestamp + 1 hours,
                "Timestamp not valid"
            );
        }
        _;
    }

    /// @notice Updates the Beacon set using the current values of its Beacons
    /// @dev As an oddity, this function still works if some of the IDs in
    /// `beaconIds` belong to Beacon sets rather than Beacons. This can be used
    /// to implement hierarchical Beacon sets.
    /// @param beaconIds Beacon IDs
    /// @return beaconSetId Beacon set ID
    function updateBeaconSetWithBeacons(
        bytes32[] memory beaconIds
    ) public override returns (bytes32 beaconSetId) {
        (int224 updatedValue, uint32 updatedTimestamp) = aggregateBeacons(
            beaconIds
        );
        beaconSetId = deriveBeaconSetId(beaconIds);
        DataFeed storage beaconSet = _dataFeeds[beaconSetId];
        if (beaconSet.timestamp == updatedTimestamp) {
            require(
                beaconSet.value != updatedValue,
                "Does not update Beacon set"
            );
        }
        _dataFeeds[beaconSetId] = DataFeed({
            value: updatedValue,
            timestamp: updatedTimestamp
        });
        emit UpdatedBeaconSetWithBeacons(
            beaconSetId,
            updatedValue,
            updatedTimestamp
        );
    }

    /// @notice Reads the data feed with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function _readDataFeedWithId(
        bytes32 dataFeedId
    ) internal view returns (int224 value, uint32 timestamp) {
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
        require(timestamp > 0, "Data feed not initialized");
    }

    /// @notice Derives the Beacon ID from the Airnode address and template ID
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @return beaconId Beacon ID
    function deriveBeaconId(
        address airnode,
        bytes32 templateId
    ) internal pure returns (bytes32 beaconId) {
        beaconId = keccak256(abi.encodePacked(airnode, templateId));
    }

    /// @notice Derives the Beacon set ID from the Beacon IDs
    /// @dev Notice that `abi.encode()` is used over `abi.encodePacked()`
    /// @param beaconIds Beacon IDs
    /// @return beaconSetId Beacon set ID
    function deriveBeaconSetId(
        bytes32[] memory beaconIds
    ) internal pure returns (bytes32 beaconSetId) {
        beaconSetId = keccak256(abi.encode(beaconIds));
    }

    /// @notice Called privately to process the Beacon update
    /// @param beaconId Beacon ID
    /// @param timestamp Timestamp used in the signature
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    /// @return updatedBeaconValue Updated Beacon value
    function processBeaconUpdate(
        bytes32 beaconId,
        uint256 timestamp,
        bytes calldata data
    )
        internal
        onlyValidTimestamp(timestamp)
        returns (int224 updatedBeaconValue)
    {
        updatedBeaconValue = decodeFulfillmentData(data);
        require(
            timestamp > _dataFeeds[beaconId].timestamp,
            "Does not update timestamp"
        );
        _dataFeeds[beaconId] = DataFeed({
            value: updatedBeaconValue,
            timestamp: uint32(timestamp)
        });
    }

    /// @notice Called privately to decode the fulfillment data
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    /// @return decodedData Decoded fulfillment data
    function decodeFulfillmentData(
        bytes memory data
    ) internal pure returns (int224) {
        require(data.length == 32, "Data length not correct");
        int256 decodedData = abi.decode(data, (int256));
        require(
            decodedData >= type(int224).min && decodedData <= type(int224).max,
            "Value typecasting error"
        );
        return int224(decodedData);
    }

    /// @notice Called privately to aggregate the Beacons and return the result
    /// @param beaconIds Beacon IDs
    /// @return value Aggregation value
    /// @return timestamp Aggregation timestamp
    function aggregateBeacons(
        bytes32[] memory beaconIds
    ) internal view returns (int224 value, uint32 timestamp) {
        uint256 beaconCount = beaconIds.length;
        require(beaconCount > 1, "Specified less than two Beacons");
        int256[] memory values = new int256[](beaconCount);
        int256[] memory timestamps = new int256[](beaconCount);
        for (uint256 ind = 0; ind < beaconCount; ) {
            DataFeed storage dataFeed = _dataFeeds[beaconIds[ind]];
            values[ind] = dataFeed.value;
            timestamps[ind] = int256(uint256(dataFeed.timestamp));
            unchecked {
                ind++;
            }
        }
        value = int224(median(values));
        timestamp = uint32(uint256(median(timestamps)));
    }
}