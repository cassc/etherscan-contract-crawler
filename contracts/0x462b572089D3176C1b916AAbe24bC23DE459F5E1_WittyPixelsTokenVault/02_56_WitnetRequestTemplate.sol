// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetRequest.sol";
import "../libs/WitnetV2.sol";

abstract contract WitnetRequestTemplate
{
    event WitnetRequestTemplateSettled(WitnetRequest indexed request, bytes32 indexed radHash, string[][] args);

    function class() virtual external view returns (bytes4);
    function getDataSources() virtual external view returns (bytes32[] memory);
    function getDataSourcesCount() virtual external view returns (uint256);    
    function getRadonAggregatorHash() virtual external view returns (bytes32);
    function getRadonTallyHash() virtual external view returns (bytes32);
    function getResultDataMaxSize() virtual external view returns (uint16);
    function getResultDataType() virtual external view returns (WitnetV2.RadonDataTypes);
    function lookupDataSourceByIndex(uint256) virtual external view returns (WitnetV2.DataSource memory);
    function lookupRadonAggregator() virtual external view returns (WitnetV2.RadonReducer memory);
    function lookupRadonTally() virtual external view returns (WitnetV2.RadonReducer memory);
    function parameterized() virtual external view returns (bool);
    function settleArgs(string[][] calldata args) virtual external returns (WitnetRequest);
    function version() virtual external view returns (string memory);
}