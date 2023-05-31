// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interface/ITpiAirdrop.sol";
import "./interface/ISegmentManagement.sol";

contract TpiAirdrop is Pausable, EIP712, ITpiAirdrop {
    IERC20 public immutable TPI;
    ISegmentManagement public immutable GNFT_SEGMENT_MANAGEMENT;
    bytes32 public merkleRoot;

    bytes32 internal constant _MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address account,uint256 amount,bytes32 nonce,uint256 deadline)"
        );

    mapping(bytes32 => bool) public hasClaimed;
    mapping(bytes32 => bool) public nonces;

    constructor(
        address gnftSegment_,
        bytes32 merkleRoot_
    ) EIP712("TpiAirdrop", "1") {
        if (gnftSegment_ == address(0)) revert ZeroAddress();
        TPI = IERC20(ISegmentManagement(gnftSegment_).TPI());
        GNFT_SEGMENT_MANAGEMENT = ISegmentManagement(gnftSegment_);
        merkleRoot = merkleRoot_;
    }

    function claim(
        address account,
        uint256 amount,
        uint256 nonce,
        bytes32[] calldata proof
    ) external whenNotPaused {
        bytes32 leaf = _validateProof(account, amount, nonce, proof);
        TPI.transfer(account, amount);
        emit Claimed(account, leaf, amount);
    }

    function permit(
        address account,
        uint256 amount,
        bytes32 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) revert DeadlineExpired();

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                account,
                amount,
                _useNonce(nonce),
                deadline
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        _validateRole(_MANAGER_ROLE, signer);

        TPI.transfer(account, amount);
    }

    function _validateProof(
        address account,
        uint256 amount,
        uint256 nonce,
        bytes32[] calldata proof
    ) private returns(bytes32) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount, nonce)))
        );
        if (hasClaimed[leaf]) revert AlreadyClaimed(leaf);
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert NotInMerkle();
        hasClaimed[leaf] = true;
        return leaf;
    }

    function _validateRole(bytes32 role, address user) internal view {
        if (!GNFT_SEGMENT_MANAGEMENT.hasRole(role, user)) revert Auth();
    }

    function _useNonce(
        bytes32 tokenAndSegment
    ) internal virtual returns (bytes32) {
        if (nonces[tokenAndSegment]) revert NonceUsed(tokenAndSegment);
        nonces[tokenAndSegment] = true;
        return tokenAndSegment;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external {
        _validateRole(_MANAGER_ROLE, msg.sender);
        merkleRoot = _merkleRoot;
    }

    function setPause(bool newState) external {
        _validateRole(_PAUSER_ROLE, msg.sender);
        newState ? _pause() : _unpause();
    }
}