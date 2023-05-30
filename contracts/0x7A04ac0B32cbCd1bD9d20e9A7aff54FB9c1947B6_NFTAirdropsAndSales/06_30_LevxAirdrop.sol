// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MerkleProof.sol";

contract LevxAirdrop is Ownable, MerkleProof {
    using SafeERC20 for IERC20;

    address public immutable levx;
    mapping(bytes32 => bool) public isValidMerkleRoot;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _hasClaimed;

    event AddMerkleRoot(bytes32 indexed merkleRoot);
    event Claim(bytes32 indexed merkleRoot, address indexed account, uint256 amount);

    constructor(address _owner, address _levx) {
        levx = _levx;
        _transferOwnership(_owner);
    }

    function addMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        require(!isValidMerkleRoot[merkleRoot], "SHOYU: DUPLICATE_ROOT");
        isValidMerkleRoot[merkleRoot] = true;

        emit AddMerkleRoot(merkleRoot);
    }

    function claim(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) external {
        require(isValidMerkleRoot[merkleRoot], "SHOYU: INVALID_ROOT");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(!_hasClaimed[merkleRoot][leaf], "SHOYU: FORBIDDEN");
        require(verify(merkleRoot, leaf, merkleProof), "SHOYU: INVALID_PROOF");

        _hasClaimed[merkleRoot][leaf] = true;
        IERC20(levx).safeTransferFrom(owner(), msg.sender, amount);

        emit Claim(merkleRoot, msg.sender, amount);
    }
}