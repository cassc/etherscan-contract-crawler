// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./WhiteRabbitProducerPass.sol";

/*
 * This contract allows users to stake and unstake producer passes
 * independent of any chapter in the White Rabbit IP
 */
contract ProducerPassStaking is Ownable, ERC1155Holder {
    mapping(uint256 => bool) public isProducerPassStakingEnabledForId;
    mapping(uint256 => bool) public isProducerPassUnstakingEnabledForId;

    mapping(address => mapping(uint256 => uint256))
        public stakedProducerPassesFromUser;
    ERC1155 public producerPassContract;

    function isStakingEnabledForChapter(uint256 chapter)
        public
        view
        virtual
        returns (bool)
    {
        return isProducerPassStakingEnabledForId[chapter];
    }

    function isUnstakingEnabledForChapter(uint256 chapter)
        public
        view
        virtual
        returns (bool)
    {
        return isProducerPassUnstakingEnabledForId[chapter];
    }

    function setProducerPassContract(address add) external onlyOwner {
        producerPassContract = ERC1155(add);
    }

    function setProducerPassStakingEnabledForIds(
        uint256[] calldata chapterIds,
        bool[] calldata enabled
    ) external onlyOwner {
        for (uint256 i = 0; i < chapterIds.length; i++) {
            uint256 chapterId = chapterIds[i];
            bool enable = enabled[i];
            isProducerPassStakingEnabledForId[chapterId] = enable;
        }
    }

    function setProducerPassUnstakingEnabledForIds(
        uint256[] calldata chapterIds,
        bool[] calldata enabled
    ) external onlyOwner {
        for (uint256 i = 0; i < chapterIds.length; i++) {
            uint256 chapterId = chapterIds[i];
            bool enable = enabled[i];
            isProducerPassUnstakingEnabledForId[chapterId] = enable;
        }
    }

    function stakeProducerPasses(
        uint256[] calldata chapterIds,
        uint256[] calldata amounts
    ) public {
        for (uint256 i = 0; i < chapterIds.length; i++) {
            uint256 chapterId = chapterIds[i];
            uint256 amount = amounts[i];
            require(
                isProducerPassStakingEnabledForId[chapterId],
                "Staking for this chapter Not enabled"
            );

            require(amount > 0, "Cannot stake 0");
            require(
                producerPassContract.balanceOf(msg.sender, chapterId) >= amount,
                "Insufficient pass balance"
            );
            producerPassContract.safeTransferFrom(
                msg.sender,
                address(this),
                chapterId,
                amount,
                ""
            );
            uint256 previousStakedAmount = stakedProducerPassesFromUser[
                msg.sender
            ][chapterId];
            stakedProducerPassesFromUser[msg.sender][chapterId] =
                previousStakedAmount +
                amount;
        }
    }

    function unstakeProducerPasses(
        uint256[] calldata chapterIds,
        uint256[] calldata amounts
    ) public {
        for (uint256 i = 0; i < chapterIds.length; i++) {
            uint256 chapterId = chapterIds[i];
            uint256 amount = amounts[i];
            require(
                isProducerPassUnstakingEnabledForId[chapterId],
                "Unstaking not enabled"
            );
            require(amount > 0, "Cannot unstake 0");
            require(
                stakedProducerPassesFromUser[msg.sender][chapterId] >= amount,
                "Not enough producer pass staked"
            );
            producerPassContract.safeTransferFrom(
                address(this),
                msg.sender,
                chapterId,
                amount,
                ""
            );
            uint256 previousStakedAmount = stakedProducerPassesFromUser[
                msg.sender
            ][chapterId];
            stakedProducerPassesFromUser[msg.sender][chapterId] =
                previousStakedAmount -
                amount;
        }
    }
}