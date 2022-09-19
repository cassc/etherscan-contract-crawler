// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/Strings.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

library NftMetadataUtils {
  string constant JSON_DELIMITER = ',';
  string constant VALUE_KEY = 'value';
  string constant TRAIT_TYPE_KEY = 'trait_type';
  string constant MAX_VALUE_KEY = 'max_value';
  string constant DISPLAY_TYPE_KEY = 'display_type';

  string constant BOOST_NUMBER_DISPLAY_TYPE = 'boost_number';
  string constant BOOST_PERCENTAGE_DISPLAY_TYPE = 'boost_percentage';
  string constant NUMBER_DISPLAY_TYPE = 'number';
  string constant DATE_DISPLAY_TYPE = 'date';

  function object(string[] memory content) public pure returns (string memory) {
    return string(abi.encodePacked('{', delimit(content), '}'));
  }

  function array(string[] memory content) public pure returns (string memory) {
    return string(abi.encodePacked('[', delimit(content), ']'));
  }

  function keyValue(string memory key, string memory value)
    public
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('"', key, '":', value));
  }

  function stringWrap(string memory value) public pure returns (string memory) {
    return string(abi.encodePacked('"', value, '"'));
  }

  function delimit(string[] memory values) public pure returns (string memory) {
    bytes memory delimitedValues = '';
    for (uint256 i = 0; i < values.length; ++i) {
      delimitedValues = abi.encodePacked(
        delimitedValues,
        i == 0 ? '' : JSON_DELIMITER,
        values[i]
      );
    }
    return string(delimitedValues);
  }

  function getBaseAttributeObject(
    string memory traitType,
    string memory value,
    string memory extra
  ) public pure returns (string memory) {
    string[] memory components = new string[](3);
    components[0] = keyValue(VALUE_KEY, value);
    components[1] = keyValue(TRAIT_TYPE_KEY, stringWrap(traitType));
    components[2] = extra;

    return object(components);
  }

  function getAttributeObject(string memory traitType, string memory value)
    public
    pure
    returns (string memory)
  {
    return getBaseAttributeObject(traitType, value, '');
  }

  function getAttributeObjectWithMaxValue(
    string memory traitType,
    string memory value,
    string memory maxValue
  ) public pure returns (string memory) {
    return
      getBaseAttributeObject(
        traitType,
        value,
        keyValue(MAX_VALUE_KEY, maxValue)
      );
  }

  function getAttributeObjectWithDisplayType(
    string memory traitType,
    string memory value,
    string memory displayType
  ) public pure returns (string memory) {
    return
      getBaseAttributeObject(
        traitType,
        value,
        keyValue(DISPLAY_TYPE_KEY, displayType)
      );
  }

  function getAttributeObjectWithDisplayTypeAndMaxValue(
    string memory traitType,
    string memory value,
    string memory displayType,
    string memory maxValue
  ) public pure returns (string memory) {
    string[] memory components = new string[](2);
    components[0] = keyValue(DISPLAY_TYPE_KEY, stringWrap(displayType));
    components[1] = keyValue(MAX_VALUE_KEY, maxValue);
    return getBaseAttributeObject(traitType, value, delimit(components));
  }
}