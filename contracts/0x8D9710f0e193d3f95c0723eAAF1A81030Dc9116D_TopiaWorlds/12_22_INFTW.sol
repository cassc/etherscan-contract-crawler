// SPDX-License-Identifier: MIT
//
// ...............   ...............   ...............  .....   ...............  
// :==============.  ===============  :==============:  -====  .==============-  
// :==============.  ===============  :==============:  -====  .==============-  
// :==============.  ===============  :==============:  -====  .==============-  
// :==============.  ===============  :==============:  -====  .==============-  
// .::::-====-::::.  ===============  :====-:::::::::.  -====  .====-::::-====-  
//      :====.       ===============  :====:            -====  .====:    .====-  
//      :====.       ===============  :====:            -====  .====:    .====-  
//
// Learn more at https://topia.gg or Twitter @topiagg

pragma solidity 0.8.18;

interface INFTW {
  function getGeography(uint _tokenId) external view returns (uint24[5] memory);
  function getResources(uint _tokenId) external view returns (uint16[9] memory);
  function getDensities(uint _tokenId) external view returns (string[3] memory);
  function getBiomes(uint _tokenId) external view returns (string[] memory);
  function getFeatures(uint _tokenId) external view returns (string[] memory);
}