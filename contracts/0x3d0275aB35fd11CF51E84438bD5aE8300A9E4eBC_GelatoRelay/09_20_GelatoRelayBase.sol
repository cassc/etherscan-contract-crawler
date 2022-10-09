// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IGelatoRelayBase} from "../interfaces/IGelatoRelayBase.sol";
import {GelatoString} from "../lib/GelatoString.sol";
import {SponsoredCall, SponsoredUserAuthCall} from "../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract GelatoRelayBase is IGelatoRelayBase {
    using GelatoString for string;

    mapping(address => uint256) public userNonce;

    address public immutable gelato;

    bytes32 public constant SPONSORED_CALL_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "SponsoredCall(uint256 chainId,address target,bytes data)"
            )
        );

    bytes32 public constant SPONSORED_USER_AUTH_CALL_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "SponsoredUserAuthCall(uint256 chainId,address target,bytes data,address user,uint256 userNonce,uint256 userDeadline)"
            )
        );

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;
    }

    function _requireChainId(uint256 _chainId, string memory _errorTrace)
        internal
        view
    {
        require(_chainId == block.chainid, _errorTrace.suffix("chainid"));
    }

    function _requireUserBasics(
        uint256 _callUserNonce,
        uint256 _storedUserNonce,
        uint256 _userDeadline,
        string memory _errorTrace
    ) internal view {
        require(
            _callUserNonce == _storedUserNonce,
            _errorTrace.suffix("nonce")
        );
        require(
            // solhint-disable-next-line not-rely-on-time
            _userDeadline == 0 || _userDeadline >= block.timestamp,
            _errorTrace.suffix("deadline")
        );
    }

    function _requireSponsoredCallSignature(
        bytes32 _domainSeparator,
        SponsoredCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeSponsoredCall(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBase1Balance._requireSponsoredCallSignature"
        );
    }

    function _requireSponsoredUserAuthCallSignature(
        bytes32 _domainSeparator,
        SponsoredUserAuthCall calldata _call,
        bytes calldata _signature,
        address _expectedSigner
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeSponsoredUserAuthCall(_call))
            )
        );

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            digest,
            _signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == _expectedSigner,
            "GelatoRelayBase1Balance._requireSponsoredUserAuthCallSignature"
        );
    }

    function _abiEncodeSponsoredCall(SponsoredCall calldata _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                SPONSORED_CALL_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data)
            );
    }

    function _abiEncodeSponsoredUserAuthCall(
        SponsoredUserAuthCall calldata _call
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                SPONSORED_USER_AUTH_CALL_TYPEHASH,
                _call.chainId,
                _call.target,
                keccak256(_call.data),
                _call.user,
                _call.userNonce,
                _call.userDeadline
            );
    }
}