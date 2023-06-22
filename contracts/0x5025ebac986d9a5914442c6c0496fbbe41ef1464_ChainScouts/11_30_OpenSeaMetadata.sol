//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "./Integer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

enum NumericAttributeType {
    NUMBER,
    BOOST_PERCENTAGE,
    BOOST_NUMBER,
    DATE
}

struct Attribute {
    string displayType;
    string key;
    string serializedValue;
    string maxValue;
}

struct OpenSeaMetadata {
    string svg;
    string description;
    string name;
    uint24 backgroundColor;
    Attribute[] attributes;
}

library OpenSeaMetadataLibrary {
    using Strings for uint;

    struct ObjectKeyValuePair {
        string key;
        string serializedValue;
    }

    function uintToColorString(uint value, uint nBytes) internal pure returns (string memory) {
        bytes memory symbols = "0123456789ABCDEF";
        bytes memory buf = new bytes(nBytes * 2);

        for (uint i = 0; i < nBytes * 2; ++i) {
            buf[nBytes * 2 - 1 - i] = symbols[Integer.bitsFrom(value, (i * 4) + 3, i * 4)];
        }

        return string(buf);
    }

    function quote(string memory str) internal pure returns (string memory output) {
        return bytes(str).length > 0 ? string(abi.encodePacked(
            '"',
            str,
            '"'
        )) : "";
    }

    function makeStringAttribute(string memory key, string memory value) internal pure returns (Attribute memory) {
        return Attribute("", key, quote(value), "");
    }

    function makeNumericAttribute(NumericAttributeType nat, string memory key, string memory value, string memory maxValue) private pure returns (Attribute memory) {
        string memory s = "number";
        if (nat == NumericAttributeType.BOOST_PERCENTAGE) {
            s = "boost_percentage";
        }
        else if (nat == NumericAttributeType.BOOST_NUMBER) {
            s = "boost_number";
        }
        else if (nat == NumericAttributeType.DATE) {
            s = "date";
        }

        return Attribute(s, key, value, maxValue);
    }

    function makeFixedPoint(uint value, uint decimals) internal pure returns (string memory) {
        bytes memory st = bytes(value.toString());

        while (st.length < decimals) {
            st = abi.encodePacked(
                "0",
                st
            );
        }

        bytes memory ret = new bytes(st.length + 1);

        if (decimals >= st.length) {
            return string(abi.encodePacked("0.", st));
        }

        uint dl = st.length - decimals;

        uint i = 0;
        uint j = 0;

        while (i < ret.length) {
            if (i == dl) {
                ret[i] = '.';
                i++;
                continue;
            }

            ret[i] = st[j];

            i++;
            j++;
        }

        return string(ret);
    }

    function makeFixedPointAttribute(NumericAttributeType nat, string memory key, uint value, uint maxValue, uint decimals) internal pure returns (Attribute memory) {
        return makeNumericAttribute(nat, key, makeFixedPoint(value, decimals), maxValue == 0 ? "" : makeFixedPoint(maxValue, decimals));
    }

    function makeUintAttribute(NumericAttributeType nat, string memory key, uint value, uint maxValue) internal pure returns (Attribute memory) {
        return makeNumericAttribute(nat, key, value.toString(), maxValue == 0 ? "" : maxValue.toString());
    }

    function makeBooleanAttribute(string memory key, bool value) internal pure returns (Attribute memory) {
        return Attribute("", key, value ? "true" : "false", "");
    }

    function makeAttributesArray(Attribute[] memory attributes) internal pure returns (string memory output) {
        output = "[";
        bool empty = true;

        for (uint i = 0; i < attributes.length; ++i) {
            if (bytes(attributes[i].serializedValue).length > 0) {
                ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](4);
                kvps[0] = ObjectKeyValuePair("trait_type", quote(attributes[i].key));
                kvps[1] = ObjectKeyValuePair("display_type", quote(attributes[i].displayType));
                kvps[2] = ObjectKeyValuePair("value", attributes[i].serializedValue);
                kvps[3] = ObjectKeyValuePair("max_value", attributes[i].maxValue);

                output = string(abi.encodePacked(
                    output,
                    empty ? "" : ",",
                    makeObject(kvps)
                ));
                empty = false;
            }
        }

        output = string(abi.encodePacked(output, "]"));
    }

    function notEmpty(string memory s) internal pure returns (bool) {
        return bytes(s).length > 0;
    }

    function makeObject(ObjectKeyValuePair[] memory kvps) internal pure returns (string memory output) {
        output = "{";
        bool empty = true;

        for (uint i = 0; i < kvps.length; ++i) {
            if (bytes(kvps[i].serializedValue).length > 0) {
                output = string(abi.encodePacked(
                    output,
                    empty ? "" : ",",
                    '"',
                    kvps[i].key,
                    '":',
                    kvps[i].serializedValue
                ));
                empty = false;
            }
        }

        output = string(abi.encodePacked(output, "}"));
    }

    function makeMetadataWithExtraKvps(OpenSeaMetadata memory metadata, ObjectKeyValuePair[] memory extra) internal pure returns (string memory output) {
        /*
        string memory svgUrl = string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            string(Base64.encode(bytes(metadata.svg)))
        ));
        */

        string memory svgUrl = string(abi.encodePacked(
            "data:image/svg+xml;utf8,",
            metadata.svg
        ));

        ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](5 + extra.length);
        kvps[0] = ObjectKeyValuePair("name", quote(metadata.name));
        kvps[1] = ObjectKeyValuePair("description", quote(metadata.description));
        kvps[2] = ObjectKeyValuePair("image", quote(svgUrl));
        kvps[3] = ObjectKeyValuePair("background_color", quote(uintToColorString(metadata.backgroundColor, 3)));
        kvps[4] = ObjectKeyValuePair("attributes", makeAttributesArray(metadata.attributes));
        for (uint i = 0; i < extra.length; ++i) {
            kvps[i + 5] = extra[i];
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(makeObject(kvps)))
        ));
    }

    function makeMetadata(OpenSeaMetadata memory metadata) internal pure returns (string memory output) {
        return makeMetadataWithExtraKvps(metadata, new ObjectKeyValuePair[](0));
    }

    function makeERC1155Metadata(OpenSeaMetadata memory metadata, string memory symbol) internal pure returns (string memory output) {
        ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](1);
        kvps[0] = ObjectKeyValuePair("symbol", quote(symbol));
        return makeMetadataWithExtraKvps(metadata, kvps);
    }
}