// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IDataChunk {
  function data() external view returns (string memory);
}

interface IDataChunkCompiler {
  function BEGIN_JSON() external view returns (string memory);

  function END_JSON() external view returns (string memory);

  function HTML_HEAD() external view returns (string memory);

  function BEGIN_SCRIPT() external view returns (string memory);

  function END_SCRIPT() external view returns (string memory);

  function BEGIN_SCRIPT_DATA() external view returns (string memory);

  function END_SCRIPT_DATA() external view returns (string memory);

  function BEGIN_SCRIPT_DATA_COMPRESSED() external view returns (string memory);

  function END_SCRIPT_DATA_COMPRESSED() external view returns (string memory);

  function SCRIPT_VAR(
    string memory name,
    string memory value,
    bool omitQuotes
  ) external pure returns (string memory);

  function BEGIN_METADATA_VAR(string memory name, bool omitQuotes)
    external
    pure
    returns (string memory);

  function END_METADATA_VAR(bool omitQuotes)
    external
    pure
    returns (string memory);

  function compile2(address chunk1, address chunk2)
    external
    view
    returns (string memory);

  function compile3(
    address chunk1,
    address chunk2,
    address chunk3
  ) external returns (string memory);

  function compile4(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4
  ) external view returns (string memory);

  function compile5(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5
  ) external view returns (string memory);

  function compile6(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6
  ) external view returns (string memory);

  function compile7(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6,
    address chunk7
  ) external view returns (string memory);

  function compile8(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6,
    address chunk7,
    address chunk8
  ) external view returns (string memory);

  function compile9(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6,
    address chunk7,
    address chunk8,
    address chunk9
  ) external view returns (string memory);
}