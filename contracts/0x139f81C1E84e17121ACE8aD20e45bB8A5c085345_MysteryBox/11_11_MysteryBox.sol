// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MysteryBox {
    struct StakeData {
        address staker;
        address tokenAddress;
        uint256 tokenId;
    }

    event Stake(address staker, address tokenAddress, uint256 tokenId);
    event Claim(address staker, address tokenAddress, uint256 tokenId);

    uint256 public immutable deadlineBlock; //NFTの受付期限
    uint256 public constant unlockMargin = 100; //結果公開までのブロック数
    bytes32 public randomSeed;
    uint256 public constant stakeValue = 0.001 ether;

    uint256 public totalStaked;
    mapping(uint256 => StakeData) public stakes; //1 start index
    mapping(address => uint256) public stakeOf;
    mapping(address => bool) public claimed;

    constructor(uint256 deadlineBlock_) {
        require(
            deadlineBlock_ > block.number,
            "deadlineBlock should be in the future"
        );
        deadlineBlock = deadlineBlock_;
    }

    function stake(address tokenAddress, uint256 tokenId) public payable {
        require(deadlineBlock > block.number, "deadlineBlock has passed");
        require(msg.value >= stakeValue, "msg.value should be 5 ether");
        require(
            stakeOf[msg.sender] == 0 && stakes[0].staker != msg.sender,
            "You have already staked"
        );
        require(
            IERC721(tokenAddress).ownerOf(tokenId) == msg.sender,
            "You are not the owner of the token"
        );

        stakes[totalStaked] = StakeData(msg.sender, tokenAddress, tokenId);
        stakeOf[msg.sender] = totalStaked;
        totalStaked++;
        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);

        unchecked {
            randomSeed ^= keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.number,
                    msg.sender,
                    tokenAddress,
                    tokenId
                )
            );
        }

        emit Stake(msg.sender, tokenAddress, tokenId);
    }

    function stakeId(address staker) public view returns (uint256) {
        return stakeOf[staker];
    }

    function stakesByIndex(
        uint256 index,
        uint256 count
    ) public view returns (StakeData[] memory) {
        require(totalStaked >= index + count, "index+count is out of range");
        StakeData[] memory result = new StakeData[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = stakes[index + i];
        }
        return result;
    }

    function claim() public {
        require(
            block.number > deadlineBlock + unlockMargin,
            "unlockMargin has not passed"
        );
        require(!claimed[msg.sender], "You have already claimed");
        require(
            stakes[stakeOf[msg.sender]].staker == msg.sender,
            "You have not staked"
        );

        bytes32 seed = keccak256(
            abi.encodePacked(
                blockhash(deadlineBlock + unlockMargin),
                deadlineBlock + unlockMargin,
                randomSeed
            )
        );
        uint256 awardStakeId = (uint256(seed) + stakeOf[msg.sender]) %
            totalStaked;
        StakeData memory awardStake = stakes[awardStakeId];

        claimed[msg.sender] = true;
        IERC721(awardStake.tokenAddress).transferFrom(
            address(this),
            awardStake.staker,
            awardStake.tokenId
        );
        payable(msg.sender).transfer(stakeValue);

        emit Claim(msg.sender, awardStake.tokenAddress, awardStake.tokenId);
    }
}