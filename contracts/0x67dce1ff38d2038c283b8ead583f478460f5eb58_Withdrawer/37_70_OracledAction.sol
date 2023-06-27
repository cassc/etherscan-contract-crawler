// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import 'hardhat/console.sol';
import './BaseAction.sol';
import './interfaces/IOracledAction.sol';

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
abstract contract OracledAction is IOracledAction, BaseAction {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Each feed has 4 words length
    uint256 private constant EXPECTED_FEED_DATA_LENGTH = 32 * 4;

    // Enumerable set of trusted signers
    EnumerableSet.AddressSet private _signers;

    /**
     * @dev Oracled action config. Only used in the constructor.
     * @param signers List of oracle signers to be allowed
     */
    struct OracleConfig {
        address[] signers;
    }

    /**
     * @dev Creates a new oracled action
     */
    constructor(OracleConfig memory config) {
        _addOracleSigners(config.signers);
    }

    /**
     * @dev Tells the list of oracle signers
     */
    function getOracleSigners() external view override returns (address[] memory) {
        return _signers.values();
    }

    /**
     * @dev Tells whether an address is as an oracle signer or not
     * @param signer Address of the signer being queried
     */
    function isOracleSigner(address signer) public view override returns (bool) {
        return _signers.contains(signer);
    }

    /**
     * @dev Hashes the list of feeds
     * @param feeds List of feeds to be hashed
     */
    function getFeedsDigest(FeedData[] memory feeds) public pure override returns (bytes32) {
        return keccak256(abi.encode(feeds));
    }

    /**
     * @dev Updates the list of allowed oracle signers
     * @param toAdd List of signers to be added to the oracle signers list
     * @param toRemove List of signers to be removed from the oracle signers list
     * @notice The list of signers to be added will be processed first to make sure no undesired signers are allowed
     */
    function setOracleSigners(address[] memory toAdd, address[] memory toRemove) external override auth {
        _addOracleSigners(toAdd);
        _removeOracleSigners(toRemove);
    }

    /**
     * @dev Adds a list of addresses to the signers allow-list
     * @param signers List of addresses to be added to the signers allow-list
     */
    function _addOracleSigners(address[] memory signers) internal {
        for (uint256 i = 0; i < signers.length; i++) {
            address signer = signers[i];
            require(signer != address(0), 'SIGNER_ADDRESS_ZERO');
            if (_signers.add(signer)) emit OracleSignerAllowed(signer);
        }
    }

    /**
     * @dev Removes a list of addresses from the signers allow-list
     * @param signers List of addresses to be removed from the signers allow-list
     */
    function _removeOracleSigners(address[] memory signers) internal {
        for (uint256 i = 0; i < signers.length; i++) {
            address signer = signers[i];
            if (_signers.remove(signer)) emit OracleSignerDisallowed(signer);
        }
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
        if (feeds.length == 0) return (feeds, address(0));

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
        // Since the decoding functions could return garbage, if the calldata length is smaller than the potential
        // decoded feeds length, we can assume it's garbage and that there is no encoded feeds actually
        uint256 length = _getFeedsLength();
        if (msg.data.length < length) return new FeedData[](0);

        feeds = new FeedData[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 pos = 4 * (length - i);
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