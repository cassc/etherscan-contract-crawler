// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

abstract contract EIP712 
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory name) 
    {
        nameHash = keccak256(bytes(name));
    }

    bytes32 private constant eip712DomainHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant versionHash = keccak256(bytes("1"));
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 public immutable nameHash;
    
    function domainSeparator()
        internal
        view
        returns (bytes32) 
    {
        // Can't cache this in an upgradeable contract unfortunately
        return keccak256(abi.encode(
            eip712DomainHash,
            nameHash,
            versionHash,
            block.chainid,
            address(this)));
    }
    
    function getSigningHash(bytes32 dataHash)
        internal
        view
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator(), dataHash));
    }
}