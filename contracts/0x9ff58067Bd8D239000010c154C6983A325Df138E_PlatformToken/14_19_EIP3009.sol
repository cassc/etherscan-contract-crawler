// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./EIP712Domain.sol";
import "./EIP712.sol";

abstract contract EIP3009 is EIP712Domain {
    // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    // keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    error AuthorizationNotYetValid();
    error AuthorizationExpired();
    error NoncePreviouslyUsed();
    error InvalidSignature();

    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        if(block.timestamp <= validAfter)
            revert AuthorizationNotYetValid();
        if(block.timestamp >= validBefore)
            revert AuthorizationExpired();
        if(_authorizationStates[from][nonce])
            revert NoncePreviouslyUsed();

        bytes memory data = abi.encode(
            TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce
        );
        if(EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) != from)
            revert InvalidSignature();

        _authorizationStates[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);
    }
}