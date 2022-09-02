// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

contract EIP712Base is Ownable {

    /**
        NOTE: Altered the sequence in Domain by removing salt & adding chainID as per draft-EIP712.sol
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.1/contracts/utils/cryptography/draft-EIP712.sol
    */
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;

    }

    bytes32 internal domainSeparator;
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    uint256 private _CACHED_CHAIN_ID;
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _TYPE_HASH;

    /**
    @notice Sets domain separator
    @param _name Name of the domain
    @param _version Version of the domain
     */
    function setDomainSeparator(
        string memory _name,
        string memory _version
    ) public onlyOwner {
        require(domainSeparator == bytes32(0), "EIP712Base: domain separator is already set");
        
        bytes32 hashedName = keccak256(bytes(_name));
        bytes32 hashedVersion = keccak256(bytes(_version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"




        );
        
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        domainSeparator = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
        
    }

    /**
    @notice Gets domain separator
    @return bytes32 R
    epresenting the domain separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return domainSeparator;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     @dev Accept message hash and returns hash message in EIP712 compatible form
     @dev So that it can be used to recover signer from signature signed using EIP712 formatted data
     @dev https://eips.ethereum.org/EIPS/eip-712
     @dev "\\x19" makes the encoding deterministic
     @dev "\\x01" is the version byte to make it compatible to EIP-191
     @param _messageHash Hash of the message
     @return bytes32 Representing the typed hash of `_messageHash`
     */
    function toTypedMessageHash(bytes32 _messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), _messageHash));
    }
}