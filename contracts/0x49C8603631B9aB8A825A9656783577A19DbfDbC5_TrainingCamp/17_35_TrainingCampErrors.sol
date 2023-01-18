// SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.9;
// Invalid operation. Passed array's lengths doesn't match.
// @param leftLength sent correct array length.
// @param rightLength sent correct array length.
error ArrayLengthsNotMatch(uint256 leftLength, uint256 rightLength);
// Invalid pair. Passed pair is not valid.
// @param heroTokenId sent correct tokenId.
// @param villainTokenId sent correct tokenId.
error InvalidPair(uint256 heroTokenId, uint256 villainTokenId);