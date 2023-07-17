pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./VNFT.sol";

contract PetAirdrop {
    event Claimed(uint256 index, address owner);

    VNFT public immutable petMinter;
    bytes32 public immutable merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(VNFT pet_minter_, bytes32 merkleRoot_) public {
        petMinter = pet_minter_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(uint256 index, bytes32[] calldata merkleProof) external {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");
        // console.logBytes(abi.encodePacked(index));
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(bytes32(index)));
        // console.logBytes32(node);
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);

        petMinter.mint(msg.sender);

        emit Claimed(index, msg.sender);
    }
}