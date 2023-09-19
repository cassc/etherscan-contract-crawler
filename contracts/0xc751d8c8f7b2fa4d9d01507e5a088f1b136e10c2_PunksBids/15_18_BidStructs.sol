// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Bid struct to define targeted Punks
 * @custom:bidder Address of the bidder
 * @custom:attributesCountEnabled Is attributesCount used
 * @custom:attributesCount The number of attributes the Punk must have
 * @custom:modulo punkIndex % modulo = 0 (ex: modulo = 1000, valid punkIndexes are 0, 1000, 2000...) | 0 = not used
 * @custom:maxIndex Maximum valid index of a Punk | 0 = not used
 * @custom:indexes List of valid Punk indexes | empty = not used
 * @custom:excludedIndexes List of invalid Punk indexes | empty = not used
 * @custom:baseType Base attribute | "" = not used
 * @custom:attributes List of mandatory attributes the Punk must have, separated by a comma | "" = not used
 * @custom:amount Bid amount in wei
 * @custom:listingTime Timestamp in seconds before when the bid is not yet valid
 * @custom:expirationTime Timestamp in seconds until when the bid become invalid
 * @custom:salt Salt to differentiate similar bids
 * @custom:nonce Current nonce of the bidder
 */
struct Bid {
    address bidder;
    bool attributesCountEnabled;
    uint8 attributesCount;
    uint16 modulo;
    uint16 maxIndex;
    uint16[] indexes;
    uint16[] excludedIndexes;
    string baseType;
    string attributes;
    uint256 amount;
    uint256 listingTime;
    uint256 expirationTime;
    uint256 salt;
    uint256 nonce;
}

/**
 * @dev Input struct to link a Bid and its signature
 * @custom:bid Bid
 * @custom:v v of the signature
 * @custom:r r of the signature
 * @custom:s s of the signature
 */
struct Input {
    Bid bid;
    uint8 v;
    bytes32 r;
    bytes32 s;
}