// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/bridge/IBridge.sol";

abstract contract Signers is ISigners, Initializable {
    using ECDSA for bytes32;
    using MerkleProof for bytes32[];

    uint256 public constant P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    address public signer;
    string public chainName;

    mapping(address => mapping(uint8 => uint256)) public nonces;

    function __Signers_init(address signer_, string calldata chainName_) public onlyInitializing {
        signer = signer_;
        chainName = chainName_;
    }

    function checkSignatureAndIncrementNonce(
        uint8 methodId_,
        address contractAddress_,
        bytes32 signHash_,
        bytes calldata signature_
    ) public {
        _checkSignature(signHash_, signature_);
        ++nonces[contractAddress_][methodId_];
    }

    function validateChangeAddressSignature(
        uint8 methodId_,
        address contractAddress_,
        address newAddress_,
        bytes calldata signature_
    ) public {
        (string memory chainName_, uint256 nonce_) = getSigComponents(methodId_, contractAddress_);

        bytes32 signHash_ = keccak256(
            abi.encodePacked(methodId_, newAddress_, chainName_, nonce_, contractAddress_)
        );

        checkSignatureAndIncrementNonce(methodId_, contractAddress_, signHash_, signature_);
    }

    function getSigComponents(
        uint8 methodId_,
        address contractAddress_
    ) public view returns (string memory chainName_, uint256 nonce_) {
        return (chainName, nonces[contractAddress_][methodId_]);
    }

    function _checkSignature(bytes32 signHash_, bytes memory signature_) internal view {
        address signer_ = signHash_.recover(signature_);

        require(signer == signer_, "Signers: invalid signature");
    }

    function _checkMerkleSignature(bytes32 merkleLeaf_, bytes calldata proof_) internal view {
        (bytes32[] memory merklePath_, bytes memory signature_) = abi.decode(
            proof_,
            (bytes32[], bytes)
        );

        bytes32 merkleRoot_ = merklePath_.processProof(merkleLeaf_);

        _checkSignature(merkleRoot_, signature_);
    }

    function _convertPubKeyToAddress(bytes calldata pubKey_) internal pure returns (address) {
        require(pubKey_.length == 64, "Signers: wrong pubKey length");

        (uint256 x_, uint256 y_) = abi.decode(pubKey_, (uint256, uint256));

        // @dev y^2 = x^3 + 7, x != 0, y != 0 (mod P)
        require(x_ != 0 && y_ != 0 && x_ != P && y_ != P, "Signers: zero pubKey");
        require(
            mulmod(y_, y_, P) == addmod(mulmod(mulmod(x_, x_, P), x_, P), 7, P),
            "Signers: pubKey not on the curve"
        );

        return address(uint160(uint256(keccak256(pubKey_))));
    }

    uint256[47] private _gap;
}