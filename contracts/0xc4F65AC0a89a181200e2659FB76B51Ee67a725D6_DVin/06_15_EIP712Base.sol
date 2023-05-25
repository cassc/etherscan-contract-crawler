pragma solidity 0.8.10;

contract EIP712Base {
    bytes32 internal DOMAIN_SEPARATOR;

    function setUpDomain(string memory name) internal {
        // This should match whats in the client side whitelist signing code
        // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L12
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // This should match the domain you set in your client side signing.
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, messageHash)
            );
    }
}