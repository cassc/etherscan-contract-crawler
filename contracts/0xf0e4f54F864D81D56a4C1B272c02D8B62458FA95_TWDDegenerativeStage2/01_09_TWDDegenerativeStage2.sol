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
import "./utils/Terms.sol";
import "./utils/Uri.sol";

contract TWDDegenerativeStage2 is ERC721A, IERC2981, Ownable, Terms, Uri {
  string constant TOKEN_SYMBOL = "TWD-DEGENERATIVE-STAGE-2";
  string constant TOKEN_NAME = "TWD Degenerative Stage 2";
  uint256 constant ROYALTY_PCT = 10;

  uint256 private maxSupply;

  string public provenanceHash;
  address public beneficiary;
  address public royalties;

  struct MsgConfig {
    string MAX_SUPPLY;
    string BENEFICIARY;
  }

  struct MintEntity {
    address to;
    uint256 quantity;
  }

  MsgConfig private msgConfig;

  constructor(
    uint256 _maxSupply,
    address _royalties,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721A(TOKEN_NAME, TOKEN_SYMBOL) {
    maxSupply = _maxSupply;
    royalties = _royalties;
    beneficiary = royalties;
    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;
    termsURI = "ipfs://Qmbv7aLanDrHKgpZHjcuEaVQB5Em6qPGUJK3ydQdtzzuro";

    msgConfig = MsgConfig(
      "Max supply will be exceeded",
      "Beneficiary needs to be set to perform this function"
    );
  }

  function setProvenanceHash(string calldata hash) public onlyOwner {
    provenanceHash = hash;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }

  /**
   * Gets the Base URI of the token API
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
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
   * Return total amount from an array of mint entities
   */
  function _totalAmount(MintEntity[] memory entities)
    private
    pure
    returns (uint256)
  {
    uint256 totalAmount = 0;

    for (uint256 i = 0; i < entities.length; i++) {
      totalAmount += entities[i].quantity;
    }

    return totalAmount;
  }

  /**
   * Bulk mint to address list with quantity
   */
  function _bulkMintQuantity(MintEntity[] memory entities) private {
    uint256 amount = _totalAmount(entities);
    require(totalSupply() + amount <= maxSupply, msgConfig.MAX_SUPPLY);

    for (uint256 i = 0; i < entities.length; i++) {
      _internalMint(entities[i].to, entities[i].quantity);
    }
  }

  /**
   * Awesome Drop multiple addresses with number to mint for each
   */
  function airDrop(MintEntity[] memory entities) public onlyOwner {
    _bulkMintQuantity(entities);
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