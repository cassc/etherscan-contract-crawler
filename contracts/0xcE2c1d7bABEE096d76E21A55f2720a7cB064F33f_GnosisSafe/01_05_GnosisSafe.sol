// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./libraries/SafeMath.sol";
import "./OwnerManager.sol";
import "./SignatureDecoder.sol";

contract GnosisSafe is OwnerManager, SignatureDecoder {
    using SafeMath for uint256;

    enum Operation {
        Call,
        DelegateCall
    }

    uint256 public nonce;

    // keccak256("ExecTransaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)");
    bytes32 private constant EXEC_TX_TYPEHASH =
        0xa609e999e2804ed92314c0c662cfdb3c1d8107df2fb6f2e4039093f20d5e6250;

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    string public constant name = "GnosisSafe V1";
    string public constant VERSION = "1";
    bytes32 public DOMAIN_SEPARATOR;

    constructor(address[] memory _owners, uint256 _threshold) {
        setupOwners(_owners, _threshold);
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(VERSION)),
                chainId,
                address(this)
            )
        );
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        bytes memory signatures
    ) public {
        bytes32 txHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        EXEC_TX_TYPEHASH,
                        to,
                        value,
                        keccak256(data),
                        operation,
                        nonce
                    )
                )
            )
        );
        nonce = nonce + 1;
        checkSignatures(txHash, signatures);
        require(execute(to, value, data, operation), "call error");
    }

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            EXEC_TX_TYPEHASH,
                            to,
                            value,
                            keccak256(data),
                            operation,
                            nonce
                        )
                    )
                )
            );
    }

    function checkSignatures(bytes32 dataHash, bytes memory signatures)
        public
        view
    {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "GS001");
        checkNSignatures(dataHash, signatures, _threshold);
    }

    function checkNSignatures(
        bytes32 dataHash,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        require(signatures.length >= requiredSignatures.mul(65), "GS020");
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            currentOwner = ecrecover(dataHash, v, r, s);
            require(
                currentOwner > lastOwner &&
                    owners[currentOwner] != address(0) &&
                    currentOwner != SENTINEL_OWNERS,
                "GS026"
            );
            lastOwner = currentOwner;
        }
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) internal returns (bool success) {
        if (operation == Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(
                    gas(),
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(
                    gas(),
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        }
    }
}