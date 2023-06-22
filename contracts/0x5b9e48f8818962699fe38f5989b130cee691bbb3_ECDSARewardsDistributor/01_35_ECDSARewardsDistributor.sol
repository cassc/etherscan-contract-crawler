/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓▌        ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "@keep-network/keep-core/contracts/KeepToken.sol";
import "@keep-network/keep-core/contracts/TokenStaking.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/cryptography/MerkleProof.sol";

/// @title ECDSA Rewards distributor
/// @notice This contract can be used by stakers to claim their rewards for
/// participation in the keep network for operating ECDSA nodes.
/// @dev This contract is based on the Uniswap's Merkle Distributor
/// https://github.com/Uniswap/merkle-distributor with some modifications:
/// - added a map of merkle root keys. Whenever a new merkle root is put in the
///   map, we assign 'true' value to this key
/// - added 'allocate()' function that will be called each time to allocate
///   new KEEP rewards for a given merkle root. Merkle root is going to be generated
///   regulary (ex. every week) and it is also means that an interval for that
///   merkle root has passed
/// - changed code accordingly to process claimed rewards using a map of merkle
///   roots
contract ECDSARewardsDistributor is Ownable {
    using SafeERC20 for KeepToken;

    KeepToken public token;
    TokenStaking public tokenStaking;

    // This event is triggered whenever a call to #claim succeeds.
    event RewardsClaimed(
        bytes32 indexed merkleRoot,
        uint256 indexed index,
        address indexed operator,
        address beneficiary,
        uint256 amount
    );
    // This event is triggered whenever rewards are allocated.
    event RewardsAllocated(bytes32 merkleRoot, uint256 amount);

    // Map of merkle roots indicating whether a given interval was allocated with
    // KEEP token rewards. For each interval there is always created a new merkle
    // tree including a root, rewarded operators along with their amounts and proofs.
    mapping(bytes32 => bool) private merkleRoots;
    // Bytes32 key is a merkle root and the value is a packed array of booleans.
    mapping(bytes32 => mapping(uint256 => uint256)) private claimedBitMap;

    constructor(address _token, address _tokenStaking) public {
        token = KeepToken(_token);
        tokenStaking = TokenStaking(_tokenStaking);
    }

    /// Claim KEEP rewards for a given merkle root (interval) and the given operator
    /// address. Rewards will be sent to a beneficiary assigned to the operator.
    /// @param merkleRoot Merkle root for a given interval.
    /// @param index Index of the operator in the merkle tree.
    /// @param operator Operator address that reward will be claimed.
    /// @param amount The amount of KEEP reward to be claimed.
    /// @param merkleProof Array of merkle proofs.
    function claim(
        bytes32 merkleRoot,
        uint256 index,
        address operator,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(
            merkleRoots[merkleRoot],
            "Rewards must be allocated for a given merkle root"
        );
        require(!isClaimed(merkleRoot, index), "Reward already claimed");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, operator, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        // Mark it claimed and send the token.
        _setClaimed(merkleRoot, index);

        address beneficiary = tokenStaking.beneficiaryOf(operator);
        require(IERC20(token).transfer(beneficiary, amount), "Transfer failed");

        emit RewardsClaimed(merkleRoot, index, operator, beneficiary, amount);
    }

    /// Allocates amount of KEEP for a given merkle root.
    /// @param merkleRoot Merkle root for a given interval.
    /// @param amount The amount of KEEP tokens allocated for the merkle root.
    function allocate(bytes32 merkleRoot, uint256 amount) public onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), amount);

        merkleRoots[merkleRoot] = true;

        emit RewardsAllocated(merkleRoot, amount);
    }

    function isClaimed(bytes32 merkleRoot, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[merkleRoot][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(bytes32 merkleRoot, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[merkleRoot][claimedWordIndex] =
            claimedBitMap[merkleRoot][claimedWordIndex] |
            (1 << claimedBitIndex);
    }
}