// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @notice balance merkle distributor
contract BalanceMerkleDistributor is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Emitted when claimed token
    /// @param user user address
    /// @param token token address
    /// @param amount claimed amount
    event Claimed(address indexed user, address indexed token, uint256 amount);

    event MerkleRootUpdated(bytes32 indexed merkleRoot);

    address private constant ETH =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice claimed amount per token. user => token => amount
    mapping(address => mapping(address => uint256)) public claimedAmount;

    /// @notice merkle root
    bytes32 public merkleRoot;

    /// @notice setter address
    address public setter;

    constructor(address _setter) {
        setter = _setter;
    }

    /// @notice Update merkle root
    /// @param _merkleRoot new merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external {
        require(msg.sender == setter, "msg.sender is not setter");
        merkleRoot = _merkleRoot;

        emit MerkleRootUpdated(_merkleRoot);
    }

    /// @notice Update setter
    /// @param _setter setter address
    function setSetter(address _setter) external onlyOwner {
        setter = _setter;
    }

    /// @notice Claim available amount through merkle tree
    /// @param token token address
    /// @param allocation total allocation
    /// @param merkleProofs merkle proof
    function claim(
        address token,
        uint256 allocation,
        bytes32[] calldata merkleProofs
    ) public {
        bytes32 leaf = keccak256(abi.encode(msg.sender, token, allocation));

        require(
            MerkleProof.verify(merkleProofs, merkleRoot, leaf),
            "invalid proof"
        );

        uint256 availableAmount = allocation - claimedAmount[msg.sender][token];
        if (availableAmount != 0) {
            claimedAmount[msg.sender][token] = allocation;
            _transferToken(msg.sender, token, availableAmount);

            emit Claimed(msg.sender, token, availableAmount);
        }
    }

    /// @notice Claim available amount through merkle tree in batch
    /// @param tokens token address kust
    /// @param allocations total allocation list
    /// @param merkleProofs merkle proof list
    function claimInBatch(
        address[] calldata tokens,
        uint256[] calldata allocations,
        bytes32[][] calldata merkleProofs
    ) external {
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i += 1) {
            claim(tokens[i], allocations[i], merkleProofs[i]);
        }
    }

    /// @dev recover tokens by owner
    function recoverToken(address token, uint256 amount) external onlyOwner {
        _transferToken(msg.sender, token, amount);
    }

    /// @dev internal method to transfer ETH or ERC20 token to recipient address
    function _transferToken(
        address recipient,
        address token,
        uint256 amount
    ) internal {
        if (token == ETH) {
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "ether transfer failed");
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    receive() external payable {}
}