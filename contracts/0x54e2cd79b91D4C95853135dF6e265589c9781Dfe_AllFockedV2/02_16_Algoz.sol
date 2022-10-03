// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Algoz {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    mapping(bytes32 => bool) public consumed_token;
    address public token_verifier;
    bool public verify_enabled;
    uint public proof_ttl;

    constructor(address _token_verifier, bool _verify_enabled, uint _proof_ttl) {
        require(_proof_ttl>0, "AlgozInvalidTokenTTL");
        token_verifier = _token_verifier;
        verify_enabled = _verify_enabled; // should be true if the contract wants to use Algoz
        proof_ttl = _proof_ttl; // ideally set this value to 3
    }

    function validate_token(bytes32 expiry_token, bytes32 auth_token, bytes calldata signature_token) public {
        if(!verify_enabled) return; // skip verification if verify_enabled is false
        require(!consumed_token[auth_token], "AlgozConsumedTokenError"); // verify if the token has been used in the past
        require(SafeMath.add(uint256(expiry_token), proof_ttl) >= block.number, "AlgozTokenExpiredError"); // expire this proof if the current blocknumber > the expiry blocknumber
        require(abi.encodePacked(expiry_token, auth_token).toEthSignedMessageHash().recover(signature_token) == token_verifier, "AlgozSignatureError"); // verify if the token has been used in the past
        consumed_token[auth_token] = true;
    }

}