// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IAgency {
  function safeGetAgencyId(string memory agencyId_)
    external
    view
    returns (string memory);

  function safeGetAgencyVeriSign(string memory agencyId_)
    external
    view
    returns (string memory);

  function setTokenIdAgencyInfo(uint256 tokenId_, string memory agencyId_)
    external;

  function _metadataTypeStatusList(string memory metadataType_)
    external
    view
    returns (bool);
}