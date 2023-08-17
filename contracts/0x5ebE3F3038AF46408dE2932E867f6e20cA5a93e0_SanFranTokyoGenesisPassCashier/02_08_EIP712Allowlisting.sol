//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error EIP712AllowlistNotEnabled();
error InvalidSignature();

contract EIP712Allowlisting is Ownable {
    using ECDSA for bytes32;

    error DomainSeparatorNotSet(string name, string phase);

    // The key used to sign whitelist signatures.
    // We will check to ensure that the key that signed the signature
    // is this one that we expect.
    address private allowlistSigningKey = address(0);

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side whitelist signing code
    // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L22
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet,string phase)");

    /**
     * @dev Mapping of contractName => domainSeparator
     * for requiresAllowlist to look up for with contractName
     */
    mapping(string => bytes32) private domainSeparators;

    /**
     *
     * @dev This is a helper function that can be used to generate the domain separator
     * name_ should match the name set in the NFT contract
     *     Domain Separator is the EIP-712 defined structure that defines what contract
     * and chain these signatures can be used for.  This ensures people can't take
     * a signature used to mint on one contract and use it for another, or a signature
     * from testnet to replay on mainnet.
     * It has to be created in the constructor so we can dynamically grab the chainId.
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
     */
    function _domainSeparator(
        string calldata _name
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    // This should match the domain you set in your client side signing.
                    keccak256(bytes(_name)),
                    // EIP-712 version specifies the current version of the signing domain
                    // We use default "1" as the only usecase is for the allowlist singer to authenticate via signature
                    // for whitelisting purposes
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev set domain separator for a contract and phase
     
     */
    function setDomainSeparator(
        string calldata contractName
    ) external onlyOwner {
        bytes32 separator = _domainSeparator(contractName);
        domainSeparators[contractName] = separator;
    }

    /**
     * @dev get domain separator for a contract and phase
     */
    // get domain separator for a contract and phase
    function getDomainSeparator(
        string memory contractName,
        string memory phase
    ) internal view returns (bytes32) {
        bytes32 separator = domainSeparators[contractName];
        if (separator == 0) {
            revert DomainSeparatorNotSet(contractName, phase);
        }
        return separator;
    }

    function setAllowlistSigningAddress(
        address newSigningKey
    ) public onlyOwner {
        allowlistSigningKey = newSigningKey;
    }

    function isSignatureValid(
        bytes calldata signature,
        string memory name,
        string memory phase,
        address recipient
    ) public view returns (bool) {
        if (allowlistSigningKey == address(0))
            revert EIP712AllowlistNotEnabled();
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.

        // Construct domain separator
        bytes32 domain = getDomainSeparator(name, phase);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domain,
                keccak256(
                    abi.encode(
                        MINTER_TYPEHASH,
                        recipient,
                        keccak256(bytes(phase))
                    )
                )
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        if (recoveredAddress != allowlistSigningKey) return false;
        return true;
    }

    modifier requiresAllowlist(
        bytes calldata signature,
        string memory name,
        string memory phase
    ) {
        if (!isSignatureValid(signature, name, phase, msg.sender))
            revert InvalidSignature();
        _;
    }
}