// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './BaseAction.sol';

/**
 * @dev Action that can work with off-chain passed feed data from trusted oracles.
 * It relies on a specific "extra-calldata" layout as follows:
 *
 * [ feed 1 | feed 2 | ... | feed n | n | v | r | s ]
 *
 * For simplicity, we use full 256 bit slots for 'n', 'v', 'r', and 's' values.
 * Note that 'n' denotes the number of encoded feeds, while [v,r,s] denote the corresponding oracle signature.
 * Each feed has the following 4-words layout:
 *
 * [ base | quote | rate | deadline ]
 */
abstract contract OracledAction is BaseAction {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Feed data
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param rate Price of a token (base) expressed in `quote`. It must use the corresponding number of decimals so
     *             that when performing a fixed point product of it by a `base` amount, the result is expressed in
     *             `quote` decimals. For example, if `base` is ETH and `quote` is USDC, the number of decimals of `rate`
     *             must be 6: FixedPoint.mul(X[ETH], rate[USDC/ETH]) = FixedPoint.mul(X[18], price[6]) = X * price [6].
     * @param deadline Expiration timestamp until when the given quote is considered valid
     */
    struct FeedData {
        address base;
        address quote;
        uint256 rate;
        uint256 deadline;
    }

    // Enumerable set of trusted signers
    EnumerableSet.AddressSet private signers;

    /**
     * @dev Emitted every time a signer condition is changed
     */
    event OracleSignerSet(address indexed signer, bool allowed);

    /**
     * @dev Change an oracle signer condition
     * @param signer Address of the signer being queried
     * @param allowed Whether the signer should be allowed or not
     * @return success True if the signer was actually added or removed from the list of oracle signers
     */
    function setOracleSigner(address signer, bool allowed) external auth returns (bool success) {
        require(signer != address(0), 'ORACLED_SIGNER_ZERO');
        success = allowed ? signers.add(signer) : signers.remove(signer);
        if (success) emit OracleSignerSet(signer, allowed);
    }

    /**
     * @dev Tells the list of oracle signers
     */
    function getOracleSigners() external view returns (address[] memory) {
        return signers.values();
    }

    /**
     * @dev Tells whether an address is as an oracle signer or not
     * @param signer Address of the signer being queried
     */
    function isOracleSigner(address signer) public view returns (bool) {
        return signers.contains(signer);
    }

    /**
     * @dev Hashes the list of feeds
     * @param feeds List of feeds to be hashed
     */
    function getFeedsDigest(FeedData[] memory feeds) public pure returns (bytes32) {
        return keccak256(abi.encode(feeds));
    }

    /**
     * @dev Tries fetching a price for base/quote pair from any potential encoded off-chain oracle data. Otherwise
     * it fallbacks to the smart vault's price oracle. Off-chain oracle data is only used when it can be trusted, this
     * is: well-formed, signed by an allowed oracle, and up-to-date.
     */
    function _getPrice(address base, address quote) internal view virtual override returns (uint256) {
        (FeedData[] memory feeds, address signer) = _getEncodedOracleData();

        if (signer != address(0) && isOracleSigner(signer)) {
            for (uint256 i = 0; i < feeds.length; i++) {
                FeedData memory feed = feeds[i];
                if (feed.base == base && feed.quote == quote) {
                    require(feed.deadline >= block.timestamp, 'ORACLE_FEED_OUTDATED');
                    return feed.rate;
                }
            }
        }

        return smartVault.getPrice(base, quote);
    }

    /**
     * @dev Decodes any potential encoded off-chain oracle data.
     * @return feeds List of feeds encoded in the extra calldata.
     * @return signer Address recovered from the encoded signature in the extra calldata. A zeroed address is invalid.
     */
    function _getEncodedOracleData() private pure returns (FeedData[] memory feeds, address signer) {
        feeds = _getOracleFeeds();
        bytes32 message = ECDSA.toEthSignedMessageHash(getFeedsDigest(feeds));
        uint8 v = _getOracleSignatureV();
        bytes32 r = _getOracleSignatureR();
        bytes32 s = _getOracleSignatureS();
        signer = ecrecover(message, v, r, s);
    }

    /**
     * @dev Extracts the list of feeds encoded in the extra calldata. This function returns bogus data if there is no
     * extra calldata in place. The last feed is stored using the first four words right before the feeds length.
     */
    function _getOracleFeeds() private pure returns (FeedData[] memory feeds) {
        feeds = new FeedData[](_getFeedsLength());
        for (uint256 i = 0; i < feeds.length; i++) {
            uint256 pos = 4 * (feeds.length - i);
            FeedData memory feed = feeds[i];
            feed.base = address(uint160(uint256(_decodeCalldataWord(pos + 3))));
            feed.quote = address(uint160(uint256(_decodeCalldataWord(pos + 2))));
            feed.rate = uint256(_decodeCalldataWord(pos + 1));
            feed.deadline = uint256(_decodeCalldataWord(pos));
        }
    }

    /**
     * @dev Extracts the number of feeds encoded in the extra calldata. This function returns bogus data if there is no
     * extra calldata in place. The number of encoded feeds is encoded in the 4th word from the calldata end.
     */
    function _getFeedsLength() private pure returns (uint256) {
        return uint256(_decodeCalldataWord(3));
    }

    /**
     * @dev Extracts the component V of the oracle signature parameter from extra calldata. This function returns bogus
     * data if no signature is included. This is not a security risk, as that data would not be considered a valid
     * signature in the first place. The component V is encoded in the 3rd word from the calldata end.
     */
    function _getOracleSignatureV() private pure returns (uint8) {
        return uint8(uint256(_decodeCalldataWord(2)));
    }

    /**
     * @dev Extracts the component R of the oracle signature parameter from extra calldata. This function returns bogus
     * data if no signature is included. This is not a security risk, as that data would not be considered a valid
     * signature in the first place. The component R is encoded in the 2nd word from the calldata end.
     */
    function _getOracleSignatureR() private pure returns (bytes32) {
        return _decodeCalldataWord(1);
    }

    /**
     * @dev Extracts the component S of the oracle signature parameter from extra calldata. This function returns bogus
     * data if no signature is included. This is not a security risk, as that data would not be considered a valid
     * signature in the first place. The component S is encoded in the last word from the calldata end.
     */
    function _getOracleSignatureS() private pure returns (bytes32) {
        return _decodeCalldataWord(0);
    }

    /**
     * @dev Returns the nth 256 bit word starting from the calldata end (0 means the last calldata word).
     * This function returns bogus data if no signature is included.
     */
    function _decodeCalldataWord(uint256 n) private pure returns (bytes32 result) {
        assembly {
            result := calldataload(sub(calldatasize(), mul(0x20, add(n, 1))))
        }
    }
}