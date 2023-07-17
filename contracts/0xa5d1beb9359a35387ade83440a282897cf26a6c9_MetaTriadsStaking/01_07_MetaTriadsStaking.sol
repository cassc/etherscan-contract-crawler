// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ITria is IERC20 {
    function mintRewardForUser(address user, uint256 amount) external {}
}

contract MetaTriadsStaking is Ownable {

    IERC721 public metatriads;
    ITria public tria;

    struct userStakeData {
        uint64 lastActionTimeStamp;
        uint64 stakedAmount;
        uint128 pendingClaim;
    }
    
    mapping(uint256 => address) public traidToOwner;
    mapping(address => userStakeData) public userToStakeData;
    mapping(address => uint256) public userToTotalEarned;

    uint256 public dailyStakingReward = 9 ether;
    uint256 public timePeriod = 1 days;

    bytes32 public bonusMerkleRoot = "";
    mapping(address => uint256) public addressToNonce;

    event Stake(address indexed staker, uint256 indexed triad);
    event Unstake(address indexed staker, uint256 indexed triad);
    event Claim(address indexed claimer, uint256 indexed amount);

    constructor(
        address _metatriads,
        address _tria
    ) {
        metatriads = IERC721(_metatriads);
        tria = ITria(_tria);
    }

    function _getRewardFromPeriod(uint256 timestamp, uint256 stakedAmount) internal view returns (uint256) {
        return (block.timestamp - timestamp) * stakedAmount * dailyStakingReward / timePeriod;
    }

    function stake(uint256 metatriad) external {        
        require(traidToOwner[metatriad] == address(0), "Metatriad already staked");
        require(metatriads.ownerOf(metatriad) == msg.sender, "Sender does not own metatriad");

        traidToOwner[metatriad] = msg.sender;

        userStakeData storage stakeData = userToStakeData[msg.sender];
        stakeData.pendingClaim += uint128(_getRewardFromPeriod(stakeData.lastActionTimeStamp, stakeData.stakedAmount));
        stakeData.stakedAmount += 1;
        stakeData.lastActionTimeStamp = uint64(block.timestamp);

        metatriads.transferFrom(msg.sender, address(this), metatriad);
        emit Stake(msg.sender, metatriad);
    }

    function unstake(uint256 metatriad) external {        
        require(traidToOwner[metatriad] == msg.sender, "Sender does not own metatriad");
        require(metatriads.ownerOf(metatriad) == address(this), "Metatriad not staked");

        delete traidToOwner[metatriad];

        userStakeData storage stakeData = userToStakeData[msg.sender];
        stakeData.pendingClaim += uint128(_getRewardFromPeriod(stakeData.lastActionTimeStamp, stakeData.stakedAmount));
        stakeData.stakedAmount -= 1;
        stakeData.lastActionTimeStamp = uint64(block.timestamp);

        metatriads.transferFrom(address(this), msg.sender, metatriad);
        emit Unstake(msg.sender, metatriad);
    }

    function stakeMany(uint256[] calldata manyMetatriads) external {
        require(manyMetatriads.length > 0, "No metatriads supplied");

        for (uint i = 0; i < manyMetatriads.length; i++) {
            uint256 metatriad = manyMetatriads[i];
            require(traidToOwner[metatriad] == address(0), "Metatriad already staked");
            require(metatriads.ownerOf(metatriad) == msg.sender, "Sender does not own metatriad");

            traidToOwner[metatriad] = msg.sender;
            metatriads.transferFrom(msg.sender, address(this), metatriad);
            emit Stake(msg.sender, metatriad);
        }

        userStakeData storage stakeData = userToStakeData[msg.sender];
        stakeData.pendingClaim += uint128(_getRewardFromPeriod(stakeData.lastActionTimeStamp, stakeData.stakedAmount));
        stakeData.stakedAmount += uint64(manyMetatriads.length);
        stakeData.lastActionTimeStamp = uint64(block.timestamp);       
    }

    function unstakeMany(uint256[] calldata manyMetatriads) external {
        require(manyMetatriads.length > 0, "No metatriads supplied");

        for (uint i = 0; i < manyMetatriads.length; i++) {
            uint256 metatriad = manyMetatriads[i];
            require(traidToOwner[metatriad] == msg.sender, "Sender does not own metatriad");
            require(metatriads.ownerOf(metatriad) == address(this), "Metatriad not staked");

            delete traidToOwner[metatriad];
            metatriads.transferFrom(address(this), msg.sender, metatriad);
            emit Unstake(msg.sender, metatriad);
        }

        userStakeData storage stakeData = userToStakeData[msg.sender];
        stakeData.pendingClaim += uint128(_getRewardFromPeriod(stakeData.lastActionTimeStamp, stakeData.stakedAmount));
        stakeData.stakedAmount -= uint64(manyMetatriads.length);
        stakeData.lastActionTimeStamp = uint64(block.timestamp);
    }

    function claimAllRewards(uint256 bonusAmount, uint256 nonce, bytes32[] memory proof) external {
        userStakeData storage stakeData = userToStakeData[msg.sender];
        uint256 pendingClaim = stakeData.pendingClaim + _getRewardFromPeriod(stakeData.lastActionTimeStamp, stakeData.stakedAmount);

        if (proof.length > 0) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, bonusAmount, nonce));
            if (MerkleProof.verify(proof, bonusMerkleRoot, leaf) && nonce == addressToNonce[msg.sender]) {
                pendingClaim += bonusAmount;
                addressToNonce[msg.sender] += 1;
            }
        }

        stakeData.pendingClaim = 0;
        stakeData.lastActionTimeStamp = uint64(block.timestamp);

        userToTotalEarned[msg.sender] += pendingClaim;

        tria.mintRewardForUser(msg.sender, pendingClaim);

        emit Claim(msg.sender, pendingClaim);
    }

    function getTotalClaimableFromUser(address user, uint256 bonusAmount, uint256 nonce, bytes32[] memory proof) external view returns (uint256) {
        userStakeData memory stakeData = userToStakeData[user];
        uint256 pendingClaim = stakeData.pendingClaim + _getRewardFromPeriod(stakeData.lastActionTimeStamp, stakeData.stakedAmount);

        if (proof.length > 0) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, bonusAmount, nonce));
            if (MerkleProof.verify(proof, bonusMerkleRoot, leaf) && nonce == addressToNonce[msg.sender]) {
                pendingClaim += bonusAmount;
            }
        }

        return pendingClaim;
    }

    function getStakedTraidsOfUser(address user) external view returns (uint256[] memory) {
        userStakeData memory stakeData = userToStakeData[user];
        uint256 amountStaked = stakeData.stakedAmount;

        uint256[] memory ownedMetaTriads = new uint256[](amountStaked);
        uint256 counter;

        for (uint i = 0; i <= 2560; i++) {
            address metatriadOwner = traidToOwner[i];

            if (metatriadOwner == user) {
                ownedMetaTriads[counter] = i;
                counter++;
            }        
        }
        return ownedMetaTriads;
    }

    function setContracts(address _metatriads, address _tria) external onlyOwner {
        metatriads = IERC721(_metatriads);
        tria = ITria(_tria);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        bonusMerkleRoot = root;
    }

    function setDailyStakingReward(uint256 _dailyStakingReward) external onlyOwner {
        dailyStakingReward = _dailyStakingReward;
    }

    function setTimePeriod(uint256 newPeriod) external onlyOwner {
        timePeriod = newPeriod;
    }

    function setApprovalForAll(address operator, bool _approved) external onlyOwner {
        metatriads.setApprovalForAll(operator, _approved);
    }
}