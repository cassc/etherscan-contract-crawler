// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import { Base64 } from "base64-sol/base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { Ownable } from "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

/**
 * @title PoolTogether Inc. Pooly Pooly NFT
 * @notice A airdropped NFT to Pooly holders; a thank you for supporting.
 */
contract PoolyClub is ERC721, Ownable {
  using Strings for uint256;
  /// @notice Total supply of NFTs
  uint256 public totalSupply;

  /// @notice Track tokenId tiers
  mapping(uint256 => uint8) private tiers;

  string[3] private tierImageIpfsUris;
  string[3] private tierAnimationIpfsUris;

  /**
   * @notice Initializes the NFT contract
   * @param _name NFT collection name
   * @param _symbol NFT collection symbol
   * @param _owner Owner of this contract
   * @param _revealImageIpfsUri Owner of this contract
   */
  constructor(
    string memory _name,
    string memory _symbol,
    address _owner,
    string memory _revealImageIpfsUri,
    string memory _revealAnimationIpfsUri
  ) ERC721(_name, _symbol) Ownable(_owner) {
    require(_owner != address(0), "PoolyPool/owner-not-zero-address");
    tierImageIpfsUris[0] = _revealImageIpfsUri;
    tierImageIpfsUris[1] = _revealImageIpfsUri;
    tierImageIpfsUris[2] = _revealImageIpfsUri;
    tierAnimationIpfsUris[0] = _revealAnimationIpfsUri;
    tierAnimationIpfsUris[1] = _revealAnimationIpfsUri;
    tierAnimationIpfsUris[2] = _revealAnimationIpfsUri;
  }

  /* ================================================================================ */
  /* External Functions                                                               */
  /* ================================================================================ */

  function getTokenIdTier(uint256 tokenId) public view returns (uint8) {
    return tiers[tokenId];
  }

  function mint(address user) external payable onlyOwner {
    _mint(user);
  }

  function batchMint(address[] calldata users) external onlyOwner {
    for (uint32 i; i < users.length; i++) {
      _mint(users[i]);
    }
  }

  function setTokenIdTier(uint256 tokenId, uint8 tier) external onlyOwner {
    _setTokenIdTier(tokenId, tier);
  }

  function batchSetTokenIdsTier(uint256[] calldata tokenIds, uint8 tier) external onlyOwner {
    for (uint256 index = 0; index < tokenIds.length; index++) {
      _setTokenIdTier(tokenIds[index], tier);
    }
  }

  function setTierImageIpfsUri(uint8 _tier, string calldata _ipfsUri) external onlyOwner {
    _setTierImageIpfsUri(_tier, _ipfsUri);
  }

  function setTierAnimationIpfsUri(uint8 _tier, string calldata _ipfsUri) external onlyOwner {
    _setTierAnimationIpfsUri(_tier, _ipfsUri);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return _constructTokenURI(tokenId);
  }

  /* ================================================================================ */
  /* Internal Functions                                                               */
  /* ================================================================================ */

  function _getTokenIdTier(uint256 _tokenId) internal view returns (uint8) {
    return tiers[_tokenId];
  }

  function _getTierRarityValue(uint8 _tier) internal view returns (string memory) {
    if (_tier == 2) return "Ultra Rare";
    if (_tier == 1) return "Rare";
    return "Common";
  }

  function _getTierUpdateStatus(uint8 _tier) internal view returns (string memory) {
    if (_tier == 1 || _tier == 2) return "Yes";
    return "No";
  }

  function _getTierDescription(uint8 _tier) internal view returns (string memory) {
    return
      "Pooly's is a special hangout for the OG Pooly supporters. Animation by @chuckbergeron. 3d Pooly by @d_v_dsm. Original Pooly concept by @irrelephantoops.";
  }

  function _getTierVariantTitles(uint8 _tier) internal view returns (string memory) {
    if (_tier == 2) return "Keep Pooly Flying";
    if (_tier == 1) return "Swimsuits Not Lawsuits";
    return "No Loss";
  }

  function _getTierNames(uint8 _tier) internal view returns (string memory) {
    if (_tier == 2) return "Stars";
    if (_tier == 1) return "Nighttime";
    return "Daytime";
  }

  function _getTierImageVariantURI(uint8 _tier) internal view returns (string memory) {
    if (_tier == 2) return tierImageIpfsUris[2];
    if (_tier == 1) return tierImageIpfsUris[1];
    return tierImageIpfsUris[0];
  }

  function _getTierAnimationVariantURI(uint8 _tier) internal view returns (string memory) {
    if (_tier == 2) return tierAnimationIpfsUris[2];
    if (_tier == 1) return tierAnimationIpfsUris[1];
    return tierAnimationIpfsUris[0];
  }

  function _setTokenIdTier(uint256 _tokenId, uint8 _tier) internal {
    require(_tier == 1 || _tier == 2, "PoolyAppreciationNFT:invalid-tier");
    tiers[_tokenId] = _tier;
  }

  function _setTierImageIpfsUri(uint8 _tier, string calldata _ipfsUri) internal {
    require(_tier == 0 || _tier == 1 || _tier == 2, "PoolyAppreciationNFT:invalid-tier");
    tierImageIpfsUris[_tier] = _ipfsUri;
  }

  function _setTierAnimationIpfsUri(uint8 _tier, string calldata _ipfsUri) internal {
    require(_tier == 0 || _tier == 1 || _tier == 2, "PoolyAppreciationNFT:invalid-tier");
    tierAnimationIpfsUris[_tier] = _ipfsUri;
  }

  function _mint(address _user) internal {
    require(balanceOf(_user) == 0, "PoolyClub:existing-owner");
    // tokenId starts at 1
    _safeMint(_user, ++totalSupply);
  }

  function _constructTokenURI(uint256 _tokenId) internal view returns (string memory) {
    uint8 tier_ = _getTokenIdTier(_tokenId);
    string memory title = _getTierVariantTitles(tier_);
    string memory tierName = _getTierNames(tier_);
    string memory description = _getTierDescription(tier_);
    string memory rarity = _getTierRarityValue(tier_);
    string memory upgraded = _getTierUpdateStatus(tier_);
    string memory image = _getTierImageVariantURI(tier_);
    string memory animation = _getTierAnimationVariantURI(tier_);

    string memory name = string.concat("Club Pooly's (", tierName,") #", _tokenId.toString());

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string.concat(
                '{"name":', '"',  name, '",',
                '"description":', '"', description, '",',
                '"attributes": [',
                '{"trait_type": "Rarity",',
                '"value": "',
                rarity,
                '"},',
                '{"trait_type": "Title",',
                '"value": "',
                title,
                '"}',
                "],",
                '"image": "',
                image,
                '",',
                '"animation_url": "',
                animation,
                '"}'
              )
            )
          )
        )
      );
  }
}