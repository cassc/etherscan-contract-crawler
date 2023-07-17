// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IAKCCoreMultiStakeExtension.sol";
import "./interfaces/IAKCTribeManagerUpgradeable.sol";
import "./interfaces/IAKCCoinV2.sol";
import "./interfaces/IAKCCore.sol";

/**
 * @dev Extension of AKCTribeManagerUpgradeable
 * Allows for Reward Claiming and a cheaper AKC Multiple Unstaking,
 * in cases where a User has a large number of tribes.
 */
contract AKCTribeExtensionUpgradeable is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IERC721 public akcNFT;
    IAKCCore public akcCore;
    IAKCCoinV2 public akcCoin;
    IAKCTribeManagerUpgradeable public manager;
    IAKCCoreMultiStakeExtension public akcCoreMultiStakeExtension;

    mapping(address => bool) public hasDisabledRewards;
    mapping(address => uint256) public userClaimedRewards;
    mapping(address => mapping(uint256 => bool)) public hasUnstakedKong;

    /**
     * === Core Events ===
     */
    event ClaimAllRewardsOfUser(address indexed user, uint256 indexed amount);
    event WithdrawStuckAKC(address indexed receiver, uint256[] indexed akcIds);

    constructor(address _akc, address _manager, address _akcCoin, address _akcCore, address _akcCoreMultiStake) {}

    function initialize(address _akc, address _manager, address _akcCoin, address _akcCore, address _akcCoreMultiStake)
        public
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();

        akcNFT = IERC721(_akc);
        akcCore = IAKCCore(_akcCore);
        akcCoin = IAKCCoinV2(_akcCoin);
        manager = IAKCTribeManagerUpgradeable(_manager);
        akcCoreMultiStakeExtension = IAKCCoreMultiStakeExtension(_akcCoreMultiStake);
    }

    /**
     * === Stake Logic ===
     */

    /*
    * @param akcIds List of AKC Kong IDs 
    *
    * @notice This function withdraws Stuck Kongs from AKCMultiStakeExtension's
    * contract with lower gas fees. Should be used in cases where BatchUnstaking
    * of these kongs is Expensive.
    * 
    * @custom:WARNING This function disables All reward claiming from User 
    * So, if a user is planning to also Claim his rewards, he should do so before 
    * calling this function, as it would result in rewards being blocked. 
    */
    function withdrawStuckKongs(uint256[] calldata akcIds) external nonReentrant {
        require(akcIds.length > 1, "Batch stake must be more than one kong");

        for (uint256 i = 0; i < akcIds.length; i++) {
            uint256 akcId = akcIds[i];

            require(!hasUnstakedKong[msg.sender][akcId], "Staker has already unstaked this Kong");
            require(akcNFT.ownerOf(akcId) == address(akcCoreMultiStakeExtension), "AKC CORE NOT OWNER OF NFT");
            require(
                akcNFT.isApprovedForAll(address(akcCoreMultiStakeExtension), address(this)),
                "EXTENSION NOT APPROVED FOR CORE"
            );
            akcNFT.transferFrom(address(akcCoreMultiStakeExtension), msg.sender, akcId);

            uint256 kongStakeData = akcCoreMultiStakeExtension.kongToStaker(akcId);
            address kongStakeStaker = _getAddressFromKongStakeData(kongStakeData);

            require(kongStakeStaker == msg.sender, "Kong not owned by staker");
            require(akcNFT.ownerOf(akcId) == msg.sender, "Kong not transfered to staker");

            hasUnstakedKong[msg.sender][akcId] = true;
        }

        hasDisabledRewards[msg.sender] = true;
        emit WithdrawStuckAKC(msg.sender, akcIds);
    }

    /**
     * === Reward Claiming ===
     */

    /*
    * @notice This function claims rewards generated from the AKC Ecossystem
    * 
    * @custom:warning The rewards claimed from this function become inactive
    * for a User if he calls withdrawStuckKongs function
    */
    function claimAllRewardsOfUser() external nonReentrant {
        require(!hasDisabledRewards[msg.sender], "User has disabled rewards after calling WithdrawStuckKongs function.");

        uint256 amount = _getStakerRewards(msg.sender);
        userClaimedRewards[msg.sender] += amount;

        amount = amount < manager.userToDebt(msg.sender) ? 0 : amount - manager.userToDebt(msg.sender);
        require(amount > 0, "NO REWARD AVAILABLE");

        akcCoin.mint(amount, msg.sender);
        emit ClaimAllRewardsOfUser(msg.sender, amount);
    }

    /**
     * === Reward Data Retrieval ===
     */

    /*
    * @notice This function calculates the rewards generated from the AKC Ecossystem
    * 
    * @custom:warning The rewards claimed from this function become inactive
    * for a User if he calls withdrawStuckKongs function
    */
    function getTotalClaimableReward(address user) public view returns (uint256 amount) {
        if (!hasDisabledRewards[user]) {
            amount = _getStakerRewards(user);
            amount = amount < manager.userToDebt(user) ? 0 : amount - manager.userToDebt(user);
        }
        return amount;
    }

    function _getStakerRewards(address user) internal view returns (uint256 amount) {
        // Add capsule reward
        uint256 capsuleStakeData = akcCoreMultiStakeExtension.userToStakeData(user, 257);
        amount += akcCoreMultiStakeExtension.getBonus(user, 257)
            + akcCoreMultiStakeExtension.getStakePendingBonusFromStakeData(capsuleStakeData);

        // Add tribe rewards and old capsule reward
        if (akcCore.getTribeAmount(user) > 0 || akcCore.userToAKC(user, 257) != 0) {
            amount += akcCore.getAllRewards(user);
        }

        uint256 totalStakeBonus;
        // Get rewards from staking
        for (uint256 i = 0; i < akcCore.getTribeSpecAmount(); i++) {
            uint256 tribeStakeData = akcCoreMultiStakeExtension.userToStakeData(user, i);
            uint256 tribeReward = akcCoreMultiStakeExtension.getBonus(user, i)
                + akcCoreMultiStakeExtension.getStakePendingBonusFromStakeData(tribeStakeData);
            totalStakeBonus += tribeReward;
        }

        amount = amount + totalStakeBonus - userClaimedRewards[user];

        return amount;
    }

    /**
     * === Stake Data Retrieval ===
     */

    function _getAddressFromKongStakeData(uint256 kongStakeData) internal pure returns (address) {
        return address(uint160(kongStakeData));
    }

    function _getSpecFromKongStakeData(uint256 kongStakeData) internal pure returns (uint256) {
        return uint256(uint96(kongStakeData >> 160));
    }

    function _getKongStakeData(address staker, uint256 spec) internal pure returns (uint256) {
        uint256 kongStakeData = uint256(uint160(staker));
        kongStakeData |= spec << 160;
        return kongStakeData;
    }

    /**
     * === ONLY OWNER ===
     */

    function setTribeManager(address newManager) external onlyOwner {
        manager = IAKCTribeManagerUpgradeable(newManager);
    }

    function setAKCCoin(address v2) external onlyOwner {
        akcCoin = IAKCCoinV2(v2);
    }

    receive() external payable {}
}