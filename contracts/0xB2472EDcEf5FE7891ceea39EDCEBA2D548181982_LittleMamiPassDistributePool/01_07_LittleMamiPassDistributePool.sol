pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LittleMamiPassDistributePool is Ownable, ReentrancyGuard {
    constructor(IERC721 _littelMamiPass) {
        littelMamiPass = _littelMamiPass;
        levelBounsMapping[1] = 10;
        levelBounsMapping[2] = 12;
        levelBounsMapping[3] = 15;
        levelNumMapping[1] = 550;
        levelNumMapping[2] = 350;
        levelNumMapping[3] = 200;
        currentRoundAllBounds =
            levelBounsMapping[1] *
            levelNumMapping[1] +
            levelBounsMapping[2] *
            levelNumMapping[2] +
            levelBounsMapping[3] *
            levelNumMapping[3];
        root = 0x1489bd9f5d589b190da497edbcacb879f3787b207b352cde41f24d38ee0de631;
    }

    IERC721 littelMamiPass;

    uint256 public status;

    bytes32 public root;

    uint256 public currentRoundAllRewards;

    uint256 public currentRoundAllBounds;

    uint256 public round;

    uint256 public totalDonate;

    mapping(uint256 => uint256) public claimedRoundMapping;

    mapping(uint256 => uint256) public levelBounsMapping;

    mapping(uint256 => uint256) public levelNumMapping;

    event Donate(address indexed donater, uint256 amount);

    fallback() external payable nonReentrant {
        if (msg.value > 0) {
            totalDonate += msg.value;
            emit Donate(msg.sender, msg.value);
        }
    }

    function setLevelBounds(
        uint256[] calldata _levels,
        uint256[] calldata _bounds
    ) external onlyOwner {
        for (uint256 i = 0; i < _levels.length; i++) {
            levelBounsMapping[_levels[i]] = _bounds[i];
        }

        currentRoundAllBounds =
            levelBounsMapping[1] *
            levelNumMapping[1] +
            levelBounsMapping[2] *
            levelNumMapping[2] +
            levelBounsMapping[3] *
            levelNumMapping[3];
    }

    function setLevelNum(uint256[] calldata _levels, uint256[] calldata _nums)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _levels.length; i++) {
            levelNumMapping[_levels[i]] = _nums[i];
        }
        currentRoundAllBounds =
            levelBounsMapping[1] *
            levelNumMapping[1] +
            levelBounsMapping[2] *
            levelNumMapping[2] +
            levelBounsMapping[3] *
            levelNumMapping[3];
    }

    function claimableThisRound(uint256 _tokenId) external view returns (bool) {
        if (status == 1 && claimedRoundMapping[_tokenId] != round) return true;
        return false;
    }

    function claimRewards(
        uint256 _tokenId,
        uint256 _level,
        bytes32[] memory _proof
    ) external nonReentrant {
        require(status == 1, "Distribute activity has not started yet");
        require(
            claimedRoundMapping[_tokenId] != round,
            "The current round rewards has been claimed"
        );
        require(
            littelMamiPass.ownerOf(_tokenId) == msg.sender,
            "Must be the owner of NFT's tokenId"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_tokenId, _level));
        require(MerkleProof.verify(_proof, root, leaf), "Verification failed");

        payable(msg.sender).transfer(getClaimRewardsAmount(_level));
        claimedRoundMapping[_tokenId] = round;
    }

    function getClaimRewardsAmount(uint256 _level)
        public
        view
        returns (uint256)
    {
        uint256 bouns = levelBounsMapping[_level];

        return (currentRoundAllRewards * bouns) / currentRoundAllBounds;
    }

    function startDistribute() external payable onlyOwner {
        require(status == 0, "Distribute activity has started");
        status = 1;
        currentRoundAllRewards = address(this).balance;
        currentRoundAllBounds = currentRoundAllBounds;
        round++;
        totalDonate += msg.value;
    }

    function stopDistribute() external onlyOwner {
        require(status == 1, "Distribute activity has not started yet");
        status = 0;
        currentRoundAllRewards = 0;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }
}