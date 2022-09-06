// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

contract EIP712Base is Ownable {
    bytes constant EIP721_DOMAIN_BYTES =
    // solium-disable-next-line
    bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)");

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal domainSeparator;
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(EIP721_DOMAIN_BYTES);

    /**
    @notice Sets domain separator
    @param _name Name of the domain
    @param _version Version of the domain
    @param _chainId ID of the chain
     */
    function setDomainSeparator(
        string memory _name,
        string memory _version,
        uint256 _chainId
    ) public onlyOwner {
        require(domainSeparator == bytes32(0), "EIP721Base: domain separator is already set");

        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                address(this),
                bytes32(_chainId)
            )
        );
    }

    /**
    @notice Gets domain separator
    @return bytes32 R
    epresenting the domain separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        return domainSeparator;
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