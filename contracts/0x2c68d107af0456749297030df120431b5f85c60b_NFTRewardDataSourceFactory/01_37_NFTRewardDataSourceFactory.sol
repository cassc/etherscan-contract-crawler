// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../interfaces/IJBDirectory.sol';

import '../../NFTRewards/NFTRewardDataSourceDelegate.sol';
import '../../NFTRewards/OpenTieredTokenUriResolver.sol';
import '../../NFTRewards/OpenTieredPriceResolver.sol';
import '../../NFTRewards/TieredTokenUriResolver.sol';
import '../../NFTRewards/TieredPriceResolver.sol';

import '../../interfaces/IPriceResolver.sol';
import '../../interfaces/IToken721UriResolver.sol';

/**
 * @notice Deploys instances of NFTRewardDataSourceDelegate and supporting contracts.
 */
library NFTRewardDataSourceFactory {
  function createOpenTieredTokenUriResolver(string memory _baseUri) public returns (address) {
    OpenTieredTokenUriResolver c = new OpenTieredTokenUriResolver(_baseUri);

    return address(c);
  }

  function createOpenTieredPriceResolver(address _contributionToken, OpenRewardTier[] memory _tiers)
    public
    returns (address)
  {
    OpenTieredPriceResolver c = new OpenTieredPriceResolver(_contributionToken, _tiers);

    return address(c);
  }

  function createTieredTokenUriResolver(string memory _baseUri, uint256[] memory _idRange)
    public
    returns (address)
  {
    TieredTokenUriResolver c = new TieredTokenUriResolver(_baseUri, _idRange);

    return address(c);
  }

  function createTieredPriceResolver(
    address _contributionToken,
    uint256 _mintCap,
    uint256 _userMintCap,
    RewardTier[] memory _tiers
  ) public returns (address) {
    TieredPriceResolver c = new TieredPriceResolver(
      _contributionToken,
      _mintCap,
      _userMintCap,
      _tiers
    );

    return address(c);
  }

  function createNFTRewardDataSource(
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    uint256 _maxSupply,
    JBTokenAmount memory _minContribution,
    string memory _name,
    string memory _symbol,
    string memory _uri,
    IToken721UriResolver _tokenUriResolverAddress,
    string memory _contractMetadataUri,
    address _admin,
    IPriceResolver _priceResolver
  ) public returns (address) {
    NFTRewardDataSourceDelegate ds = new NFTRewardDataSourceDelegate(
      _projectId,
      _jbxDirectory,
      _maxSupply,
      _minContribution,
      _name,
      _symbol,
      _uri,
      _tokenUriResolverAddress,
      _contractMetadataUri,
      _admin,
      _priceResolver
    );

    return address(ds);
  }
}