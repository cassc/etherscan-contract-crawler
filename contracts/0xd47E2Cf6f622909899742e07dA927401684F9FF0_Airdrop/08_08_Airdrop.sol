// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Airdrop is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable avt;
    bytes32 public immutable merkleRoot;

    mapping(address => bool) public hasClaimed;

    error AlreadyClaimed();
    error NotInMerkle();

    event Claim(address indexed to, uint256 amount);

    constructor(bytes32 merkleRoot_, IERC20 avt_) {
        merkleRoot = merkleRoot_;
        avt = avt_;
    }

    function claim(address to, uint256 amount, bytes32[] calldata proof) external {
        if (hasClaimed[to]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        hasClaimed[to] = true;

        avt.safeTransfer(to, amount);

        emit Claim(to, amount);
    }

    function sweep(IERC20 token_) external onlyOwner {
        token_.transfer(owner(), token_.balanceOf(address(this)));
    }
}