// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./libraries/SignedSafeMath.sol";
import "./token/STRM.sol";

/// @title Vesting contract
/// @notice takes merkletrees and vest them at TGE and/or linearly over a period of time
contract Vesting is Ownable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    /// @notice Precision on divisions
    uint256 private constant PRECISION = 1e12;

    // @notice Pool expiration in blocks (4 months at an average of 13 seconds per block)
    uint256 private constant POOL_EXPIRATION = 800_000;

    struct UserInfo {
        int256 rewardDebt;
    }

    struct VestInfo {
        uint256 instrumentalPerBlock;
        uint256 initialRewards;
        uint256 maxRewards;
        uint64 start;
        uint64 end;
        uint256 totalVolume;
        bytes32 root;
    }

    struct BoostInfo {
        uint64 blockNumber;
        bytes32 root;
    }

    /// @notice Address of INSTRUMENTAL contract.
    STRM public immutable INSTRUMENTAL;

    uint256 internal claimableRewards = 0;

    /// @notice mapping of pool to Boost array
    /// mapping(uint256 => Boost[]) public boosts;
    /// BoostInfo[] public boosts;
    bytes32[][] public roots;

    /// @notice roots blockNumbers where boosts are starting
    uint64[][] public rootsBN;

    /// @notice Info for each vesting.
    VestInfo[] public vestInfo;

    /// @notice Info for each user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Claim(address indexed user, uint256 indexed vid, uint256 amount);

    event LogVestAddition(
        uint256 indexed pid,
        uint256 instrumentalPerBlock,
        uint256 initialRewards,
        uint64 end,
        uint256 totalVolume
    );

    event LogUpdateVest(
        uint256 indexed vid,
        uint64 lastRewardBlock,
        uint256 accInstrumentalPerShare
    );

    event LogBoostAddition(uint256 indexed pid, bytes32 root);

    /// @notice
    /// @dev
    /// @param _instrumental ()
    constructor(STRM _instrumental) {
        INSTRUMENTAL = _instrumental;
    }

    function _arePoolExpired() internal view returns (bool) {
        uint256 end = 0;
        for (uint256 i = 0; i < vestInfo.length; ++i) {
            end = vestInfo[i].end > end ? vestInfo[i].end : end;
        }
        return block.number > end + POOL_EXPIRATION;
    }

    function withdrawLeftovers() public onlyOwner {
        require(_arePoolExpired() == true, "Vesting: Pools are not expired");
        INSTRUMENTAL.transfer(msg.sender, INSTRUMENTAL.balanceOf(address(this)));
    }

    /// @notice Returns the number of LM pools.
    /// @notice
    /// @dev
    /// @return pools (uint256)
    function vestInfoLength() public view returns (uint256 pools) {
        return vestInfo.length;
    }

    /// @notice Add a new vesting airdrop, defining the vesting yields, the lifetime and the root merkletree,
    /// merkletree leaf aggregate use address and user volume on instrumental, user rewards is the fraction of user's volume vs total volume
    /// ensure totalVolume is exactly the aggregated volume for each user or you'll get spurious results
    /// @param instrumentalPerBlock (uint256)
    /// @param initialRewards (uint256)
    /// @param end (uint64)
    /// @param totalVolume (uint256)
    /// @param root (bytes32)
    function add(
        uint256 instrumentalPerBlock,
        uint256 initialRewards,
        uint64 end,
        uint256 totalVolume,
        bytes32 root
    ) public onlyOwner {
        uint256 maxRewards = uint256(end).sub(block.number).mul(instrumentalPerBlock).add(
            initialRewards
        );
        require(
            INSTRUMENTAL.balanceOf(address(this)) >= maxRewards + claimableRewards,
            "Vesting: Insufficient funds"
        );
        claimableRewards += maxRewards;
        vestInfo.push(
            VestInfo({
                instrumentalPerBlock: instrumentalPerBlock,
                initialRewards: initialRewards,
                maxRewards: maxRewards,
                start: uint64(block.number),
                end: end,
                totalVolume: totalVolume,
                root: root
            })
        );
        roots.push(new bytes32[](0));
        rootsBN.push(new uint64[](0));
        emit LogVestAddition(
            vestInfo.length - 1,
            instrumentalPerBlock,
            initialRewards,
            end,
            totalVolume
        );
    }

    /// @notice Instrumental can boost rewards for a set of user.
    /// Every now and then Instrumental can add a mekletree at a specific block, each user present in the merkletree will get
    /// a 10% boost for the rest of the Vesting lifetime. A user elligible for multiple boost will
    /// get it's reward time shorten by 10% each time
    /// @dev
    /// @param vid (uint256)
    /// @param root (bytes32)
    function addBoost(uint256 vid, bytes32 root) public onlyOwner {
        roots[vid].push(root);
        rootsBN[vid].push(uint64(block.number));
        emit LogBoostAddition(vid, root);
    }

    function getBoost(
        uint256 vid,
        uint256 volume,
        bytes32[] memory proof
    ) public view returns (uint256 boost) {
        if (roots[vid].length == 0) return 1;
        VestInfo memory vest = vestInfo[vid];
        // require(verify(proof, vest.root, volume), "Vesting: Invalid proof");
        boost = PRECISION;
        for (uint256 i = 0; i < roots[vid].length; i++) {
            if (verify(proof, roots[vid][i], volume)) {
                uint256 weight = uint256(vest.end).sub(rootsBN[vid][i]).mul(PRECISION) /
                    (uint256(vest.end).sub(vest.start));
                boost = boost.add(weight.mul(11) / 10);
            }
        }
        boost = boost / PRECISION;
    }

    /// @notice compute pending instrumental rewards for one user
    /// @param vid (uint256)
    /// @param volume (uint256)
    /// @param proof ()
    /// @return rewards (uint256)
    function pendingInstrumental(
        uint256 vid,
        uint256 volume,
        bytes32[] memory proof
    ) public view returns (uint256 rewards) {
        VestInfo memory vest = vestInfo[vid];
        require(verify(proof, vest.root, volume), "Vesting: Invalid proof");
        UserInfo memory user = userInfo[vid][msg.sender];
        uint256 userShare = volume.mul(PRECISION) / vest.totalVolume;

        // the maxRewards this user could possibly claim
        uint256 maxRewards = vest.maxRewards.mul(userShare);

        // accumulated instrumental since vesting inception
        uint256 accumulatedInstrumental = block
            .number
            .sub(vest.start)
            .mul(vest.instrumentalPerBlock)
            .mul(getBoost(vid, volume, proof))
            .add(vest.initialRewards)
            .mul(userShare);

        uint256 maxAccumulatedInstrumental = accumulatedInstrumental > maxRewards
            ? maxRewards
            : accumulatedInstrumental;

        rewards = int256(maxAccumulatedInstrumental / PRECISION).sub(user.rewardDebt).toUInt256();
    }

    /// @notice
    /// @dev
    /// @param vid (uint256)
    /// @param to (address)
    /// @param proof ()
    /// @param volume (uint256)
    function claim(
        uint256 vid,
        address to,
        bytes32[] calldata proof,
        uint256 volume
    ) public {
        require(_arePoolExpired() == false, "LM: Pool has expired");
        UserInfo storage user = userInfo[vid][msg.sender];
        uint256 rewards = pendingInstrumental(vid, volume, proof);
        // Effects
        user.rewardDebt = user.rewardDebt.add(int256(rewards));

        // Interactions
        if (rewards != 0) {
            claimableRewards -= rewards;
            INSTRUMENTAL.transfer(to, rewards);
        }
        emit Claim(msg.sender, vid, rewards);
    }

    function claimAll(
        uint256[] calldata vids,
        address to,
        bytes32[][] calldata proofs,
        uint256[] calldata volumes
    ) public {
        for (uint256 i = 0; i < vids.length; i++) {
            claim(vids[i], to, proofs[i], volumes[i]);
        }
    }

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        uint256 volume
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, volume));
        return MerkleProof.verify(proof, root, leaf);
    }
}