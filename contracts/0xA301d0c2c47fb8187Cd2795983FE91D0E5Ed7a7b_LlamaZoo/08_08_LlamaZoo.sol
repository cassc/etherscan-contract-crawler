// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
   __ _                                               
  / /| | __ _ _ __ ___   __ _/\   /\___ _ __ ___  ___ 
 / / | |/ _` | '_ ` _ \ / _` \ \ / / _ \ '__/ __|/ _ \
/ /__| | (_| | | | | | | (_| |\ V /  __/ |  \__ \  __/
\____/_|\__,_|_| |_| |_|\__,_| \_/ \___|_|  |___/\___|

*/

contract LlamaZoo is  Ownable {

    /* -------------------------------------------------------------------------- */
    /*                                    types                                   */
    /* -------------------------------------------------------------------------- */
    enum TokenType {
        StaticLlama,
        AnimatedLlama,
        SilverBoost,
        GoldBoost,
        LlamaDraws
    }

    struct Staker {
        uint256[] stakedLlamas;     // ERC721 ids
        uint256 stakedLlamaDraws;   // ERC721 tokenID
        uint128 stakedSilverBoosts; // ERC1155 amount
        uint128 stakedGoldBoosts;   // ERC1155 amount
        uint256 lastUpdated;
        uint256 totalRewards;
    }

    struct Rewards {
        uint256 staticLlama;
        uint256 animatedLlama;
        uint256 silverEnergy;
        uint256 goldEnergy;
        uint256 llamaDraws;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrStakingIsNotLive();
    error ErrNotOwner();
    error ErrStakingZeroNotAllowed();
    error ErrUnstakingZeroNotAllowed();
    error ErrLlamaDrawAlreadyStaked();
    error ErrNoLlamaDrawsStaked();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event EvStakedMultipleLlamas(address indexed sender, uint256[] tokenIDs);
    event EvUnstakeMultipleLlamas(address indexed sender, uint256[] tokenIDs);
    event EvStakeLlama(address indexed sender, uint256 tokenID);
    event EvUnstakeLlama(address indexed sender, uint256 tokenID);

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    IERC721 public pixellatedLlamaContract;
    IERC721 public llamaDrawsContract;
    IERC1155 public boostContract;

    mapping(address => Staker) public userInfo;
    mapping(address => mapping(uint256 => uint256)) public balances;

    bool public stakingLive;
    Rewards public rewards;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor(address pixellatedLlamaContract_, address llamaDrawsContract_, address boostContract_) {
        pixellatedLlamaContract = IERC721(pixellatedLlamaContract_);
        llamaDrawsContract = IERC721(llamaDrawsContract_);
        boostContract = IERC1155(boostContract_);
        rewards.staticLlama = uint256(10 ether) / 1 days;    // 10 a day per static llama
        rewards.animatedLlama = uint256(30 ether) / 1 days;  // 30 a day per animated llama
        rewards.silverEnergy = uint256(4 ether) / 1 days;    // 4 a day per silver energy
        rewards.goldEnergy = uint256(12 ether) / 1 days;     // 12 a day per gold energy
        rewards.llamaDraws = uint256(1 ether) / 1 days;      // 1 a day for each llamadraw
    }

    /* -------------------------------------------------------------------------- */
    /*                                    stake                                   */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- bulk ---------------------------------- */
    function bulkStake(
        uint256[] memory llamas,
        uint128 silverBoosts,
        uint128 goldBoosts,
        uint256 llamaDraws
    ) public {
        if (llamas.length > 0) stakeMultipleLlamas(llamas);
        stakeBoosts(silverBoosts, goldBoosts);
        if (llamaDraws != 0) stakeLlamaDraws(llamaDraws);
    }

    function bulkUnstake(
        uint256[] memory llamas,
        uint128 silverBoosts,
        uint128 goldBoosts,
        bool llamaDraws
    ) public {
        if (llamas.length > 0) unstakeMultipleLlamas(llamas);
        unstakeBoosts(silverBoosts, goldBoosts);
        if (llamaDraws) unstakeLlamaDraws();
    }

    /* --------------------------------- llamas --------------------------------- */
    function stakeMultipleLlamas(uint256[] memory tokenIds) public {
        if (!stakingLive) revert ErrStakingIsNotLive();
        uint256 animatedCount = 0;
        Staker storage staker = userInfo[msg.sender];
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] < 500) ++animatedCount;
            staker.stakedLlamas.push(tokenIds[i]);
            pixellatedLlamaContract.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        if (animatedCount > 0) {
            processStake(msg.sender,TokenType.AnimatedLlama,animatedCount);
        }

        if ((tokenIds.length - animatedCount) > 0) {
            processStake(msg.sender, TokenType.StaticLlama, tokenIds.length - animatedCount);
        }

        emit EvStakedMultipleLlamas(msg.sender, tokenIds);
    }

    function unstakeMultipleLlamas(uint256[] memory tokenIds) public {
        if (!stakingLive) revert ErrStakingIsNotLive();
        uint256 animatedCount = 0;
        Staker storage staker = userInfo[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if(!containsElement(staker.stakedLlamas,tokenId)) revert ErrNotOwner();
            if (tokenId < 500) ++animatedCount;
            pixellatedLlamaContract.transferFrom(address(this), msg.sender, tokenId);

            uint256[] memory stakedLlamas = staker.stakedLlamas;
            uint256 index;
            for (uint256 j; j < stakedLlamas.length; j++) {
                if (stakedLlamas[j] == tokenId) index = j;
            }
            if (stakedLlamas[index] == tokenId) {
                staker.stakedLlamas[index] = stakedLlamas[staker.stakedLlamas.length - 1];
                staker.stakedLlamas.pop();
            }
        }

        if (animatedCount > 0) {
            processUnstake(msg.sender,TokenType.AnimatedLlama,animatedCount);
        }
        if ((tokenIds.length - animatedCount) > 0) {
            processUnstake(
                msg.sender,
                TokenType.StaticLlama,
                tokenIds.length - animatedCount
                );  
        }

        emit EvUnstakeMultipleLlamas(msg.sender, tokenIds);
    }

    /**
     * @notice Stake a LlamaVerse llama.
     * @param tokenId The tokenId of the llama to stake 
     */
    function stakeLlama(uint256 tokenId) external {
        if (!stakingLive) revert ErrStakingIsNotLive();
        bool animated = tokenId < 500;
        Staker storage staker = userInfo[msg.sender];
        staker.stakedLlamas.push(tokenId);
        pixellatedLlamaContract.transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        processStake(
            msg.sender,
            animated ? TokenType.AnimatedLlama : TokenType.StaticLlama,
            1
        );        

        emit EvStakeLlama(msg.sender, tokenId);
    }

    /**
     * @notice Unstake a LlamaVerse llama.
     * @param tokenId The tokenId of the llama to unstake 
     */
    function unstakeLlama(uint256 tokenId) external {
        if (!stakingLive) revert ErrStakingIsNotLive();
        bool animated = tokenId < 500;
        Staker storage staker = userInfo[msg.sender];
        if (!containsElement(staker.stakedLlamas, tokenId)) revert ErrNotOwner();

        pixellatedLlamaContract.transferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        uint256[] memory stakedLlamas = staker.stakedLlamas;
        uint256 index;
        for (uint256 i; i < stakedLlamas.length; i++) {
            if (stakedLlamas[i] == tokenId) index = i;
        }
        if (stakedLlamas[index] == tokenId) {
            processUnstake(
                msg.sender, 
                animated ? TokenType.AnimatedLlama : TokenType.StaticLlama,
                1
            );
            
            staker.stakedLlamas[index] = stakedLlamas[staker.stakedLlamas.length - 1];
            staker.stakedLlamas.pop();
        }

        emit EvUnstakeLlama(msg.sender, tokenId);
    }

    /* --------------------------------- boosts --------------------------------- */
    function stakeBoosts(uint128 silverAmount, uint128 goldAmount) public {
        if (silverAmount != 0) stakeSilverBoosts(silverAmount);
        if (goldAmount != 0) stakeGoldBoosts(goldAmount);
    }

    function unstakeBoosts(uint128 silverAmount, uint128 goldAmount) public {
        if (silverAmount != 0) unstakeSilverBoosts(silverAmount);
        if (goldAmount != 0) unstakeGoldBoosts(goldAmount);
    }
    
    /**
     * @notice Stake silver boosts.
     * @param amount The amount of boosts to stake. 
     */
    function stakeSilverBoosts(uint128 amount) public {
        if (!stakingLive) revert ErrStakingIsNotLive();
        if (amount == 0) revert ErrStakingZeroNotAllowed();

        userInfo[msg.sender].stakedSilverBoosts += amount;
        boostContract.safeTransferFrom(
            msg.sender,
            address(this),
            2,
            amount,
            ""
        );
        processStake(msg.sender,TokenType.SilverBoost,amount);
    }

    /**
     * @notice Unstake silver boosts.
     * @param amount The amount of boosts to unstake. 
     */
    function unstakeSilverBoosts(uint128 amount) public {
        if (!stakingLive) revert ErrStakingIsNotLive();
        if (amount == 0) revert ErrUnstakingZeroNotAllowed();

        userInfo[msg.sender].stakedSilverBoosts -= amount;
        boostContract.safeTransferFrom(
            address(this),
            msg.sender,
            2,
            amount,
            ""
        );
        processUnstake(msg.sender, TokenType.SilverBoost, amount);
    }

    /**
     * @notice Stake gold boosts with the requested tokenID.
     * @param amount The amount of boosts to stake. 
     */
    function stakeGoldBoosts(uint128 amount) public {
        if (!stakingLive) revert ErrStakingIsNotLive();
        if (amount == 0) revert ErrStakingZeroNotAllowed();
        userInfo[msg.sender].stakedGoldBoosts += amount;
        boostContract.safeTransferFrom(
            msg.sender,
            address(this),
            1,
            amount,
            ""
        );
        processStake(msg.sender, TokenType.GoldBoost, amount);
    }

    /**
     * @notice Unstake gold boosts with the requested tokenID.
     * @param amount The amount of boosts to stake. 
     */
    function unstakeGoldBoosts(uint128 amount) public {
        if (!stakingLive) revert ErrStakingIsNotLive();
        if (amount == 0) revert ErrUnstakingZeroNotAllowed();
        userInfo[msg.sender].stakedGoldBoosts -= amount;
        boostContract.safeTransferFrom(
            address(this),
            msg.sender,
            1,
            amount,
            ""
        );

        processUnstake(msg.sender, TokenType.GoldBoost, amount);
    }

    /* ---------------------------------- draws --------------------------------- */
    /**
     * @notice Stake a Llamadraws.
     * @param tokenId The token ID of the llamadraws to stake.
     */
    function stakeLlamaDraws(uint256 tokenId) public {
        if (!stakingLive) revert ErrStakingIsNotLive();
        if (userInfo[msg.sender].stakedLlamaDraws != 0) revert ErrLlamaDrawAlreadyStaked();

        userInfo[msg.sender].stakedLlamaDraws = tokenId;
        llamaDrawsContract.transferFrom(msg.sender, address(this), tokenId);

        processStake(msg.sender, TokenType.LlamaDraws, 1);
    }

    /**
     * @notice Unstake your Llamadraws.
     */
    function unstakeLlamaDraws() public {
        if (!stakingLive) revert ErrStakingIsNotLive();
        if (userInfo[msg.sender].stakedLlamaDraws == 0) revert ErrNoLlamaDrawsStaked();

        llamaDrawsContract.transferFrom(
            address(this),
            msg.sender,
            userInfo[msg.sender].stakedLlamaDraws
        );
        userInfo[msg.sender].stakedLlamaDraws = 0;

        processUnstake(msg.sender, TokenType.LlamaDraws, 1);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Set the contract addresses for all contract instances.
     * @param pixellatedLlamaContract_ The contract address of PixellatedLlama.
     * @param llamaDrawsContract_ The contract address of LlamaDraws.
     * @param boostContract_ The contract address of RewardBooster.
     */
    function setContractAddresses(
        address pixellatedLlamaContract_,
        address llamaDrawsContract_,
        address boostContract_
    ) public onlyOwner {
        pixellatedLlamaContract = IERC721(pixellatedLlamaContract_);
        llamaDrawsContract = IERC721(llamaDrawsContract_);
        boostContract = IERC1155(boostContract_);
    }

    /**
     * @notice Pauses staking and unstaking, for emergency purposes
     * @dev If we have to migrate because of Polygon instability or state sync issues, this will save us
     */
    function setStakingLive(bool live) public onlyOwner {
        stakingLive = live;
    }

    /**
     * @notice Allows the contract deployer to sets the reward rates for each token type.
     * @param staticLlama The reward rate for staking a static llama.
     * @param animatedLlama The reward rate for staking an animated llama.
     * @param silverEnergy The reward rate for staking a silver llama boost.
     * @param goldEnergy The reward rate for staking a gold llama boost.
     */
    function setRewardRates(
        uint256 staticLlama,
        uint256 animatedLlama,
        uint256 silverEnergy,
        uint256 goldEnergy,
        uint256 llamaDraws
    ) public onlyOwner {
        rewards.staticLlama = staticLlama;
        rewards.animatedLlama = animatedLlama;
        rewards.silverEnergy = silverEnergy;
        rewards.goldEnergy = goldEnergy;
        rewards.llamaDraws = llamaDraws;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice For collab.land to give a role based on staking status
     */
    function balanceOf(address owner) public view returns (uint256) {
        uint[] memory llamas = userInfo[owner].stakedLlamas;
        if (llamas.length == 0) return 0;
        for (uint256 i = 0; i < llamas.length; i++) {
           if(llamas[i] < 500) return 1;
        }
        return 2;
    }

    /**
     * @dev Using the mapping directly wasn't returning the array, so we made this helper fuction.
     */
    function getStakedTokens(address user) public view returns (
        uint256[] memory llamas, uint256 llamaDraws, uint128 silverBoosts, uint128 goldBoosts
    ) {
        Staker memory staker = userInfo[user];
        return (
            staker.stakedLlamas,
            staker.stakedLlamaDraws,
            staker.stakedSilverBoosts,
            staker.stakedGoldBoosts
        );
    }

    function getAccountTotalRewards(address account) external view returns(uint256) {
        return userInfo[account].totalRewards + earned(account);
    }

    /**
     * @notice Calculates the total amount of rewards accumulated for a staker, for staking all owned token types.
     * @dev Calculates based on when the staker last withdrew rewards, and compares it with the current block's timestamp.
     * @param account The account to calculate the accumulated rewards for.
     */
    function earned(address account) public view returns (uint256) {
        return spitPerSecond(account) * (block.timestamp - userInfo[account].lastUpdated);
    }

    /**
     * @notice Calculates the amount of SPIT earned per second by the given user
     * @param account The account to calculate the accumulated rewards for.
     */
    function spitPerSecond(address account) public view returns (uint256) {
        return (
            // static llama
            (balances[account][uint256(TokenType.StaticLlama)] * rewards.staticLlama) +

            // animated llama
            (balances[account][uint256(TokenType.AnimatedLlama)] * rewards.animatedLlama) +

            // silver
            (min(
                balances[account][uint256(TokenType.SilverBoost)], 
                balances[account][uint256(TokenType.StaticLlama)]) * rewards.silverEnergy
            ) +

            // gold
            (min(
                balances[account][uint256(TokenType.GoldBoost)], 
                balances[account][uint256(TokenType.AnimatedLlama)]) * rewards.goldEnergy
            ) +

            // llama draws
            (balances[account][uint256(TokenType.LlamaDraws)] * rewards.llamaDraws)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                                 on received                                */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
     * This function MAY throw to revert and reject the transfer.
     * Return of other amount than the magic value MUST result in the transaction being reverted.
     * Note: The token contract address is always the message sender.
     * @param operator  The address which called the `safeTransferFrom` function.
     * @param from      The address which previously owned the token.
     * @param id        The id of the token being transferred.
     * @param amount    The amount of tokens being transferred.
     * @param data      Additional data with no specified format.
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
     * This function MAY throw to revert and reject the transfer.
     * Return of other amount than the magic value WILL result in the transaction being reverted.
     * Note: The token contract address is always the message sender.
     * @param operator  The address which called the `safeBatchTransferFrom` function.
     * @param from      The address which previously owned the token.
     * @param ids       An array containing ids of each token being transferred.
     * @param amounts   An array containing amounts of each token being transferred.
     * @param data      Additional data with no specified format.
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   helpers                                  */
    /* -------------------------------------------------------------------------- */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function containsElement(uint[] memory elements, uint tokenId) internal pure returns (bool) {
        for (uint256 i = 0; i < elements.length; i++) {
           if(elements[i] == tokenId) return true;
        }
        return false;
    }
    
    /**
     * @notice Called when withdrawing rewards. $SPIT is transferred to the address, and the lastUpdated field is updated.
     * @param account The address to mint to.
     */
    modifier updateReward(address account) {
        uint256 amount = earned(account);
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            userInfo[account].totalRewards += amount;
        }

        userInfo[account].lastUpdated = block.timestamp;
        _;
    }

    /**
     * @notice Internal call to stake an amount of a specific token type.
     * @param account The address which will be staking.
     * @param tokenType The token type to stake.
     * @param amount The amount to stake.
     */
    function processStake(
        address account,
        TokenType tokenType,
        uint256 amount
    ) internal updateReward(account) {
        balances[account][uint256(tokenType)] += amount;
    }

    /**
     * @notice Internal call to unstake an amount of a specific token type.
     * @param account The address which will be unstaking.
     * @param tokenType The token type to unstake.
     * @param amount The amount to unstake.
     */
    function processUnstake(
        address account,
        TokenType tokenType,
        uint256 amount
    ) internal updateReward(account) {
        balances[account][uint256(tokenType)] -= amount;
    }
}