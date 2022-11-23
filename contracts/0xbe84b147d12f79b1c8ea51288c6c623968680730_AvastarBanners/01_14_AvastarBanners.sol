// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './IMetadataRenderer.sol';

interface IAvastarsFactory is IERC721 {
  enum Wave {
    PRIME,
    REPLICANT
  }

  function getAvastarWaveByTokenId(uint256 _tokenId) external view returns (Wave wave);
}
/**
  * @title Avastar Banner NFTs
  */
contract AvastarBanners is ERC721, IERC2981, Ownable {
  IAvastarsFactory public avastars;
  IMetadataRenderer public metadataRenderer;
  mapping (uint256 => IMetadataRenderer.Metadata) public tokenMetadataById;
  address payable public royaltyBenefactor;
  uint256 public royaltyBps; // static denominator of 10000
  uint256 public secretBannerCount;

  constructor(IAvastarsFactory _avastars, IMetadataRenderer _metadataRenderer) ERC721('Avastar Banners', 'AVB')
  {
    avastars = _avastars;
    metadataRenderer = _metadataRenderer;
    royaltyBenefactor = payable(msg.sender);
    royaltyBps = 250; // default of 2.5%
    secretBannerCount = 0;
  }

  modifier onlyAvastarType(IMetadataRenderer.BannerType bannerType, uint256 avastarId) {
    require(getAvastarType(avastarId) == bannerType, 'Wrong Avastar');
    _;
  }

  modifier onlyClaimable( uint256 avastarId ) {
    require(checkClaimed(avastarId) == false); // must be unclaimed
    require(avastars.ownerOf(avastarId) == msg.sender); // must be the owner
    _;
  }

  /**
   * Return the BannerType for a given avastar ID
   * @param avastarId the avastar Id
   * @return bannerType the bannerType for that avastar (if any)
   * @dev see {IMetadataRenderer-BannerType}.
   */
  function getAvastarType(uint256 avastarId) internal view returns ( IMetadataRenderer.BannerType bannerType) {
    IAvastarsFactory.Wave wave = avastars.getAvastarWaveByTokenId(avastarId);

    if (wave == IAvastarsFactory.Wave.PRIME) {
      if (avastarId < 100) {
        return IMetadataRenderer.BannerType.FOUNDER;
      } else if (avastarId < 200) {
        return IMetadataRenderer.BannerType.EXCLUSIVE;
      }

      return IMetadataRenderer.BannerType.PRIME;
    } else if (wave == IAvastarsFactory.Wave.REPLICANT) {
      return IMetadataRenderer.BannerType.REPLICANT;
    }

    return IMetadataRenderer.BannerType.INVALID;
  }

  /**
   * Set the contract used to render the on-chain metadata
   * @param _metadataRenderer the new IMetadataRendere to use
   */
  function setMetadataRenderer(IMetadataRenderer _metadataRenderer) public onlyOwner {
    metadataRenderer = _metadataRenderer;
  }

  /**
   * Set the colleciton wide royalty information
   * @param _royaltyBenefactor the wallet that will receive future royalties
   * @param _royaltyBps the basis points for the royalty (denominmator is 10000)
   */
  function setRoyaltyInfo(address payable _royaltyBenefactor, uint256 _royaltyBps) public onlyOwner {
    royaltyBenefactor = _royaltyBenefactor;
    royaltyBps = _royaltyBps;
  }

  /**
   * Mint a founders banner to the current owner of the founder avastar
   * @param avastarId which avastarId the banner is associated with
   * @dev only the owner of this avastar can invoke this
   */
  function mintFounders(uint256 avastarId) onlyClaimable(avastarId) onlyAvastarType(IMetadataRenderer.BannerType.FOUNDER, avastarId) public {
    tokenMetadataById[avastarId] = IMetadataRenderer.Metadata(
      IMetadataRenderer.BannerType.FOUNDER,
      IMetadataRenderer.BackgroundType.INVALID,
      IMetadataRenderer.AvastarImageType.INVALID,
      uint16(avastarId),
      uint16(avastarId)
    );
    _mint(msg.sender, avastarId);
  }

  /**
   * Mint an exclusive banner to the current owner of the exclusive avastar
   * @param avastarId which avastarId the banner is associated with
   * @dev only the owner of this avastar can invoke this
   */
  function mintExclusive(uint256 avastarId, IMetadataRenderer.AvastarImageType avastarImageChoice) onlyClaimable(avastarId) onlyAvastarType(IMetadataRenderer.BannerType.EXCLUSIVE, avastarId) public {
    tokenMetadataById[avastarId] = IMetadataRenderer.Metadata(
      IMetadataRenderer.BannerType.EXCLUSIVE,
      IMetadataRenderer.BackgroundType.INVALID,
      avastarImageChoice,
      uint16(avastarId),
      uint16(avastarId)
    );
    _mint(msg.sender, avastarId);
  }

  /**
   * Mint a prime banner to the current owner of the prime
   * @param avastarId which avastarId the banner is associated with
   * @param bgChoice which choice of background color the owner has made
   * @dev only the owner of this avastar can invoke this
   */
  function mintPrime(uint256 avastarId, IMetadataRenderer.BackgroundType bgChoice) onlyClaimable(avastarId) onlyAvastarType(IMetadataRenderer.BannerType.PRIME, avastarId) public {
    require(uint(bgChoice) >= uint(IMetadataRenderer.BackgroundType.P1) && uint(bgChoice) <= uint(IMetadataRenderer.BackgroundType.P4), 'Not an Prime Background');
    tokenMetadataById[avastarId] = IMetadataRenderer.Metadata(
      IMetadataRenderer.BannerType.PRIME,
      bgChoice,
      IMetadataRenderer.AvastarImageType.INVALID,
      uint16(avastarId),
      uint16(avastarId)
    );
    _mint(msg.sender, avastarId);
  }

  /**
   * Mint a replicant banner to the current owner of the replicant
   * @param avastarId which avastarId the banner is associated with
   * @param bgChoice which choice of background color the owner has made
   * @dev only the owner of this avastar can invoke this
   */
  function mintReplicant(uint256 avastarId, IMetadataRenderer.BackgroundType bgChoice) onlyClaimable(avastarId) onlyAvastarType(IMetadataRenderer.BannerType.REPLICANT, avastarId) public {
    require(uint(bgChoice) >= uint(IMetadataRenderer.BackgroundType.R1) && uint(bgChoice) <= uint(IMetadataRenderer.BackgroundType.R4), 'Not an Replicant Background');
    tokenMetadataById[avastarId] = IMetadataRenderer.Metadata(
      IMetadataRenderer.BannerType.REPLICANT,
      bgChoice,
      IMetadataRenderer.AvastarImageType.INVALID,
      uint16(avastarId),
      uint16(avastarId)
    );
    _mint(msg.sender, avastarId);
  }

  /**
   * Mint the secret banner
   * @param to the lucky first owner of the secret banner
   * @dev only the owner of the banner contract can invoke this
   */
  function mintSecret(address to) onlyOwner public {
    uint secretTokenId = 50400 + secretBannerCount++;
    tokenMetadataById[secretTokenId] = IMetadataRenderer.Metadata(
      IMetadataRenderer.BannerType.SECRET,
      IMetadataRenderer.BackgroundType.INVALID,
      IMetadataRenderer.AvastarImageType.INVALID,
      uint16(secretTokenId),
      uint16(0)
    );
    _safeMint(to, secretTokenId);
  }

  /**
   * Check to see if the given avastar ID has claimed it's banner
   * @param avastarId the avastar ID to check
   * @return claimed true if the avastar has already claimed a banner, false otherwise
   */
  function checkClaimed(uint256 avastarId) public view returns (bool claimed) {
    claimed = tokenMetadataById[avastarId].bannerType != IMetadataRenderer.BannerType.INVALID;
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireMinted(tokenId);
    return metadataRenderer.renderTokenURI(tokenMetadataById[tokenId]);
  }

  /**
    * Access the on-chain metadata IF the metadata renderer supports it
    * @param tokenId the tokenId of the token whose metadata is returned
    * @return metadata JSON-encoded metadata compatible with standards
    */
  function getMetadata(uint256 tokenId) public view returns (string memory) {
    _requireMinted(tokenId);
    return metadataRenderer.renderMetadata(tokenMetadataById[tokenId]);
  }

  /**
     * @dev See {IERC2981-royaltyInfo}
     */
  function royaltyInfo(uint256, uint256 salePrice) public view returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyBenefactor;
    royaltyAmount = (salePrice * royaltyBps) / 10000;
  }

  /**
    * indicate support for ERC2981
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
      return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }
}