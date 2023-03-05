// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPythParser.sol";
import "./IPythWithGetters.sol";
import "./UnsafeBytesLib.sol";

contract PythParser is IPythParser {
  // Update data is coming from an invalid data source.
  error InvalidUpdateDataSource();
  // Update data is invalid (e.g., deserialization error)
  error InvalidUpdateData(string reason);
  // Given message is not a valid Wormhole VAA.
  error InvalidWormholeVaa(string reason);
  // Price id not found in the price update data
  error PriceFeedNotFound(bytes32 priceId);

  IPythWithGetters immutable pyth;

  constructor(IPythWithGetters _pyth) {
    pyth = _pyth;
  }

  function parseAndVerifyBatchAttestationVM(
    bytes memory encodedVm
  ) internal view returns (IWormhole.VM memory vm) {
    {
      bool valid;
      string memory reason;
      (vm, valid, reason) = pyth.wormhole().parseAndVerifyVM(encodedVm);
      if (!valid) revert InvalidWormholeVaa(reason);
    }

    if (!pyth.isValidDataSource(vm.emitterChainId, vm.emitterAddress))
      revert InvalidUpdateDataSource();
  }

  function parseBatchAttestationHeader(
    bytes memory encoded
  )
    internal
    pure
    returns (uint index, uint nAttestations, uint attestationSize)
  {
    unchecked {
      index = 0;

      // Check header
      {
        uint32 magic = UnsafeBytesLib.toUint32(encoded, index);
        index += 4;
        if (magic != 0x50325748)
          revert InvalidUpdateData("invalid magic number");

        uint16 versionMajor = UnsafeBytesLib.toUint16(encoded, index);
        index += 2;
        if (versionMajor != 3)
          revert InvalidUpdateData("invalid major version");

        // This value is only used as the check below which currently
        // never reverts
        // uint16 versionMinor = UnsafeBytesLib.toUint16(encoded, index);
        index += 2;

        // This check is always false as versionMinor is 0, so it is commented.
        // in the future that the minor version increases this will have effect.
        // if(versionMinor < 0) revert InvalidUpdateData();

        uint16 hdrSize = UnsafeBytesLib.toUint16(encoded, index);
        index += 2;

        // NOTE(2022-04-19): Currently, only payloadId comes after
        // hdrSize. Future extra header fields must be read using a
        // separate offset to respect hdrSize, i.e.:
        //
        // uint hdrIndex = 0;
        // bpa.header.payloadId = UnsafeBytesLib.toUint8(encoded, index + hdrIndex);
        // hdrIndex += 1;
        //
        // bpa.header.someNewField = UnsafeBytesLib.toUint32(encoded, index + hdrIndex);
        // hdrIndex += 4;
        //
        // // Skip remaining unknown header bytes
        // index += bpa.header.hdrSize;

        uint8 payloadId = UnsafeBytesLib.toUint8(encoded, index);

        // Skip remaining unknown header bytes
        index += hdrSize;

        // Payload ID of 2 required for batch headerBa
        if (payloadId != 2) revert InvalidUpdateData("invalid payloadId");
      }

      // Parse the number of attestations
      nAttestations = UnsafeBytesLib.toUint16(encoded, index);
      index += 2;

      // Parse the attestation size
      attestationSize = UnsafeBytesLib.toUint16(encoded, index);
      index += 2;

      // Given the message is valid the arithmetic below should not overflow, and
      // even if it overflows then the require would fail.
      // if (encoded.length != (index + (attestationSize * nAttestations)))
      if (encoded.length != (index + (attestationSize * nAttestations)))
        revert InvalidUpdateData("invalid encoded length");
    }
  }

  function parseSingleAttestationFromBatch(
    bytes memory encoded,
    uint index,
    uint attestationSize
  ) internal pure returns (PythInternalPriceInfo memory info, bytes32 priceId) {
    unchecked {
      // NOTE: We don't advance the global index immediately.
      // attestationIndex is an attestation-local offset used
      // for readability and easier debugging.
      uint attestationIndex = 0;

      // Unused bytes32 product id
      attestationIndex += 32;

      priceId = UnsafeBytesLib.toBytes32(encoded, index + attestationIndex);
      attestationIndex += 32;

      info.price = int64(
        UnsafeBytesLib.toUint64(encoded, index + attestationIndex)
      );
      attestationIndex += 8;

      info.conf = UnsafeBytesLib.toUint64(encoded, index + attestationIndex);
      attestationIndex += 8;

      info.expo = int32(
        UnsafeBytesLib.toUint32(encoded, index + attestationIndex)
      );
      attestationIndex += 4;

      info.emaPrice = int64(
        UnsafeBytesLib.toUint64(encoded, index + attestationIndex)
      );
      attestationIndex += 8;

      info.emaConf = UnsafeBytesLib.toUint64(encoded, index + attestationIndex);
      attestationIndex += 8;

      {
        // Status is an enum (encoded as uint8) with the following values:
        // 0 = UNKNOWN: The price feed is not currently updating for an unknown reason.
        // 1 = TRADING: The price feed is updating as expected.
        // 2 = HALTED: The price feed is not currently updating because trading in the product has been halted.
        // 3 = AUCTION: The price feed is not currently updating because an auction is setting the price.
        uint8 status = UnsafeBytesLib.toUint8(
          encoded,
          index + attestationIndex
        );
        attestationIndex += 1;

        // Unused uint32 numPublishers
        attestationIndex += 4;

        // Unused uint32 numPublishers
        attestationIndex += 4;

        // Unused uint64 attestationTime
        attestationIndex += 8;

        info.publishTime = UnsafeBytesLib.toUint64(
          encoded,
          index + attestationIndex
        );
        attestationIndex += 8;

        if (status == 1) {
          // status == TRADING
          attestationIndex += 24;
        } else {
          // If status is not trading then the latest available price is
          // the previous price info that are passed here.

          // Previous publish time
          info.publishTime = UnsafeBytesLib.toUint64(
            encoded,
            index + attestationIndex
          );
          attestationIndex += 8;

          // Previous price
          info.price = int64(
            UnsafeBytesLib.toUint64(encoded, index + attestationIndex)
          );
          attestationIndex += 8;

          // Previous confidence
          info.conf = UnsafeBytesLib.toUint64(
            encoded,
            index + attestationIndex
          );
          attestationIndex += 8;
        }
      }

      if (attestationIndex > attestationSize)
        revert InvalidUpdateData("attestationIndex");
    }
  }

  function parsePriceFeedUpdates(
    bytes[] memory updateData,
    bytes32[] memory priceIds
  ) public view returns (PythInternalPriceInfo[] memory priceFeeds) {
    unchecked {
      priceFeeds = new PythInternalPriceInfo[](priceIds.length);
      for (uint i = 0; i < updateData.length; ++i) {
        bytes memory encoded;
        {
          IWormhole.VM memory vm = parseAndVerifyBatchAttestationVM(
            updateData[i]
          );
          encoded = vm.payload;
        }

        (
          uint index,
          uint nAttestations,
          uint attestationSize
        ) = parseBatchAttestationHeader(encoded);

        // Deserialize each attestation
        for (uint j = 0; j < nAttestations; j++) {
          // NOTE: We don't advance the global index immediately.
          // attestationIndex is an attestation-local offset used
          // for readability and easier debugging.
          uint attestationIndex = 0;

          // Unused bytes32 product id
          attestationIndex += 32;

          bytes32 priceId = UnsafeBytesLib.toBytes32(
            encoded,
            index + attestationIndex
          );

          // Check whether the caller requested for this data.
          uint k = 0;
          for (; k < priceIds.length; k++) {
            if (priceIds[k] == priceId) {
              break;
            }
          }

          // If priceFeed[k].id != 0 then it means that there was a valid
          // update for priceIds[k] and we don't need to process this one.
          if (k == priceIds.length || priceFeeds[k].id == priceId) {
            index += attestationSize;
            continue;
          }

          (
            PythInternalPriceInfo memory info,

          ) = parseSingleAttestationFromBatch(encoded, index, attestationSize);

          priceFeeds[k].id = priceId;
          priceFeeds[k].price = info.price;
          priceFeeds[k].conf = info.conf;
          priceFeeds[k].expo = info.expo;
          priceFeeds[k].emaPrice = info.emaPrice;
          priceFeeds[k].emaConf = info.emaConf;
          priceFeeds[k].publishTime = info.publishTime;

          index += attestationSize;
        }
      }
    }
    for (uint i = 0; i < priceIds.length; ++i) {
      if (priceIds[i] != priceFeeds[i].id)
        revert PriceFeedNotFound(priceIds[i]);
    }
  }
}