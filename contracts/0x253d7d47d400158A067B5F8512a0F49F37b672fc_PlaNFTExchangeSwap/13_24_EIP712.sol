// SPDX-License-Identifier: MIT

/*

  << EIP 712 >>

*/

pragma solidity ^0.8.13;

/**
 * @title EIP712
 * @author Anton
 */
contract EIP712 {
    string internal _name;
    string internal _version;
    uint256 internal immutable _chainId;
    address internal immutable _verifyingContract;
    bytes32 internal immutable _salt;
    bytes32 internal immutable DOMAIN_SEPARATOR;
    bytes4 internal constant EIP_1271_MAGICVALUE = 0x1626ba7e;

    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

    constructor(
        string memory name,
        string memory version,
        uint256 chainId,
        bytes32 salt
    ) {
        _name = name;
        _version = version;
        _chainId = chainId;
        _salt = salt;
        _verifyingContract = address(this);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"),
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                _chainId,
                _verifyingContract,
                _salt
            )
        );
    }

    function domainSeparator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }
}