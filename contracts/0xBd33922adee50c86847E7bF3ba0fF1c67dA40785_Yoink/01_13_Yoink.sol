// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Base64 } from "./libraries/Base64.sol";

/// @title Yoink
/// @notice Creates modifiable NFTs for any wallet address - this contract is not
/// audited, so use at your own risk
/// @author Nathan Thomas
contract Yoink is Ownable, ERC721URIStorage {
  using Strings for uint256;

  uint256 public newTokenID = 0;
  uint256 public mintingFee = 0;

  mapping(address => bool) public exemptAddresses;

  // https://docs.opensea.io/docs/metadata-standards
  struct Attribute {
    string trait_type;
    string value;
  }
  struct TokenMetadata {
    string description;
    string image;
    string name;
    Attribute[] attributes;
  }

  event AddressExemptionChanged(address indexed changedAddress, bool isExempt);
  event MintedToken(address indexed owner, uint256 indexed tokenID);
  event UpdatedTokenURI(address indexed owner, uint256 indexed tokenID);
  event Withdraw(address indexed to, address indexed project, uint256 amount);

  modifier isMinimumFeeOrExemptAddress() {
    require(
      exemptAddresses[msg.sender] ||
        owner() == msg.sender ||
        msg.value >= mintingFee,
      "Yoink: invalid fee"
    );
    _;
  }

  modifier isTokenOwner(uint256 _tokenID) {
    require(ownerOf(_tokenID) == msg.sender, "Yoink: not token owner");
    _;
  }

  /// @notice Instantiates a new contract for creating custom NFTs
  /// @param _name The name for the NFT collection
  /// @param _symbol The symbol to be used for the NFT collection
  /// @param _mintingFee The fee non-exempt addresses should pay to mint a custom NFT
  /// @param _firstTokenMetadataURI The first token's metadata URI to be saved in state
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _mintingFee,
    string memory _firstTokenMetadataURI,
    address[] memory _exemptAddresses
  ) ERC721(_name, _symbol) {
    toggleExemptAddresses(_exemptAddresses);
    updateMintingFee(_mintingFee);
    mintNFT(_firstTokenMetadataURI);
  }

  /// @notice Toggles the boolean value of addresses to be exempt from minting fee
  /// @param _addresses The addresses that will have their exemption toggled
  /// @dev This function can toggle true -> false and false -> true for various
  /// addresses in the same array within the same transaction
  function toggleExemptAddresses(address[] memory _addresses) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      exemptAddresses[_addresses[i]] = !exemptAddresses[_addresses[i]];

      emit AddressExemptionChanged(
        _addresses[i],
        exemptAddresses[_addresses[i]]
      );
    }
  }

  /// @notice Mints a new custom NFT with a dynamic metadata URL
  /// @param _newTokenMetadataURI The URI to be assigned to the new token
  /// @dev The token metadata URL should load in JSON in the following schema:
  /// https://docs.opensea.io/docs/metadata-standards
  function mintNFT(string memory _newTokenMetadataURI)
    public
    payable
    isMinimumFeeOrExemptAddress
  {
    newTokenID += 1;

    _safeMint(msg.sender, newTokenID);
    emit MintedToken(msg.sender, newTokenID);

    updateTokenURI(newTokenID, _newTokenMetadataURI);
  }

  /// @notice Mins a new custom NFT with static token metadata
  /// @param _newTokenMetadata The static metadata object for the token
  /// @dev The token metadata schema should follow these instructions:
  /// https://docs.opensea.io/docs/metadata-standards
  function mintNFT(TokenMetadata memory _newTokenMetadata)
    public
    payable
    isMinimumFeeOrExemptAddress
  {
    newTokenID += 1;

    _safeMint(msg.sender, newTokenID);
    emit MintedToken(msg.sender, newTokenID);

    updateTokenURI(newTokenID, _newTokenMetadata);
  }

  /// @notice Allows the owner of any NFT to update the URL for that token's URI
  /// @param _tokenID The token ID that will have its URI updated
  /// @param _newTokenMetadataURI The metadata URI to update for the token ID
  function updateTokenURI(uint256 _tokenID, string memory _newTokenMetadataURI)
    public
    isTokenOwner(_tokenID)
  {
    _setTokenURI(_tokenID, _newTokenMetadataURI);
    emit UpdatedTokenURI(msg.sender, _tokenID);
  }

  /// @notice Allows the owner of any token to assign a static metadata object
  /// @param _tokenID The token ID that will have its URI updated
  /// @param _newTokenMetadata The metadata object to be parsed into base 64
  /// encoding and stored onchain
  function updateTokenURI(
    uint256 _tokenID,
    TokenMetadata memory _newTokenMetadata
  ) public isTokenOwner(_tokenID) {
    _setTokenURI(_tokenID, buildTokenURI(_newTokenMetadata));
    emit UpdatedTokenURI(msg.sender, _tokenID);
  }

  /// @notice Builds a static token URI in base 64 encoding to be saved in state
  /// @param _metadata The metadata to be converted to JSON and base 64 encoded
  function buildTokenURI(TokenMetadata memory _metadata)
    public
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string(
                abi.encodePacked(
                  '{"description": "',
                  _metadata.description,
                  '", "image": "',
                  _metadata.image,
                  '", "name": "',
                  _metadata.name,
                  '", "attributes": ',
                  _buildAttributesJSON(_metadata.attributes),
                  "}"
                )
              )
            )
          )
        )
      );
  }

  /// @notice Constructs a static JSON-compliant string for attributes metadata
  /// @param _attributes The attributes array to be converted into a string
  /// @return string The attributes string
  function _buildAttributesJSON(Attribute[] memory _attributes)
    internal
    pure
    returns (string memory)
  {
    string memory attributesJSON = "[";

    if (_attributes.length <= 0) {
      return string(abi.encodePacked(attributesJSON, "]"));
    }

    string memory comma = "";

    for (uint256 i = 0; i < _attributes.length; i++) {
      if (i == 1) {
        comma = ",";
      }

      attributesJSON = string(
        abi.encodePacked(
          attributesJSON,
          comma,
          '{"trait_type": "',
          _attributes[i].trait_type,
          '", "value": "',
          _attributes[i].value,
          '"}'
        )
      );
    }

    return string(abi.encodePacked(attributesJSON, "]"));
  }

  /// @notice Allows the contract owner to update the minting fee value
  /// @param _newMintingFee The new minting fee to be saved in state
  /// @dev The minting fee must be greater-than-or-equal-to 0
  function updateMintingFee(uint256 _newMintingFee) public onlyOwner {
    mintingFee = _newMintingFee;
  }

  /// @notice Allows the owner of the contract to withdraw all ether in it
  function withdrawAllEther() external onlyOwner {
    uint256 addressBalance = address(this).balance;

    require(address(this).balance > 0, "Yoink: no ether");

    (bool success, ) = msg.sender.call{ value: addressBalance }("");
    require(success, "Yoink: withdraw failed");
    emit Withdraw(msg.sender, address(this), addressBalance);
  }
}