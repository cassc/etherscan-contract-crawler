// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface ICyberBrokersMetadata {
    struct CyberBrokerLayer {
        string key;
        string attributeName;
        string attributeValue;
    }

    function layerMap(uint256 layerId) external view returns(CyberBrokerLayer memory);
        
    // Mapping of all talents
    struct CyberBrokerTalent {
        string talent;
        string species;
        string class;
        string description;
    }
    function getBrokerName(uint256 _tokenId) external view returns (string memory);
    function getStats(uint256 tokenId) external view returns (uint256 mind, uint256 body, uint256 soul);
    function talentMap(uint256 talentId) external view returns(CyberBrokerTalent memory);
    function brokerDna(uint256 tokenId) external view returns(uint256);
    function getTalent(uint256 tokenId) external view returns (CyberBrokerTalent memory talent);
    function getLayers(uint256 tokenId) external view returns (uint256[] memory);
    function tokenURI(uint256 tokenId) external;
      function renderBroker(
    uint256 _tokenId,
    uint256 _startIndex
  )
    external
    view
    returns (
      string memory,
      uint256
    );
}