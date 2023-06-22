// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IToken721UriResolver.sol';
import './ITokenSupplyDetails.sol';

interface INFTRewardDataSourceDelegate is ITokenSupplyDetails {
  function transfer(address _to, uint256 _id) external;

  function mint(address) external returns (uint256);

  function burn(address, uint256) external;

  function isOwner(address, uint256) external view returns (bool);

  function contractURI() external view returns (string memory);

  function setContractUri(string calldata _contractMetadataUri) external;

  function setTokenUri(string calldata _uri) external;

  function setTokenUriResolver(IToken721UriResolver _tokenUriResolverAddress) external;

  function setTransferrable(bool _transferrable) external;
}