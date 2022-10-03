// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract EIP5267 is EIP712 {
    bytes1 private constant f_name = hex"01";
    bytes1 private constant f_version = hex"02";
    bytes1 private constant f_chain_id = hex"04";
    bytes1 private constant f_contract = hex"08";
    bytes1 private constant f_salt = hex"10";

    string private _name;
    string private _version;

    constructor(string memory name, string memory version) EIP712(name, version) {
        _name = name;
        _version = version;
    }

    function eip712Domain() external view returns (
        bytes1 fields,
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract,
        bytes32 salt,
        uint256[] memory extensions
    ) {
        return (
            f_name | f_version | f_chain_id | f_contract,
            _name,
            _version,
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

contract EIP5267Demo is EIP5267 {
    string private constant name = "EIP5267Demo";
    string private constant version = "1";

    constructor() EIP5267(name, version) {}

    function checkSignature(address signer, uint256 value, bytes32 r, bytes32 vs) view public returns (bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Value(uint256 value)"),
            value
        )));
        address recoveredSigner = ECDSA.recover(digest, r, vs);
        return signer == recoveredSigner;
    }
}