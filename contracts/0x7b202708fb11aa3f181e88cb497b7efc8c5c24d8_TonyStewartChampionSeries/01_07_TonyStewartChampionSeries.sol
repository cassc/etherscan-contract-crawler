/*
╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━╮╱╱╱╱╱╱╱╱╭╮
┃╭━╮┃╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━╮┃╱╱╱╱╱╱╱╭╯╰╮
┃┃╱┃┣━┳━━┳━╮╭━━┳━━╮┃┃╱╰╋━━┳╮╭┳━┻╮╭╯
┃┃╱┃┃╭┫╭╮┃╭╮┫╭╮┃┃━┫┃┃╱╭┫╭╮┃╰╯┃┃━┫┃
┃╰━╯┃┃┃╭╮┃┃┃┃╰╯┃┃━┫┃╰━╯┃╰╯┃┃┃┃┃━┫╰╮
╰━━━┻╯╰╯╰┻╯╰┻━╮┣━━╯╰━━━┻━━┻┻┻┻━━┻━╯
╱╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╱╱╰━━╯
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract TonyStewartChampionSeries is ERC721A, IERC2981, Ownable {
  string public PROVENANCE_HASH;

  uint256 constant ROYALTY_PCT = 10;

  string public baseURI;
  string public termsURI;
  string private _contractURI;
  uint256 private maxSupply;

  address public beneficiary;
  address public royalties;

  struct MsgConfig {
    string MAX_SUPPLY;
    string BENEFICIARY;
  }

  MsgConfig private msgConfig;

  constructor(
    string memory name,
    string memory symbol,
    uint256 _maxSupply,
    address _royalties,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721A(name, symbol) {
    maxSupply = _maxSupply;
    royalties = _royalties;
    beneficiary = royalties;
    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;
    termsURI = "ipfs://QmTVp9aDwZYG9mFoxvL2SZ9wJUSNiUjz5haSSsqTtdJX5q";

    msgConfig = MsgConfig(
      "Max supply will be exceeded",
      "Beneficiary needs to be set to perform this function"
    );
  }

  function setProvenanceHash(string calldata hash) public onlyOwner {
    PROVENANCE_HASH = hash;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }

  /**
   * Sets the Base URI for the token API
   */
  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  /**
   * Gets the Base URI of the token API
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * OpenSea contract level metdata standard for displaying on storefront.
   * https://docs.opensea.io/docs/contract-level-metadata
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
  }

  function setTermsURI(string memory uri) public onlyOwner {
    termsURI = uri;
  }

  /**
   * Override start token ID
   */
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /**
   * Mint next available token(s) to addres using ERC721A _safeMint
   */
  function _internalMint(address to, uint256 quantity) private {
    require(totalSupply() + quantity <= maxSupply, msgConfig.MAX_SUPPLY);

    _safeMint(to, quantity);
  }

  /**
   * Owner can mint to specified address
   */
  function ownerMint(address to, uint256 quantity) public onlyOwner {
    _internalMint(to, quantity);
  }

  /**
   * Include withdraw in the event money ends up in the contract
   */
  function withdraw() public onlyOwner {
    require(beneficiary != address(0), msgConfig.BENEFICIARY);
    payable(beneficiary).transfer(address(this).balance);
  }

  /**
   * Supporting ERC721, IER165
   * https://eips.ethereum.org/EIPS/eip-165
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * Setting up royalty standard: IERC2981
   * https://eips.ethereum.org/EIPS/eip-2981
   */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address, uint256 royaltyAmount)
  {
    _tokenId; // silence solc unused parameter warning
    royaltyAmount = (_salePrice / 100) * ROYALTY_PCT;
    return (royalties, royaltyAmount);
  }
}