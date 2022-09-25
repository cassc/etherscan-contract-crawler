//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./interface/IMojoMilestone.sol";

import "./interface/IMojoMilestoneStaking.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract MojoMilestoneClaimV2 is AccessControlUpgradeable {

    IMojoMilestone public mojoMilestone;
    IMojoMilestoneStaking mojoMilestoneStaking;

    bytes32 public merkleRoot;

    mapping(address => mapping(uint256 => uint256)) public claimedTokens;

    bytes32 public constant MERKLE_TREE_ROLE = keccak256("MERKLE_TREE_ROLE");

    function initialize(address mojoMilestone_, address mojoMilestoneStakingAddress) external initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MERKLE_TREE_ROLE, _msgSender());

        mojoMilestone = IMojoMilestone(mojoMilestone_);
        mojoMilestoneStaking = IMojoMilestoneStaking(mojoMilestoneStakingAddress);

    }

    function claimMilestones(address receiver, uint256[] memory tokenIds_, uint256[] memory totalClaimable_, uint256[] memory claimWanted, bytes32[] calldata proof, bool stake) external {

        require(tokenIds_.length == totalClaimable_.length, "tokenIds and totalClaimable must be same size.");
        bytes32 leaf = keccak256(abi.encodePacked(receiver, tokenIds_, totalClaimable_));
        require(MerkleProofUpgradeable.verify(proof, merkleRoot, leaf), "MerkleProof failed.");


        for (uint i = 0; i < tokenIds_.length; i++) {
            uint256 claimable = totalClaimable_[i] - claimedTokens[receiver][tokenIds_[i]];
            if (claimable > 0 && claimWanted[i] > 0 && claimWanted[i] <= claimable) {
                claimedTokens[receiver][tokenIds_[i]] = claimedTokens[receiver][tokenIds_[i]] + claimWanted[i];

                if (stake && address(mojoMilestoneStaking) != address(0)) {
                    mojoMilestoneStaking.stake(receiver, tokenIds_[i], claimWanted[i]);
                    mojoMilestone.mintAndBurn(receiver, tokenIds_[i], claimWanted[i]);
                } else {
                    mojoMilestone.mint(receiver, tokenIds_[i], claimWanted[i]);
                }
            }
        }
    }

    function updateMerkleRoot(bytes32 merkleRoot_) external onlyRole(MERKLE_TREE_ROLE) {
        merkleRoot = merkleRoot_;
    }

    function updateMojoMilestone(address mojoMilestone_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mojoMilestone = IMojoMilestone(mojoMilestone_);

    }


}