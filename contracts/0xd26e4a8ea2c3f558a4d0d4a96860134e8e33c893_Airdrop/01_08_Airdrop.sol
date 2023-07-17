// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Airdrop is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// @notice address of USDC token
    address public immutable tokenUSDC;

    /// @notice address of BUMP token
    address public immutable tokenBUMP;

    /// @notice Merkle tree root hash
    /// @dev Should be computed off-chain and be passed to contract
    ///      every time, when data, stored in tree nodes (address and amount of BUMP/USDC)
    ///      changes
    bytes32 public merkleRoot;

    /// @notice Packed array of booleans.
    /// @dev Value should be set using _setClaimed() function
    ///      Value should be taken using isClaimed() function
    mapping(uint256 => uint256) private claimedBitMap;

    // This event is triggered whenever a claim succeeds
    event Claimed(
        uint256 index,
        address indexed account,
        uint256 amountUSDC,
        uint256 amountBUMP,
        uint256 timestamp
    );

    /// @param _tokenUSDC USDC token address
    /// @param _tokenBUMP BUMP token address
    /// @param _merkleRoot Initial hash root of merle tree
    constructor(
        address _tokenUSDC,
        address _tokenBUMP,
        bytes32 _merkleRoot
    ) {
        require(_tokenUSDC != address(0), "Zero USDC address");
        require(_tokenBUMP != address(0), "Zero BUMP address");

        tokenUSDC = _tokenUSDC;
        tokenBUMP = _tokenBUMP;
        merkleRoot = _merkleRoot;

        // contract is paused by default
        _pause();
    }

    /// @notice Pauses contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Claim a specific amount of tokens.
    /// @param index Unique idendifier of tree record. Records with same index are not allowed
    /// @param account Air-droped tokens owner
    /// @param amountUSDC Amount of USDC tokens to claim
    /// @param amountBUMP Amount of BUMP tokens to claim
    /// @param merkleProof  Proof of data accuracy
    function claim(
        uint256 index,
        address account,
        uint256 amountUSDC,
        uint256 amountBUMP,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        _claim(index, account, amountUSDC, amountBUMP, merkleProof);
    }

    /// @notice Bulk token claim.
    /// @dev Can only be invoked if the escrow is NOT paused.
    /// @param claimArgs array encoded values (index, account, amount, timestamp, merkleProof)
    function claimBulk(bytes[] calldata claimArgs) external whenNotPaused {
        for (uint256 i = 0; i < claimArgs.length; i++) {
            (uint256 index, address account, uint256 amountUSDC, uint256 amountBUMP, bytes32[] memory merkleProof) = abi.decode(
                    claimArgs[i],
                (uint256, address, uint256, uint256, bytes32[])
            );
            _claim(index, account, amountUSDC, amountBUMP, merkleProof);
        }
    }

    /// @notice Claim a specific amount of tokens.
    /// @param index Unique idendifier of tree record. Records with same index are not allowed
    /// @param account Air-droped tokens owner
    /// @param amountUSDC Amount of USDC tokens to claim
    /// @param amountBUMP Amount of BUMP tokens to claim
    /// @param merkleProof  Proof of data accuracy
    function _claim(
        uint256 index,
        address account,
        uint256 amountUSDC,
        uint256 amountBUMP,
        bytes32[] memory merkleProof
    ) internal {
        require(merkleRoot != bytes32(0), "Merkle root not set");
        require(!isClaimed(index), "Drop already claimed");

        // Verify the merkle proof.
        bytes32 node = keccak256(
            abi.encodePacked(index, account, amountUSDC, amountBUMP)
        );
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        // Mark it claimed and send the token.
        _setClaimed(index);

        if (amountUSDC > 0) {
            IERC20(tokenUSDC).safeTransfer(account, amountUSDC);
        }

        if (amountBUMP > 0) {
            IERC20(tokenBUMP).safeTransfer(account, amountBUMP);
        }

        emit Claimed(index, account, amountUSDC, amountBUMP, block.timestamp);
    }

    /// @notice Withdraws tokens, stored on this contract to address
    function withdraw(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice Updates merkle tree root hash
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    /// @notice Check for index been claimed or not
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// @dev set claimedBitMap mapping value to `true`
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }
}