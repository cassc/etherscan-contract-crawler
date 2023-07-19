// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.20;

interface IDataCompiler {
  function BEGIN_JSON() external view returns (string memory);
  function END_JSON() external view returns (string memory);

  function HTML_HEAD_START() external view returns (string memory);
  function HTML_HEAD_END() external view returns (string memory);
  function HTML_FOOT() external view returns (string memory);

  function BEGIN_SCRIPT() external view returns (string memory);
  function END_SCRIPT() external view returns (string memory);

  function BEGIN_SCRIPT_DATA_COMPRESSED() external view returns (string memory);
  function END_SCRIPT_DATA_COMPRESSED() external view returns (string memory);
  function END_SCRIPT_JS_DATA_COMPRESSED() external view returns (string memory);
  function END_SCRIPT_SVG_DATA_COMPRESSED() external view returns (string memory);

  function BEGIN_METADATA_VAR(string memory name, bool omitQuotes) external pure returns (string memory);
  function END_METADATA_VAR(bool omitQuotes, bool last) external pure returns (string memory);

  function SCRIPT_VAR( string memory name, string memory value, bool omitQuotes) external pure returns (string memory);

  function encodeURI(string memory str) external pure returns (string memory);

  function compileDataChunks(address[] memory chunks) external view returns (string memory);
  function compileBytesChunks(address[] memory chunks) external view returns (bytes memory);

  function uint2str(uint256 _i) external pure returns (string memory _uintAsString);
  function toHex32String (bytes32) external pure returns (string memory);
  function toHex16String (bytes16) external pure returns (string memory);
}