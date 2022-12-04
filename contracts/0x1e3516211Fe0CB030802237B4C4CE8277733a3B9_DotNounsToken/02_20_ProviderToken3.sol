// SPDX-License-Identifier: MIT

/**
 * This is a part of an effort to create a decentralized autonomous marketplace for digital assets,
 * which allows artists and developers to sell their arts and generative arts.
 *
 * Please see "https://fullyonchain.xyz/" for details. 
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

// import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../packages/ERC721P2P/ERC721P2P.sol";
import { Base64 } from 'base64-sol/base64.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "assetprovider.sol/IAssetProvider.sol";

/**
 * ProviderToken is an abstract implentation of ERC721, which is built on top of an asset provider.
 * The specified asset provider is responsible in providing images for NFTs in SVG format,
 * which turns them into fully on-chain NFTs.
 *
 * When implementing the mint method, and it should call processPayout method of the asset provider like this:
 *
 *   provider.processPayout{value:msg.value}(assetId)
 *
 */
abstract contract ProviderToken3 is ERC721P2P {
  using Strings for uint256;
  using Strings for uint16;

  uint public nextTokenId;

  // To be specified by the concrete contract
  string public description; 
  uint public mintPrice; 
  uint internal _mintLimit; // with a virtual getter

  IAssetProvider public immutable assetProvider;

  constructor(
    IAssetProvider _assetProvider,
    string memory _title,
    string memory _shortTitle
  ) ERC721(_title, _shortTitle)  {
    assetProvider = _assetProvider;
  }

  function setDescription(string memory _description) external onlyOwner {
      description = _description;
  }

  function setMintPrice(uint256 _price) external onlyOwner {
    mintPrice = _price;
  }

  function setMintLimit(uint256 _limit) external onlyOwner {
    _mintLimit = _limit;
  }

  function mintLimit() public view virtual returns(uint256) {
    return _mintLimit;
  }

  string constant SVGHeader = '<svg viewBox="0 0 1024 1024'
      '"  xmlns="http://www.w3.org/2000/svg">\n'
      '<defs>\n';

  /*
   * A function of IAssetStoreToken interface.
   * It generates SVG with the specified style, using the given "SVG Part".
   */
  function generateSVG(uint256 _assetId) internal view returns (string memory) {
    // Constants of non-value type not yet implemented by Solidity
    (string memory svgPart, string memory tag) = assetProvider.generateSVGPart(_assetId);
    return string(abi.encodePacked(
      SVGHeader, 
      svgPart,
      '</defs>\n'
      '<use href="#', tag, '" />\n'
      '</svg>\n'));
  }

  /**
    * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), 'ProviderToken.tokenURI: nonexistent token');
    bytes memory image = bytes(generateSVG(_tokenId));

    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"', tokenName(_tokenId), 
                '","description":"', description, 
                '","attributes":[', generateTraits(_tokenId), 
                '],"image":"data:image/svg+xml;base64,', 
                Base64.encode(image), 
              '"}')
          )
        )
      )
    );
  }

  function tokenName(uint256 _tokenId) internal view virtual returns(string memory) {
    return _tokenId.toString();
  }

  /**
   * For non-free minting,
   * 1. Override this method
   * 2. Check for the required payment, by calling mintPriceFor()
   * 3. Call the processPayout method of the asset provider with appropriate value
   */
  function mint() public virtual payable returns(uint256 tokenId) {
    require(nextTokenId < mintLimit(), "Sold out");
    tokenId = nextTokenId++; 
    _safeMint(msg.sender, tokenId);
  }

  /**
   * The concreate contract may override to offer custom pricing,
   * such as token-gated discount. 
   */
  function mintPriceFor(address) public virtual view returns(uint256) {
    return mintPrice;
  }

  function totalSupply() public view returns (uint256) {
    return nextTokenId;
  }

  function generateTraits(uint256 _tokenId) internal view returns (bytes memory traits) {
    traits = bytes(assetProvider.generateTraits(_tokenId));
  }

  function debugTokenURI(uint256 _tokenId) public view returns (string memory uri, uint256 gas) {
    gas = gasleft();
    uri = tokenURI(_tokenId);
    gas -= gasleft();
  }
}