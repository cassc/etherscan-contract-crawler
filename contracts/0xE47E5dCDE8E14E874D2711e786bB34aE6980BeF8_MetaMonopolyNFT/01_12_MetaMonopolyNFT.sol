// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract MetaMonopolyNFT is
  AccessControl,
  ERC721
{
  // 32 bytes hash of the minter role
  bytes32 public constant MINTER_ROLE = bytes32("MINTER");
  // increasing counter for the tokens that represent token id
  uint256 public id = 1;

  // base uri of the NFT.
  string public baseUri;

  // extension of the file pointed to by URI.
  string public uriExtension;

  // event emitted when uri is set.
  event UriSet(string baseUri, string uriExtension);

  /**
   * @dev { constructor } of the contract that sets name and symbol of NFT contract.
   * Also assigns { ADMIN } and { MINTER } role to contract deployer.
   */
  constructor() ERC721(
    "Meta Monopoly NFT",
    "MMNFT"
  ) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControl, ERC721)
    returns (bool)
  {
    return
      AccessControl.supportsInterface(interfaceId)
      || ERC721.supportsInterface(interfaceId);
  }

  /**
   * @dev Allows { Admin } to set URI for the contract.
   * Only contract admin can call this function.
   */
  function setURI(
    string calldata _baseUri,
    string calldata _uriExtension
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    baseUri = _baseUri;
    uriExtension = _uriExtension;

    emit UriSet(_baseUri, _uriExtension);
  }

  /**
   * @dev { mint } function allows owner to mint NFTs to { recipients }.
   * Only contract owner can call this function.
   */
  function mint(
    address[] calldata recipients
  )
    external
    onlyRole(MINTER_ROLE)
  {
    for (uint256 i = 0; i < recipients.length; i++)
      _mint(
        recipients[i],
        id++
      );
  }

  /**
   * @dev Public facing function that returns URL for metadata of
   * NFT token for which the id is provided as parameter {tokenId}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    return
      string(
        abi.encodePacked(
          baseUri,
          Strings.toString(tokenId),
          uriExtension
        )
      );
  }
}