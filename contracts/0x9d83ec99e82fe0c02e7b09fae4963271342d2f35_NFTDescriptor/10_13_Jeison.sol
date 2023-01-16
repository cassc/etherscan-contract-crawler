// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Strings} from './Strings.sol';
import {Base64} from './Base64.sol';

library IntStrings {
    function toString(int256 value) internal pure returns (string memory) {
        if (value >= 0) return Strings.toString(uint256(value));
        return string(abi.encodePacked('-', Strings.toString(uint256(-value))));
    }
}

library Jeison {
    using Strings for uint256;
    using Strings for address;
    using IntStrings for int256;

    struct DataPoint {
        string name;
        string value;
        bool isNumeric;
    }

    struct JsonObject {
        string[] varNames;
        string[] varValues;
        bool[] isNumeric;
        uint256 i;
    }

    function dataPoint(string memory varName, bool varValue) internal pure returns (DataPoint memory _datapoint) {
        string memory boolStr = varValue ? 'true' : 'false';
        _datapoint = DataPoint(varName, boolStr, true);
    }

    function dataPoint(string memory varName, string memory varValue)
        internal
        pure
        returns (DataPoint memory _datapoint)
    {
        _datapoint = DataPoint(varName, varValue, false);
    }

    function dataPoint(string memory varName, address varValue) internal pure returns (DataPoint memory _datapoint) {
        _datapoint = DataPoint(varName, varValue.toHexString(), false);
    }

    function dataPoint(string memory varName, uint256 varValue) internal pure returns (DataPoint memory _datapoint) {
        _datapoint = DataPoint(varName, varValue.toString(), true);
    }

    function dataPoint(string memory varName, int256 varValue) internal pure returns (DataPoint memory _datapoint) {
        _datapoint = DataPoint(varName, varValue.toString(), true);
    }

    function dataPoint(string memory varName, uint256[] memory uintValues)
        internal
        pure
        returns (DataPoint memory _datapoint)
    {
        string memory batchStr = '[';
        for (uint256 _i; _i < uintValues.length; _i++) {
            string memory varStr;
            varStr = uintValues[_i].toString();
            if (_i != 0) varStr = string(abi.encodePacked(', ', varStr));
            batchStr = string(abi.encodePacked(batchStr, varStr));
        }

        batchStr = string(abi.encodePacked(batchStr, ']'));

        _datapoint = DataPoint(varName, batchStr, true);
    }

    function dataPoint(string memory varName, int256[] memory intValues)
        internal
        pure
        returns (DataPoint memory _datapoint)
    {
        string memory batchStr = '[';
        for (uint256 _i; _i < intValues.length; _i++) {
            string memory varStr;
            varStr = intValues[_i].toString();
            if (_i != 0) varStr = string(abi.encodePacked(', ', varStr));
            batchStr = string(abi.encodePacked(batchStr, varStr));
        }

        batchStr = string(abi.encodePacked(batchStr, ']'));

        _datapoint = DataPoint(varName, batchStr, true);
    }

    function _load(JsonObject memory self, string memory varName, string memory varValue, bool varType)
        internal
        pure
        returns (JsonObject memory)
    {
        uint256 _index = self.i++;
        self.varNames[_index] = varName;
        self.varValues[_index] = varValue;
        self.isNumeric[_index] = varType;
        return self;
    }

    function get(JsonObject memory self) internal pure returns (string memory jsonStr) {
        jsonStr = '{';
        for (uint256 _i; _i < self.i; _i++) {
            string memory varStr;
            varStr = string(
                abi.encodePacked(
                    '"',
                    self.varNames[_i],
                    '" : ',
                    _separator(self.isNumeric[_i]),
                    self.varValues[_i], // "value" / value
                    _separator(self.isNumeric[_i])
                )
            );
            if (_i != 0) {
                // , "var" : "value"
                varStr = string(abi.encodePacked(', ', varStr));
            }
            jsonStr = string(abi.encodePacked(jsonStr, varStr));
        }

        jsonStr = string(abi.encodePacked(jsonStr, '}'));
    }

    function getBase64(JsonObject memory self) internal pure returns (string memory jsonBase64) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(get(self)))));
    }

    function _separator(bool _isNumeric) private pure returns (string memory separator) {
        if (!_isNumeric) return '"';
    }

    function _initialize(uint256 _jsonLength) private pure returns (JsonObject memory json) {
        json.varNames = new string[](_jsonLength);
        json.varValues = new string[](_jsonLength);
        json.isNumeric = new bool[](_jsonLength);
        json.i = 0;
    }

    function create(DataPoint[] memory _datapoints) internal pure returns (JsonObject memory json) {
        json = _initialize(_datapoints.length);
        for (uint256 _i; _i < _datapoints.length; _i++) {
            json = _load(json, _datapoints[_i].name, _datapoints[_i].value, _datapoints[_i].isNumeric);
        }
        return json;
    }

    function arraify(string memory varName, JsonObject[] memory jsons)
        internal
        pure
        returns (DataPoint memory datapoint)
    {
        datapoint.name = varName;
        datapoint.isNumeric = true;

        string memory batchStr = '[';
        for (uint256 _i; _i < jsons.length; _i++) {
            string memory varStr;
            varStr = get(jsons[_i]);
            if (_i != 0) {
                // , "var" : "value"
                varStr = string(abi.encodePacked(', ', varStr));
            }
            batchStr = string(abi.encodePacked(batchStr, varStr));
        }

        datapoint.value = string(abi.encodePacked(batchStr, ']'));
    }
}