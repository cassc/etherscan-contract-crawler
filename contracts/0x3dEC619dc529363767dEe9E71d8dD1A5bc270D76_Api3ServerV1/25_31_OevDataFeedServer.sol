// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataFeedServer.sol";
import "./interfaces/IOevDataFeedServer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./proxies/interfaces/IOevProxy.sol";

/// @title Contract that serves OEV Beacons and Beacon sets
/// @notice OEV Beacons and Beacon sets can be updated by the winner of the
/// respective OEV auctions. The beneficiary can withdraw the proceeds from
/// this contract.
contract OevDataFeedServer is DataFeedServer, IOevDataFeedServer {
    using ECDSA for bytes32;

    /// @notice Data feed with ID specific to the OEV proxy
    /// @dev This implies that an update as a result of an OEV auction only
    /// affects contracts that read through the respective proxy that the
    /// auction was being held for
    mapping(address => mapping(bytes32 => DataFeed))
        internal _oevProxyToIdToDataFeed;

    /// @notice Accumulated OEV auction proceeds for the specific proxy
    mapping(address => uint256) public override oevProxyToBalance;

    /// @notice Updates a data feed that the OEV proxy reads using the
    /// aggregation signed by the absolute majority of the respective Airnodes
    /// for the specific bid
    /// @dev For when the data feed being updated is a Beacon set, an absolute
    /// majority of the Airnodes that power the respective Beacons must sign
    /// the aggregated value and timestamp. While doing so, the Airnodes should
    /// refer to data signed to update an absolute majority of the respective
    /// Beacons. The Airnodes should require the data to be fresh enough (e.g.,
    /// at most 2 minutes-old), and tightly distributed around the resulting
    /// aggregation (e.g., within 1% deviation), and reject to provide an OEV
    /// proxy data feed update signature if these are not satisfied.
    /// @param oevProxy OEV proxy that reads the data feed
    /// @param dataFeedId Data feed ID
    /// @param updateId Update ID
    /// @param timestamp Signature timestamp
    /// @param data Update data (an `int256` encoded in contract ABI)
    /// @param packedOevUpdateSignatures Packed OEV update signatures, which
    /// include the Airnode address, template ID and these signed with the OEV
    /// update hash
    function updateOevProxyDataFeedWithSignedData(
        address oevProxy,
        bytes32 dataFeedId,
        bytes32 updateId,
        uint256 timestamp,
        bytes calldata data,
        bytes[] calldata packedOevUpdateSignatures
    ) external payable override onlyValidTimestamp(timestamp) {
        require(
            timestamp > _oevProxyToIdToDataFeed[oevProxy][dataFeedId].timestamp,
            "Does not update timestamp"
        );
        bytes32 oevUpdateHash = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                oevProxy,
                dataFeedId,
                updateId,
                timestamp,
                data,
                msg.sender,
                msg.value
            )
        );
        int224 updatedValue = decodeFulfillmentData(data);
        uint32 updatedTimestamp = uint32(timestamp);
        uint256 beaconCount = packedOevUpdateSignatures.length;
        if (beaconCount > 1) {
            bytes32[] memory beaconIds = new bytes32[](beaconCount);
            uint256 validSignatureCount;
            for (uint256 ind = 0; ind < beaconCount; ) {
                bool signatureIsNotOmitted;
                (
                    signatureIsNotOmitted,
                    beaconIds[ind]
                ) = unpackAndValidateOevUpdateSignature(
                    oevUpdateHash,
                    packedOevUpdateSignatures[ind]
                );
                if (signatureIsNotOmitted) {
                    unchecked {
                        validSignatureCount++;
                    }
                }
                unchecked {
                    ind++;
                }
            }
            // "Greater than or equal to" is not enough because full control
            // of aggregation requires an absolute majority
            require(
                validSignatureCount > beaconCount / 2,
                "Not enough signatures"
            );
            require(
                dataFeedId == deriveBeaconSetId(beaconIds),
                "Beacon set ID mismatch"
            );
            emit UpdatedOevProxyBeaconSetWithSignedData(
                dataFeedId,
                oevProxy,
                updateId,
                updatedValue,
                updatedTimestamp
            );
        } else if (beaconCount == 1) {
            {
                (
                    bool signatureIsNotOmitted,
                    bytes32 beaconId
                ) = unpackAndValidateOevUpdateSignature(
                        oevUpdateHash,
                        packedOevUpdateSignatures[0]
                    );
                require(signatureIsNotOmitted, "Missing signature");
                require(dataFeedId == beaconId, "Beacon ID mismatch");
            }
            emit UpdatedOevProxyBeaconWithSignedData(
                dataFeedId,
                oevProxy,
                updateId,
                updatedValue,
                updatedTimestamp
            );
        } else {
            revert("Did not specify any Beacons");
        }
        _oevProxyToIdToDataFeed[oevProxy][dataFeedId] = DataFeed({
            value: updatedValue,
            timestamp: updatedTimestamp
        });
        oevProxyToBalance[oevProxy] += msg.value;
    }

    /// @notice Withdraws the balance of the OEV proxy to the respective
    /// beneficiary account
    /// @dev This does not require the caller to be the beneficiary because we
    /// expect that in most cases, the OEV beneficiary will be a contract that
    /// will not be able to make arbitrary calls. Our choice can be worked
    /// around by implementing a beneficiary proxy.
    /// @param oevProxy OEV proxy
    function withdraw(address oevProxy) external override {
        address oevBeneficiary = IOevProxy(oevProxy).oevBeneficiary();
        require(oevBeneficiary != address(0), "Beneficiary address zero");
        uint256 balance = oevProxyToBalance[oevProxy];
        require(balance != 0, "OEV proxy balance zero");
        oevProxyToBalance[oevProxy] = 0;
        emit Withdrew(oevProxy, oevBeneficiary, balance);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = oevBeneficiary.call{value: balance}("");
        require(success, "Withdrawal reverted");
    }

    /// @notice Reads the data feed as the OEV proxy with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function _readDataFeedWithIdAsOevProxy(
        bytes32 dataFeedId
    ) internal view returns (int224 value, uint32 timestamp) {
        DataFeed storage oevDataFeed = _oevProxyToIdToDataFeed[msg.sender][
            dataFeedId
        ];
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        if (oevDataFeed.timestamp > dataFeed.timestamp) {
            (value, timestamp) = (oevDataFeed.value, oevDataFeed.timestamp);
        } else {
            (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
        }
        require(timestamp > 0, "Data feed not initialized");
    }

    /// @notice Called privately to unpack and validate the OEV update
    /// signature
    /// @param oevUpdateHash OEV update hash
    /// @param packedOevUpdateSignature Packed OEV update signature, which
    /// includes the Airnode address, template ID and these signed with the OEV
    /// update hash
    /// @return signatureIsNotOmitted If the signature is omitted in
    /// `packedOevUpdateSignature`
    /// @return beaconId Beacon ID
    function unpackAndValidateOevUpdateSignature(
        bytes32 oevUpdateHash,
        bytes calldata packedOevUpdateSignature
    ) private pure returns (bool signatureIsNotOmitted, bytes32 beaconId) {
        (address airnode, bytes32 templateId, bytes memory signature) = abi
            .decode(packedOevUpdateSignature, (address, bytes32, bytes));
        beaconId = deriveBeaconId(airnode, templateId);
        if (signature.length != 0) {
            require(
                (
                    keccak256(abi.encodePacked(oevUpdateHash, templateId))
                        .toEthSignedMessageHash()
                ).recover(signature) == airnode,
                "Signature mismatch"
            );
            signatureIsNotOmitted = true;
        }
    }
}