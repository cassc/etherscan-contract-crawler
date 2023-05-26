// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/utils/Base64.sol';

import "./Tiny721.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotExceedAllowance();

/**
  @title On-chain generative nihilism.
  @author Tim Clancy

  This contract generates a piece of pseudorandom data upon each token's mint.
  This data is then used to generate 100% on-chain an SVG of timeless
  existential frustration at the passing of time.

  June 11th, 2022.
*/
contract Since is
  Tiny721
{
  using Strings for uint256;

  /// A mapping from each token ID to the pseudorandom hash when it was minted.
  mapping ( uint256 => uint256 ) public mintData;

  /// A counter for how many items a single address has minted.
  mapping ( address => uint256 ) public mintCount;

  /**
    Construct a new instance of this ERC-721 contract.
  */
  constructor (
  ) Tiny721("RektSince", "RS", "", 6026) {
  }

  /**
    Directly return the metadata of the token with the specified `_id` as a
    packed base64-encoded URI.

    @param _id The ID of the token to retrive a metadata URI for.

    @return The metadata of the token with the ID of `_id` as a base64 URI.
  */
  function tokenURI (
    uint256 _id
  ) external view virtual override returns (string memory) {
    if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }

    /*
      Retrieve the random roll and convert it into a year between 4001 BC and AD
      2025. Years are displayed with their appropriate prefix or suffix.
    */
    string memory displayYear;
    uint256 year = mintData[_id];
    if (year < 4001) {
      displayYear = string(abi.encodePacked(
        (year + 1).toString(),
        " BC"
      ));
    } else {
      displayYear = string(abi.encodePacked(
        "AD ",
        (year - 4000).toString()
      ));
    }

    // Encode the SVG into a base64 data URI.
    string memory encodedImage = string(abi.encodePacked(
      "data:image/svg+xml;base64,",
      Base64.encode(
        bytes(
          string(abi.encodePacked(
            "<svg version=\"1.1\" width=\"512\" height=\"512\" ",
            "viewBox=\"0 0 612 612\" stroke-linecap=\"round\" ",
            "xmlns=\"http://www.w3.org/2000/svg\" ",
            "xmlns:xlink=\"http://www.w3.org/1999/xlink\">",
            "<style>",
            ".small { font: 64px sans-serif; text-anchor: middle; }",
            ".large { font: bold 128px sans-serif; text-anchor: middle; }",
            "</style>",
            "<rect width=\"100%\" height=\"100%\" fill=\"black\"/>",
            "<text x=\"50%\" y=\"35%\" fill=\"white\" class=\"small\">",
            "REKT SINCE",
            "</text>",
            "<text x=\"50%\" y=\"60%\" fill=\"white\" class=\"large\">",
            displayYear,
            "</text>",
            "</svg>"
          ))
        )
      )
    ));

    // Return the base64-encoded packed metadata.
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              "{ \"name\": \"",
              "Since ",
              displayYear,
              "\", \"description\": \"\", ",
              "\"image\": \"",
              encodedImage,
              "\"}"
            )
          )
        )
      )
    );
  }

  /**
    This function allows permissioned minters of this contract to mint one or
    more tokens dictated by the `_amount` parameter. Any minted tokens are sent
    to the `_recipient` address.

    Note that tokens are always minted sequentially starting at one. That is,
    the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
    Also note that per our use cases the intended recipient of these minted
    items will always be externally-owned accounts and not other contracts. As a
    result there is no safety check on whether or not the mint destination can
    actually correctly handle an ERC-721 token.

    @param _recipient The recipient of the tokens being minted.
    @param _amount The amount of tokens to mint.
  */
  function mint (
    address _recipient,
    uint256 _amount
  ) public {

    /*
      Limit the number of items that a single caller may mint. Normally I split
      logic like this out of the item itself and host it in a separate shop
      contract for better composability. This is a silly little NFT project so I
      don't feel the need to do that.
    */
    if (mintCount[_msgSender()] + _amount > 10) {
      revert CannotExceedAllowance();
    }
    mintCount[_msgSender()] += _amount;

    // Store a piece of pseudorandom data tied to each item that will be minted.
    uint256 startTokenId = nextId;
    unchecked {
      uint256 updatedIndex = startTokenId;
      for (uint256 i; i < _amount; i++) {
        if (updatedIndex == 1) {
          mintData[updatedIndex] = 1;
        } else {
          mintData[updatedIndex] = (
            mintData[updatedIndex - 1] + 3851
          ) % cap;
        }
        updatedIndex++;
      }
    }

    // Actually mint the items.
    super.mint_Qgo(_recipient, _amount);
  }
}