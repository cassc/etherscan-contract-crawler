// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

import "./interfaces/ISignatureMerkleDrop128.sol";

contract SignatureMerkleDrop128 is ISignatureMerkleDrop128, Ownable {
    using Address for address payable;
    using SafeERC20 for IERC20;

    address public immutable override token;
    bytes16 public immutable override merkleRoot;
    uint256 public immutable override depth;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private _claimedBitMap;

    uint256 private constant _CLAIM_GAS_COST = 60000;

    receive() external payable {}  // solhint-disable-line no-empty-blocks

    constructor(address token_, bytes16 merkleRoot_, uint256 depth_) {
        token = token_;
        merkleRoot = merkleRoot_;
        depth = depth_;
    }

    function claim(address receiver, uint256 amount, bytes calldata merkleProof, bytes calldata signature) external override {
        bytes32 signedHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(receiver)));
        address account = ECDSA.recover(signedHash, signature);
        // Verify the merkle proof.
        bytes16 node = bytes16(keccak256(abi.encodePacked(account, amount)));
        (bool valid, uint256 index) = _verifyAsm(merkleProof, merkleRoot, node);
        require(valid, "MD: Invalid proof");
        _invalidate(index);
        IERC20(token).safeTransfer(receiver, amount);
        _cashback();
    }

    function verify(bytes calldata proof, bytes16 root, bytes16 leaf) external view returns (bool valid, uint256 index) {
        return _verifyAsm(proof, root, leaf);
    }

    function verify(bytes calldata proof, bytes16 leaf) external view returns (bool valid, uint256 index) {
        return _verifyAsm(proof, merkleRoot, leaf);
    }

    function isClaimed(uint256 index) external view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _cashback() private {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            // solhint-disable-next-line avoid-tx-origin
            payable(tx.origin).sendValue(Math.min(block.basefee * _CLAIM_GAS_COST, balance));
        }
    }

    function _invalidate(uint256 index) private {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        uint256 claimedWord = _claimedBitMap[claimedWordIndex];
        uint256 newClaimedWord = claimedWord | (1 << claimedBitIndex);
        require(claimedWord != newClaimedWord, "MD: Drop already claimed");
        _claimedBitMap[claimedWordIndex] = newClaimedWord;
    }

    function _verifyAsm(bytes calldata proof, bytes16 root, bytes16 leaf) private view returns (bool valid, uint256 index) {
        /// @solidity memory-safe-assembly
        assembly {  // solhint-disable-line no-inline-assembly
            let ptr := proof.offset
            let mask := 1

            for { let end := add(ptr, proof.length) } lt(ptr, end) { ptr := add(ptr, 0x10) } {
                let node := calldataload(ptr)

                switch lt(leaf, node)
                case 1 {
                    mstore(0x00, leaf)
                    mstore(0x10, node)
                }
                default {
                    mstore(0x00, node)
                    mstore(0x10, leaf)
                    index := or(mask, index)
                }

                leaf := keccak256(0x00, 0x20)
                mask := shl(1, mask)
            }

            valid := iszero(shr(128, xor(root, leaf)))
        }
        unchecked {
            index <<= depth - proof.length / 16;
        }
    }

    function rescueFunds(address token_, uint256 amount) external onlyOwner {
        if (token_ == address(0)) {
            payable(msg.sender).sendValue(amount);
        } else {
            IERC20(token_).safeTransfer(msg.sender, amount);
        }
    }
}