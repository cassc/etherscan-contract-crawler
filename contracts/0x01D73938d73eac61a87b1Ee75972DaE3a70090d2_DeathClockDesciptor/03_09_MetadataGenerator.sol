// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './JsonWriter.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

contract MetadataGenerator {
    using JsonWriter for JsonWriter.Json;
    using Strings for uint256;

    struct metadataPayload {
        uint256 id;
        bool isRemnant;
        uint256 minted;
        uint256 expDate;
        uint8 cid;
        uint8 tid;
        uint8 bid;
        bytes32 color;
        bytes32 topImage;
        bytes32 bottomImage;
        uint256 remnants;
        uint256 resets;
        string imageUrl;
        string webAppUrl;
        address acct;
    }

    struct attrPayload {
        string color;
        bool isRemnant;
        string topImage;
        string bottomImage;
        uint256 remnants;
        uint256 resets;
        uint256 expDate;
        address acct;
    }

    function _bytes32ToString(bytes32 _bytes32)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function generateMetadataJSON(metadataPayload memory payload)
        internal
        pure
        returns (string memory)
    {
        JsonWriter.Json memory writer;
        writer = writer.writeStartObject();
        string memory idStr = Strings.toString(payload.id);
        writer = writer.writeStringProperty(
            'name',
            string.concat('DEATH CLOCK ', idStr)
        );
        writer = writer.writeStringProperty(
            'description',
            'Become a fossil. Form a pebble. Turn to ash. Death Clock is a serial NFT project and a reminder that time is not on our side.'
        );
        writer = writer.writeStringProperty(
            'external_url',
            'https://deathclock.live'
        );

        writer = writer.writeStringProperty(
            'image',
            string.concat('ipfs://', payload.imageUrl)
        );
        string memory cidStr = Strings.toString(payload.cid);
        string memory tidStr = Strings.toString(payload.tid);
        string memory bidStr = Strings.toString(payload.bid);
        string memory mintedStr = Strings.toString(payload.minted);
        string memory expDateStr = Strings.toString(payload.expDate);
        string memory params;
        if (payload.isRemnant) {
            params = string.concat(
                '?id=',
                idStr,
                '&minted=',
                mintedStr,
                '&expDate=',
                expDateStr,
                '&acct=',
                Strings.toHexString(uint256(uint160(payload.acct)), 20)
            );
        } else {
            string memory p1 = string.concat(
                '?id=',
                idStr,
                '&cid=',
                cidStr,
                '&tid=',
                tidStr,
                '&bid=',
                bidStr
            );
            string memory p2 = string.concat(
                '&minted=',
                mintedStr,
                '&expDate=',
                expDateStr,
                '&acct=',
                Strings.toHexString(uint256(uint160(payload.acct)), 20)
            );
            params = string.concat(p1, p2);
        }

        writer = writer.writeStringProperty(
            'animation_url',
            string.concat(payload.webAppUrl, params)
        );

        writer = _generateAttributes(
            writer,
            attrPayload(
                string(abi.encodePacked(_bytes32ToString(payload.color))),
                payload.isRemnant,
                string(
                    abi.encodePacked(_bytes32ToString(payload.topImage), '.jpg')
                ),
                string(
                    abi.encodePacked(
                        _bytes32ToString(payload.bottomImage),
                        '.jpg'
                    )
                ),
                payload.remnants,
                payload.resets,
                payload.expDate,
                payload.acct
            )
        );
        writer = writer.writeEndObject();
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(abi.encodePacked(writer.value))
                )
            );
    }

    function _addStringAttribute(
        JsonWriter.Json memory _writer,
        string memory key,
        string memory value
    ) internal pure returns (JsonWriter.Json memory writer) {
        writer = _writer.writeStartObject();
        writer = writer.writeStringProperty('trait_type', key);
        writer = writer.writeStringProperty('value', value);
        writer = writer.writeEndObject();
    }

    function _addDateAttribute(
        JsonWriter.Json memory _writer,
        string memory key,
        uint256 value
    ) internal pure returns (JsonWriter.Json memory writer) {
        writer = _writer.writeStartObject();
        writer = writer.writeStringProperty('trait_type', key);
        writer = writer.writeStringProperty('display_type', 'date');
        writer = writer.writeUintProperty('value', value);
        writer = writer.writeEndObject();
    }

    function _generateAttributes(
        JsonWriter.Json memory _writer,
        attrPayload memory payload
    ) internal pure returns (JsonWriter.Json memory writer) {
        writer = _writer.writeStartArray('attributes');
        _addDateAttribute(writer, 'Time of Death', payload.expDate);
        if (!payload.isRemnant) {
            _addStringAttribute(writer, 'Colorway', payload.color);
            _addStringAttribute(writer, 'Remnants', Strings.toString(payload.remnants));
            _addStringAttribute(writer, 'Resets', Strings.toString(payload.resets));
            _addStringAttribute(writer, 'Image Top', payload.topImage);
            _addStringAttribute(writer, 'Image Botom', payload.bottomImage);
        }
        _addStringAttribute(
            writer,
            'Future Departed',
            Strings.toHexString(uint256(uint160(payload.acct)), 20)
        );
        writer = writer.writeEndArray();
    }
}