// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract HeroEscrowV2 is ERC165Upgradeable, IERC721ReceiverUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    struct HeroInfo {
        uint16 level;           // DEPRECATED, use migratedHeroLevels instead
        address owner;          // staked to, otherwise owner == 0
        uint16 deposit;         // Needed for rental functions in the future
        uint16 rentalPerDay;    // Needed for rental functions in the future
        uint16 minRentDays;     // Needed for rental functions in the future
        uint32 rentableUntil;   // Needed for rental functions in the future
    }

    struct RewardsPerlevel {
        uint32 totalLevel;
        uint96 accumulated;
        uint32 lastUpdated;
        uint96 rate;
    }

    struct UserRewards {
        uint32 stakedLevel;
        uint96 accumulated;
        uint96 checkpoint;
    }

    using SafeCastUpgradeable for uint;
    using ECDSAUpgradeable for bytes32;

    IERC20 WRLD_ERC20_ADDR;
    IERC721 HERO_ERC721;
    HeroInfo[5555] private heroInfo;
    RewardsPerlevel public rewardsPerlevel;     
    mapping (address => UserRewards) public rewards;
    mapping (address => uint[]) public stakedHeroes;
    address private signer;

    event HeroStaked(uint256 indexed tokenId, address indexed user);
    event HeroUnstaked(uint256 indexed tokenId, address indexed user);

    event RewardsSet(uint256 rate);
    event RewardClaimed(address receiver, uint256 claimed);

    bool[5555] private isHeroLevelMigrated;
    uint32[5555] private migratedHeroLevels;

    // ======== Admin functions ========
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address wrld, address herogalaxy) initializer public {
        __ERC165_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        require(wrld != address(0), "E0"); // E0: addr err
        require(herogalaxy != address(0), "E0");
        WRLD_ERC20_ADDR = IERC20(wrld);
        HERO_ERC721 = IERC721(herogalaxy);
    }

    // Set staking rewards
    function setRewards(uint96 rate) external virtual onlyOwner {
        // ~0.5 avg WRLD per hour for 5555 stakers is ~.771 ether per second (.5 * 5555 / 3600)
        // ~0.2 avg WRLD per hour for 5555 stakers is .3086 ether per second (.2 * 5555 / 3600)
        require(rate < 10 ether, "E1"); // E1: Rate incorrect

        _updateRewardsPerlevel(0, false);
        rewardsPerlevel.rate = rate;

        emit RewardsSet(rate);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    // ======== Public functions ========
    // Stake a hero with given item levels. 
    // @tokenIds - Array of token ids corresponding to ERC721 Hero
    // @levels - Array of hero levels for each token id
    // @stakeTo - Optionally stakeTo a different address (only allows unstaking from the stakeTo address)
    // Rest are rental functions, pass in 0 until we work with NFTWorlds to verify ownership from rental contract
    function stake(uint[] calldata tokenIds, uint[] calldata levels, address stakeTo, uint32 _maxTimestamp, bytes calldata _signature) 
        external virtual nonReentrant {
        require(tokenIds.length == levels.length, "E2"); // E2: Input length mismatch
        require(block.timestamp <= _maxTimestamp, "E3"); // E3: Signature expired
        require(_verifySignerSignature(keccak256(
            abi.encode(tokenIds, levels, msg.sender, _maxTimestamp, address(this))), _signature), "E7"); // E7: Invalid signature
        _ensureEOAorERC721Receiver(stakeTo);
        require(stakeTo != address(this), "E4"); // E4: Cannot stake to escrow

        uint totalLevels = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            {
                uint tokenId = tokenIds[i];
                require(HERO_ERC721.ownerOf(tokenId) == msg.sender, "E5"); // E5: Not your hero
                HERO_ERC721.safeTransferFrom(msg.sender, address(this), tokenId); 

                emit HeroStaked(tokenId, stakeTo); 
            }

            isHeroLevelMigrated[tokenIds[i]] = true;
            migratedHeroLevels[tokenIds[i]] = levels[i].toUint32();
            
            heroInfo[tokenIds[i]] = HeroInfo(0, stakeTo, 0, 0, 0, 0);

            totalLevels += levels[i];
        }
        // update rewards
        _updateRewardsPerlevel(totalLevels.toUint32(), true);
        _updateUserRewards(stakeTo, totalLevels.toUint32(), true);
    }

    function unstake(uint[] calldata tokenIds, address unstakeTo) external virtual nonReentrant {
        // ensure unstakeTo is EOA or ERC721Receiver to avoid token lockup
        _ensureEOAorERC721Receiver(unstakeTo);
        require(unstakeTo != address(this), "ES"); // E4: Cannot unstake to escrow

        uint totalLevels = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            require(heroInfo[tokenId].owner == msg.sender, "E5"); // E9: Not your hero
            HERO_ERC721.safeTransferFrom(address(this), unstakeTo, tokenId);

            uint32 _level;
            if (isHeroLevelMigrated[tokenId]) {
                _level = migratedHeroLevels[tokenId];
            } else {
                _level = heroInfo[tokenId].level;
            }

            totalLevels += _level;

            migratedHeroLevels[tokenId] = 0;
            heroInfo[tokenId] = HeroInfo(0,address(0), 0, 0, 0, 0);

            emit HeroUnstaked(tokenId, msg.sender);
        }
        // update rewards
        _updateRewardsPerlevel(totalLevels.toUint32(), false);
        _updateUserRewards(msg.sender, totalLevels.toUint32(), false);
    }

    // Claim all rewards from caller into a given address
    function claim(address to) external virtual {
        _updateRewardsPerlevel(0, false);
        uint rewardAmount = _updateUserRewards(msg.sender, 0, false);
        rewards[msg.sender].accumulated = 0;
        WRLD_ERC20_ADDR.transfer(to, rewardAmount);
        emit RewardClaimed(to, rewardAmount);
    }

    function updateRent(uint[] calldata tokenIds, 
        uint16 _deposit, uint16 _rentalPerDay, uint16 _minRentDays, uint32 _rentableUntil) 
        external virtual {
    }

    // Extend rental period of ongoing rent
    function extendRentalPeriod(uint tokenId, uint32 _rentableUntil) external virtual {
    }

    // ======== View only functions ========

    function getHeroInfo(uint tokenId) external view returns(HeroInfo memory) {
        return heroInfo[tokenId];
    }

    function getHeroLevel(uint tokenId) external view returns(uint32 level) {
        if (isHeroLevelMigrated[tokenId]) {
            return migratedHeroLevels[tokenId];
        } else {
            return heroInfo[tokenId].level;
        }
    }

    function getAllHeroesInfo() external view returns(HeroInfo[5555] memory) {
        return heroInfo;
    }

    function checkUserRewards(address user) external virtual view returns(uint) {
        RewardsPerlevel memory rewardsPerLevel_ = rewardsPerlevel;
        UserRewards memory userRewards_ = rewards[user];

        // Find out the unaccounted time
        uint32 end = block.timestamp.toUint32();
        uint256 unaccountedTime = end - rewardsPerLevel_.lastUpdated; // Cast to uint256 to avoid overflows later on
        if (unaccountedTime != 0) {

            // Calculate and update the new value of the accumulator. unaccountedTime casts it into uint256, which is desired.
            // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
            if (rewardsPerLevel_.totalLevel != 0) {
                rewardsPerLevel_.accumulated = (rewardsPerLevel_.accumulated + unaccountedTime * rewardsPerLevel_.rate / rewardsPerLevel_.totalLevel).toUint96();
            }
        }
        // Calculate and update the new value user reserves. userRewards_.stakedLevel casts it into uint256, which is desired.
        return userRewards_.accumulated + userRewards_.stakedLevel * (rewardsPerLevel_.accumulated - userRewards_.checkpoint);
    }

    // ======== internal functions ========

    function _verifySignerSignature(bytes32 hash, bytes calldata signature) internal view returns(bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }


    // Needs to be called on each staking/unstaking event.
    function _updateRewardsPerlevel(uint32 level, bool increase) internal virtual {
        RewardsPerlevel memory rewardsPerLevel_ = rewardsPerlevel;
        // Find out the unaccounted time
        uint32 end = block.timestamp.toUint32();
        uint256 unaccountedTime = end - rewardsPerLevel_.lastUpdated; // Cast to uint256 to avoid overflows later on
        if (unaccountedTime != 0) {

            // Calculate and update the new value of the accumulator.
            // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
            if (rewardsPerLevel_.totalLevel != 0) {
                rewardsPerLevel_.accumulated = (rewardsPerLevel_.accumulated + unaccountedTime * rewardsPerLevel_.rate / rewardsPerLevel_.totalLevel).toUint96();
            }
            rewardsPerLevel_.lastUpdated = end;
        }
        
        if (increase) {
            rewardsPerLevel_.totalLevel += level;
        }
        else {
            rewardsPerLevel_.totalLevel -= level;
        }
        rewardsPerlevel = rewardsPerLevel_;
    }

    // Accumulate rewards for an user.
    // Needs to be called on each staking/unstaking event.
    function _updateUserRewards(address user, uint32 level, bool increase) internal virtual returns (uint96) {
        UserRewards memory userRewards_ = rewards[user];
        RewardsPerlevel memory rewardsPerLevel_ = rewardsPerlevel;
        
        // Calculate and update the new value user reserves.
        userRewards_.accumulated = userRewards_.accumulated + userRewards_.stakedLevel * (rewardsPerLevel_.accumulated - userRewards_.checkpoint);
        userRewards_.checkpoint = rewardsPerLevel_.accumulated;    
        
        if (level != 0) {
            if (increase) {
                userRewards_.stakedLevel += level;
            }
            else {
                userRewards_.stakedLevel -= level;
            }
        }
        rewards[user] = userRewards_;

        return userRewards_.accumulated;
    }

    function _ensureEOAorERC721Receiver(address to) internal virtual {
        uint32 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(address(this), address(this), 1, "") returns (bytes4 retval) {
                require(retval == IERC721ReceiverUpgradeable.onERC721Received.selector, "ET"); // ET: neither EOA nor ERC721Receiver
            } catch (bytes memory) {
                revert("ET"); // ET: neither EOA nor ERC721Receiver
            }
        }
    }


    // ======== function overrides ========
    // Prevent sending ERC721 tokens directly to this contract
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4) {
        from; tokenId; data; // supress solidity warnings
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        }
        else {
            return 0x00000000;
        }
    }

    function increment() public onlyOwner {
    }
}