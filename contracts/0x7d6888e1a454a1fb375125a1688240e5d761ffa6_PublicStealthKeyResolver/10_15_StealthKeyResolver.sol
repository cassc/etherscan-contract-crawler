pragma solidity ^0.7.4;
import "../ResolverBase.sol";

abstract contract StealthKeyResolver is ResolverBase {
    bytes4 constant private STEALTH_KEY_INTERFACE_ID = 0x69a76591;

    /// @dev Event emitted when a user updates their resolver stealth keys
    event StealthKeyChanged(bytes32 indexed node, uint256 spendingPubKeyPrefix, uint256 spendingPubKey, uint256 viewingPubKeyPrefix, uint256 viewingPubKey);

    /**
     * @dev Mapping used to store two secp256k1 curve public keys useful for
     * receiving stealth payments. The mapping records two keys: a viewing
     * key and a spending key, which can be set and read via the `setsStealthKeys`
     * and `stealthKey` methods respectively.
     *
     * The mapping associates the node to another mapping, which itself maps
     * the public key prefix to the actual key . This scheme is used to avoid using an
     * extra storage slot for the public key prefix. For a given node, the mapping
     * may contain a spending key at position 0 or 1, and a viewing key at position
     * 2 or 3. See the setter/getter methods for details of how these map to prefixes.
     *
     * For more on secp256k1 public keys and prefixes generally, see:
     * https://github.com/ethereumbook/ethereumbook/blob/develop/04keys-addresses.asciidoc#generating-a-public-key
     *
     */
    mapping(bytes32 => mapping(uint256 => uint256)) _stealthKeys;

    /**
     * Sets the stealth keys associated with an ENS name, for anonymous sends.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
     * @param spendingPubKey The public key for generating a stealth address
     * @param viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
     * @param viewingPubKey The public key to use for encryption
     */
    function setStealthKeys(bytes32 node, uint256 spendingPubKeyPrefix, uint256 spendingPubKey, uint256 viewingPubKeyPrefix, uint256 viewingPubKey) external authorised(node) {
        require(
            (spendingPubKeyPrefix == 2 || spendingPubKeyPrefix == 3) &&
            (viewingPubKeyPrefix == 2 || viewingPubKeyPrefix == 3),
            "StealthKeyResolver: Invalid Prefix"
        );

        emit StealthKeyChanged(node, spendingPubKeyPrefix, spendingPubKey, viewingPubKeyPrefix, viewingPubKey);

        // Shift the spending key prefix down by 2, making it the appropriate index of 0 or 1
        spendingPubKeyPrefix -= 2;

        // Ensure the opposite prefix indices are empty
        delete _stealthKeys[node][1 - spendingPubKeyPrefix];
        delete _stealthKeys[node][5 - viewingPubKeyPrefix];

        // Set the appropriate indices to the new key values
        _stealthKeys[node][spendingPubKeyPrefix] = spendingPubKey;
        _stealthKeys[node][viewingPubKeyPrefix] = viewingPubKey;
    }

    /**
     * Returns the stealth key associated with a name.
     * @param node The ENS node to query.
     * @return spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
     * @return spendingPubKey The public key for generating a stealth address
     * @return viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
     * @return viewingPubKey The public key to use for encryption
     */
    function stealthKeys(bytes32 node) external view returns (uint256 spendingPubKeyPrefix, uint256 spendingPubKey, uint256 viewingPubKeyPrefix, uint256 viewingPubKey) {
        if (_stealthKeys[node][0] != 0) {
            spendingPubKeyPrefix = 2;
            spendingPubKey = _stealthKeys[node][0];
        } else {
            spendingPubKeyPrefix = 3;
            spendingPubKey = _stealthKeys[node][1];
        }

        if (_stealthKeys[node][2] != 0) {
            viewingPubKeyPrefix = 2;
            viewingPubKey = _stealthKeys[node][2];
        } else {
            viewingPubKeyPrefix = 3;
            viewingPubKey = _stealthKeys[node][3];
        }

        return (spendingPubKeyPrefix, spendingPubKey, viewingPubKeyPrefix, viewingPubKey);
    }

    function supportsInterface(bytes4 interfaceID) public virtual override pure returns(bool) {
        return interfaceID == STEALTH_KEY_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}