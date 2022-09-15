// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Staking functionality to earn TTKKNN.
/// @author 67ac2b3e1a1f71cdf69d11eb2baf93ad284264f20087ffc2866cfce01204fe91
/// @notice You can use this contract to stake an ERC721 token and earn TTKKNN.
contract StakingAbstract is IERC721Receiver, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    /// @notice A Stake struct represents how a staked token is stored.
    struct Stake {
        address user;
        uint256 tokenId;
        uint256 stakedFromBlock;
    }

    /// @notice A Stakeholder struct stores an address and its active Stakes.
    struct Stakeholder {
        address user;
        Stake[] addressStakes;
    }

     /// @notice A StakingSummary struct stores an array of Stake structs.
     struct StakingSummary {
         Stake[] stakes;
     }

    /// @notice Interface definition for the ERC721 token that is being staked.
    /// @dev This is given a generalized name and can be any ERC721 collection.
    IERC721 public utilityToken;

    /// @notice Interface definition for the ERC20 token that is being used a staking reward.
    /// @dev This can be any ERC20 token but will be TTKKNN in this case.
    IERC20 public someToken;

    /// @notice The amount of ERC20 tokens received as a reward for every block an ERC721 token is staked.
    /// @dev Expressed in Wei.
    // Reference: https://ethereum.org/en/developers/docs/blocks/
    // Reference for merge: https://blog.ethereum.org/2021/11/29/how-the-merge-impacts-app-layer/
    uint256 public tokensPerBlock;

    /// @notice An address is used as a key to an index value in the stakes that occur.
    mapping(address => uint256) private stakes;
    /// @notice An address is used as a key to the array of Stakes.
    mapping(address => Stake[]) private addressStakes;
    /// @notice An integer is used as key to the value of a Stake in order to provide a receipt.
    mapping(uint256 => Stake) public receipt;

    /// @notice All current stakeholders.
    Stakeholder[] private stakeholders;

     /// @notice Emitted when a token is staked.
    event Staked(address indexed user, uint256 indexed tokenId, uint256 staredFromBlock, uint256 index);

    /// @notice Emitted when a token is unstaked.
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 blockNumber);

    /// @notice Emitted when a token is unstaked in an emergency.
    event EmergencyUnstaked(address indexed user, uint256 indexed tokenId, uint256 blockNumber);

    /// @notice Emitted when a reward is paid out to an address.
    event StakePayout(address indexed staker, uint256 tokenId, uint256 stakeAmount, uint256 fromBlock, uint256 toBlock);

    /// @notice Emitted when the rewards per block are updated.
    /// @dev Value is in Wei.
    event StakeRewardUpdated(uint256 rewardPerBlock);

    /// @notice Requirements related to token ownership.
    /// @param tokenId The current tokenId being staked.
    modifier onlyStaker(uint256 tokenId) {
        // Require that this contract has the token.
        require(utilityToken.ownerOf(tokenId) == address(this), "onlyStaker: Contract is not owner of this NFT");

        // Require that this token is staked.
        require(receipt[tokenId].stakedFromBlock != 0, "onlyStaker: Token is not staked");

        // Require that msg.sender is the owner of this tokenId.
        require(receipt[tokenId].user == msg.sender, "onlyStaker: Caller is not NFT stake owner");

        _;
    }

    /// @notice A requirement to have at least one block pass before staking, unstaking or harvesting.
    /// @param tokenId The tokenId being staked or unstaked.
    modifier requireTimeElapsed(uint256 tokenId) {
        require(
            receipt[tokenId].stakedFromBlock < block.number,
            "requireTimeElapsed: Cannot stake/unstake/harvest in the same block"
        );
        _;
    }

    /// @dev Push needed to avoid index 0 causing bug of index-1.
    constructor() {
        stakeholders.push();
    }

    /// @dev Required implementation to support safeTransfers from ERC721 asset contracts.
    function onERC721Received (
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "No sending tokens directly to staking contract");
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Accepts a tokenId to perform staking.
    /// @param tokenId The tokenId to be staked.
    function stakeUtilityToken(uint256 tokenId) external nonReentrant {
        _stakeUtilityToken(tokenId);
    }

    /// @notice Accepts a tokenId to perform unstaking.
    /// @param tokenId The tokenId to be unstaked.
    function unstakeUtilityToken(uint256 tokenId) external nonReentrant {
        _unstakeUtilityToken(tokenId);
    }

    /// @notice Accepts a tokenId to perform emergency unstaking.
    /// @param tokenId The tokenId to be emergency unstaked.
    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        _emergencyUnstake(tokenId);
    }

    /// @notice Allows the contract owner to reclaim ERC20 rewards sent to the contract.
    function reclaimTokens() external onlyOwner {
        someToken.transfer(msg.sender, someToken.balanceOf(address(this)));
    }

    /// @notice Sets the ERC721 contract this staking contract is for.
    /// @param _utilityToken The ERC721 contract address to have its tokenIds staked.
    function setUtilityToken(IERC721 _utilityToken) public onlyOwner {
        utilityToken = _utilityToken;
    }

    /// @notice Sets the ERC20 token used as staking rewards.
    /// @param _someToken The ERC20 token contract that will provide reward tokens.
    function setSomeToken(IERC20 _someToken) public onlyOwner {
        someToken = _someToken;
    }

    /// @notice The amount of reward tokens to be emitted per block.
    /// @dev Expressed in Wei.
    /// @param _tokensPerBlock Value of reward token emissions per block expressed in Wei.
    function setTokensPerBlock(uint256 _tokensPerBlock) public onlyOwner {
        tokensPerBlock = _tokensPerBlock;
        emit StakeRewardUpdated(tokensPerBlock);
    }

    /// @notice Harvesting the ERC20 rewards earned by a staked ERC721 token.
    /// @param tokenId The tokenId of the staked token for which rewards are withdrawn.
    function harvest(uint256 tokenId)
        public
        nonReentrant
        onlyStaker(tokenId)
        requireTimeElapsed(tokenId)
    {
        _payoutStake(tokenId);
        receipt[tokenId].stakedFromBlock = block.number;
    }

    /// @notice Determine the amount of rewards earned by a staked token.
    /// @param tokenId The tokenId of the staked token.
    /// @return The value in Wei of the rewards currently earned by the tokenId.
    function getCurrentStakeEarned(uint256 tokenId) public view returns (uint256) {
        return _getTimeStaked(tokenId).mul(tokensPerBlock);
    }

    /// @notice Determine the contract address of the ERC20 token providing rewards.
    /// @return The contract address of the rewards token.
    function getSomeTokenAddress() public view returns (address) {
        return address(someToken);
    }

    /// @notice Receive a summary of current stakes by a given address.
    /// @param _user The address to receive a summary for.
    /// @return A staking summary for a given address.
    function getStakingSummary(address _user) public view returns (StakingSummary memory) {
        StakingSummary memory summary = StakingSummary(stakeholders[stakes[_user]].addressStakes);
        return summary;
    }

    /// @notice The amount of the rewards token available in the staking contract.
    /// @dev Expressed in Wei.
    /// @return The amount of the ERC20 reward token still available for emissions.
    function getTokenBalance() public view returns (uint256) {
        return someToken.balanceOf(address(this));
    }

    /// @notice Determine the contract address of the ERC721 contract set to collect staking rewards.
    /// @return The contract address of the stakeable ERC721 contract.
    function getUtilityTokenAddress() public view returns (address) {
        return address(utilityToken);
    }

    /// @notice Adds a staker to the stakeholders array.
    /// @param staker An address that is staking an ERC721 token.
    /// @return The index of the address within the array of stakeholders.
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the array to make space the new stakeholder.
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1.
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index.
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders.
        stakes[staker] = userIndex;
        return userIndex;
    }

    /// @notice Stakes the given ERC721 tokenId to provide ERC20 rewards.
    /// @param tokenId The tokenId to be staked.
    /// @return A boolean indicating whether the staking was completed.
    function _stakeUtilityToken(uint256 tokenId) internal returns (bool) {
        // Check for sending address of the tokenId in the current stakes.
        uint256 index = stakes[msg.sender];
        // Fulfil condition based on whether staker already has a staked index or not.
        if (index == 0) {
            // The stakeholder is taking for the first time and needs to mapped into the index of stakers.
            // The index returned will be the index of the stakeholder in the stakeholders array.
            index = _addStakeholder(msg.sender);
        }

        // Use the index value of the staker to add a new stake.
        stakeholders[index].addressStakes.push(Stake(msg.sender, tokenId, block.number));

        // Require that the tokenId is not already staked.
        require(receipt[tokenId].stakedFromBlock == 0, "Stake: Token is already staked");

        // Required that the tokenId is not already owned by this contract as a result of staking.
        require(utilityToken.ownerOf(tokenId) != address(this), "Stake: Token is already staked in this contract");

        // Transer the ERC721 token to this contract for staking.
        utilityToken.transferFrom(_msgSender(), address(this), tokenId);

        // Check that this contract is the owner.
        require(utilityToken.ownerOf(tokenId) == address(this), "Stake: Failed to take possession of NFT");

        // Start the staking from this block.
        receipt[tokenId].user = msg.sender;
        receipt[tokenId].tokenId = tokenId;
        receipt[tokenId].stakedFromBlock = block.number;

        emit Staked(msg.sender, tokenId, block.number, index);

        return true;
    }

    /// @notice Unstakes the given ERC721 tokenId and claims ERC20 rewards.
    /// @param tokenId The tokenId to be unstaked.
    /// @return A boolean indicating whether the unstaking was completed.
    function _unstakeUtilityToken(uint256 tokenId)
        internal
        onlyStaker(tokenId)
        requireTimeElapsed(tokenId)
        returns (bool)
    {
        // Payout the rewards collected as a result of staking.
        _payoutStake(tokenId);

        // Delete the receipt of the given tokenId.
        delete receipt[tokenId];

        // Transfer the tokenId away from the staking contract back to the ERC721 contract.
        utilityToken.safeTransferFrom(address(this), _msgSender(), tokenId);

        // Determine the index of the tokenId to be unstaked from list of stakes by an address.
        uint256 userIndex = stakes[msg.sender];
        Stake[] memory currentStakeList = stakeholders[userIndex].addressStakes;
        uint256 stakedItemsLength = currentStakeList.length;
        uint256 unstakedTokenIdx;

        for (uint256 i = 0; i < stakedItemsLength; i++) {
            Stake memory stake = currentStakeList[i];
            if (stake.tokenId == tokenId) {
                unstakedTokenIdx = i;
            }
        }

        // Use the determined index of the tokenId to pop the Stake values of the tokenId.
        Stake memory lastStake = currentStakeList[currentStakeList.length - 1];
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].user = lastStake.user;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].tokenId = lastStake.tokenId;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].stakedFromBlock = lastStake.stakedFromBlock;
        stakeholders[userIndex].addressStakes.pop();

        emit Unstaked(msg.sender, tokenId, block.number);

        return true;
    }

    /// @notice Emergency unstakes the given ERC721 tokenId and does not claim ERC20 rewards.
    /// @param tokenId The tokenId to be emergency unstaked.
    /// @return A boolean indicating whether the emergency unstaking was completed.
    function _emergencyUnstake(uint256 tokenId)
        internal
        onlyStaker(tokenId)
        returns (bool)
    {

        // Delete the receipt of the given tokenId.
        delete receipt[tokenId];

        // Transfer the tokenId away from the staking contract back to the ERC721 contract.
        utilityToken.safeTransferFrom(address(this), _msgSender(), tokenId);

        // Determine the index of the tokenId to be unstaked from list of stakes by an address.
        uint256 userIndex = stakes[msg.sender];
        Stake[] memory currentStakeList = stakeholders[userIndex].addressStakes;
        uint256 stakedItemsLength = currentStakeList.length;
        uint256 unstakedTokenIdx;

        for (uint256 i = 0; i < stakedItemsLength; i++) {
            Stake memory stake = currentStakeList[i];
            if (stake.tokenId == tokenId) {
                unstakedTokenIdx = i;
            }
        }

        // Use the determined index of the tokenId to pop the Stake values of the tokenId.
        Stake memory lastStake = currentStakeList[currentStakeList.length - 1];
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].user = lastStake.user;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].tokenId = lastStake.tokenId;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].stakedFromBlock = lastStake.stakedFromBlock;
        stakeholders[userIndex].addressStakes.pop();

        emit EmergencyUnstaked(msg.sender, tokenId, block.number);

        return true;
    }

    /// @notice Calculates and transfers earned rewards for a given tokenId.
    /// @param tokenId The tokenId for which rewards are to be calculated and paid out.
    function _payoutStake(uint256 tokenId) internal {
        /* NOTE : Must be called from non-reentrant function to be safe!*/

        // Double check that the receipt exists and that staking is beginning from block 0.
        require(receipt[tokenId].stakedFromBlock > 0, "_payoutStake: No staking from block 0");

        // Remove the transaction block of withdrawal from time staked.
        uint256 timeStaked = _getTimeStaked(tokenId).sub(1); // don't pay for the tx block of withdrawl

        uint256 payout = timeStaked.mul(tokensPerBlock);

        // If the staking contract does not have any ERC20 rewards left, return the ERC721 token without payment.
        // This prevents any type of ERC721 locking.
        if (someToken.balanceOf(address(this)) < payout) {
            emit StakePayout(msg.sender, tokenId, 0, receipt[tokenId].stakedFromBlock, block.number);
            return;
        }

        // Payout the earned rewards.
        someToken.transfer(receipt[tokenId].user, payout);

        emit StakePayout(msg.sender, tokenId, payout, receipt[tokenId].stakedFromBlock, block.number);
    }

    /// @notice Determine the number of blocks for which a given tokenId has been staked.
    /// @param tokenId The staked tokenId.
    /// @return The integer value indicating the difference the current block and the initial staking block.
    function _getTimeStaked(uint256 tokenId) internal view returns (uint256) {
        if (receipt[tokenId].stakedFromBlock == 0) {
            return 0;
        }
        return block.number.sub(receipt[tokenId].stakedFromBlock);
    }

}