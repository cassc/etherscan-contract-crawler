// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Distributor {
    address private immutable token;
    address private owner;
    address private spender;
    bytes32 private merkleRoot;

    // This is a mapping of each leaf in the tree to the amount they claimed
    mapping(address => uint32) private amountClaimedMap;

    constructor(address token_, address spender_, bytes32 merkleRoot_) {
        token = token_;
        owner = msg.sender;
        spender = spender_;
        merkleRoot = merkleRoot_;
    }

    function changeSpender(address newSpender) public virtual {
        require(msg.sender == owner, "Distributor: not the owner");
        require(newSpender != address(0), "Distributor: change spender the zero address");
        spender = newSpender;
    }

    function updateMerkleRoot(bytes32 merkleRoot_) public {
        require(msg.sender == owner, 'Distributor: only owner can update merkle root');
        merkleRoot = merkleRoot_;
    }

    function transferOwnership(address newOwner) public virtual {
        require(msg.sender == owner, "Distributor: not the owner");
        require(newOwner != address(0), "Distributor: transfer owner the zero address");
        require(newOwner != address(this), "Distributor: transfer owner to this contract");
        owner = newOwner;
    }

    // Note: The claimed amounts in the SC are stored without decimals to reduce gas costs.
    // This implies that 1 in the amountClaimedMap = 10**18 TGT
    function amountClaimed(address account) public view returns (uint32) {
        return amountClaimedMap[account];
    }

    function claimableAmount(address account, uint32 amount, bytes32[] calldata merkleProof) external view returns (uint32) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Distributor: Invalid proof.');

        return amount - amountClaimed(account);
    }

    function claim(address account, uint32 amount, bytes32[] calldata merkleProof) external {
        uint32 amountClaimed = amountClaimed(account);
        require(amountClaimed < amount, 'Distributor: no more TGT to claim.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Distributor: Invalid proof.');

        // amount to be transferred
        uint256 diff = uint256(amount - amountClaimed) * (10**18);

        // Mark it claimed and send the token.
        amountClaimedMap[account] = amount;
        require(IERC20(token).transferFrom(spender, account, diff), 'Distributor: Transfer failed.');
    }
}