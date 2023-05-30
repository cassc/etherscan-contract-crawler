// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CitadelExordium is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint8;

    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;

    struct TechTree {
        uint8 tech;
        uint8 techLevels; // 0 => 7, 1 => 9, 2 => 9, 3 => 7, 4 => 7, 5 => 3, 6 => 6, 7 => 5, 53 total
        uint256 researchCompleted;
        bool hasRelik;
    }

    uint256 private researchPerLevel = 7000000000000000000000000; //7M
    mapping(uint256 => TechTree) techTree; //0-7 annexation, 8-15 autonomous zone, 16-23 sanction, 24-31 network state

    // distribute 2.4 billion $drakma over 150 days pregame =>704,000 per hour
    struct Staker {
        uint256 amountStaked; // Sum of CITADEL staked * multiple
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint8 techIndex;
        bool hasTech;
    }

    // Rewards are cumulated once every hour. Unit wei
    uint256 private rewardsPerHour = 166000000000000000000; //166 DK base / hr
    uint256 public periodFinish = 1674943200; //JAN 28 2023, 2PM PT 
    
    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;

    uint8[] public sektMultiple = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,4,4,2,2,4,2,4,2,4,8,2,2,2,4,2,4,4,2,4,4,2,4,8,4,2,2,2,2,2,2,8,8,2,4,8,8,2,2,2,4,4,2,4,2,8,4,4,4,2,8,2,4,2,4,4,8,4,2,2,2,2,2,4,8,2,4,4,2,2,2,2,8,4,4,8,2,2,2,4,8,2,2,2,4,8,4,2,2,2,2,4,2,4,2,4,2,4,2,2,2,4,4,2,2,2,2,2,2,2,4,2,2,2,8,2,2,2,4,4,4,4,4,4,2,2,4,4,8,2,2,2,2,4,2,2,2,2,2,2,2,2,2,8,2,4,2,2,4,2,2,8,2,2,2,2,4,4,2,4,2,2,2,4,2,2,8,8,2,4,2,4,2,2,2,2,4,2,4,4,4,8,2,4,4,2,4,4,4,2,2,2,2,2,4,4,4,2,4,8,2,4,2,4,2,4,2,2,8,4,4,4,2,4,2,8,2,8,2,8,2,4,2,4,4,8,4,2,2,2,2,8,4,4,2,8,2,4,2,2,4,2,8,2,2,2,4,2,4,2,8,2,4,2,2,8,8,4,2,2,2,8,2,8,2,2,2,2,4,8,2,2,2,2,2,2,2,2,8,4,2,2,2,2,2,2,2,2,2,4,2,4,2,2,2,4,2,2,2,8,8,4,2,2,4,2,4,4,2,2,2,2,2,4,2,8,4,2,4,4,2,2,2,2,2,2,2,2,4,2,2,4,4,4,2,2,2,4,2,8,2,2,2,4,2,2,4,2,8,2,4,2,2,2,4,2,8,2,2,2,2,8,2,2,4,2,2,2,2,2,4,2,8,4,2,2,2,4,2,8,4,8,2,2,4,2,2,2,4,2,2,2,2,4,4,8,2,2,2,4,4,2,4,4,2,2,2,2,2,2,8,4,2,4,8,2,2,4,2,4,2,2,2,8,2,2,8,2,2,2,2,2,2,4,2,4,4,4,8,2,2,2,8,2,2,2,2,2,2,2,4,2,2,8,8,2,2,2,2,8,2,4,2,4,4,2,8,2,2,2,2,2,8,2,2,2,4,2,2,2,4,4,2,2,2,8,2,4,4,2,2,8,2,2,2,2,2,2,2,2,4,2,2,2,8,4,2,2,4,2,4,4,8,2,2,4,2,2,2,4,4,4,2,2,4,2,8,2,2,4,2,4,4,2,2,8,2,2,2,8,2,8,2,2,2,2,4,8,2,8,4,4,2,8,2,2,2,4,2,2,2,4,4,2,2,2,2,2,4,2,8,2,4,4,2,2,8,4,2,2,2,2,2,2,2,2,4,2,2,4,2,8,2,2,4,8,4,2,2,2,8,8,2,4,4,4,4,4,4,2,4,2,2,4,2,2,4,8,2,8,2,2,2,2,2,4,2,2,8,2,8,4,2,4,4,2,2,2,4,2,2,2,8,2,8,8,2,2,2,8,2,2,8,2,2,4,2,4,2,8,8,2,8,2,2,4,8,8,8,2,2,2,4,8,2,2,2,2,4,4,2,2,8,2,4,4,4,8,2,2,4,2,4,2,4,2,8,2,2,2,2,2,2,2,2,8,2,2,2,8,2,8,2,2,2,8,8,8,2,8,4,4,2,4,2,2,4,4,8,2,2,4,2,2,8,2,8,2,2,2,4,4,4,2,4,2,8,8,2,2,4,4,2,8,8,2,2,2,8,8,4,4,2,2,4,2,2,4,4,4,2,8,4,2,8,2,2,2,2,4,2,4,4,2,4,4,2,2,2,2,2,2,8,2,2,2,2,2,4,2,4,2,2,2,2,2,2,8,2,8,8,2,8,2,2,2,8,4,2,2,4,8,2,2,8,2,2,4,2,2,2,2,2,4,8,2,2,4,2,4,8,8,4,4,2,2,2,2,4,2,2,2,2,2,2,2,4,2,2,8,2,2,2,2,4,2,4,2,4,4,2,2,2,2,2,2,4,2,2,2,4,2,2,2,2,2,4,2,2,2,2,2,2,4,2,8,2,2,2,8,4,2,2,4,2,2,4,2,2,2,8,2,2,4,4,2,2,2,2,2,2,2,4,2,2,2,4,2,4,2,2,2,4,4,4,2,2,2,2,2,2,4,2,4,4,2,2,2,4,2,2,4,4,4,4,4,2,2,2,2,2];
    uint8[] public techProp = [0,1,4,0,5,2,0,0,0,0,0,3,1,4,0,0,0,0,6,0,3,2,7,3,4,0,1,0,6,4,2,2,7,3,6,6,1,7,5,0,1,0,0,0,3,1,5,1,3,5,4,6,0,1,0,0,2,7,2,0,0,0,0,1,0,1,1,0,0,2,1,0,2,0,3,2,0,0,0,0,0,2,0,1,0,7,1,0,3,0,0,2,3,4,4,0,0,1,0,1,0,0,2,7,0,1,2,1,1,2,0,0,0,0,0,3,1,0,4,3,3,4,1,1,1,1,1,1,0,0,5,1,3,0,0,1,1,2,1,1,0,0,1,3,5,0,1,0,0,2,0,0,0,1,3,0,0,0,7,1,0,0,2,0,0,1,2,0,1,3,0,1,2,2,0,7,2,0,4,2,1,1,1,3,0,1,0,0,0,0,1,0,1,0,0,2,1,2,0,1,0,4,0,0,1,0,0,1,1,0,1,0,5,2,0,4,1,2,0,0,1,1,2,2,0,0,0,0,0,0,1,2,0,1,0,0,0,0,0,0,0,2,0,2,0,0,0,4,2,1,0,0,1,0,1,0,0,0,3,1,0,0,1,3,0,0,0,1,0,2,0,0,3,0,0,0,1,0,0,1,4,1,0,0,0,0,3,0,5,1,0,0,0,1,2,3,1,2,2,0,1,0,0,2,0,1,0,1,1,2,1,0,0,0,1,0,2,2,0,1,2,1,4,3,0,0,0,0,0,3,0,0,0,0,0,0,2,0,1,1,0,0,1,1,3,1,4,1,1,0,1,1,0,0,2,0,0,0,1,0,2,0,0,1,1,1,0,0,2,2,6,0,0,6,2,5,0,0,0,0,1,1,0,2,1,1,0,0,0,3,3,1,1,1,0,2,1,4,0,0,4,0,0,2,1,0,1,0,1,0,2,0,2,1,1,1,2,0,0,0,1,0,0,0,2,0,0,0,1,0,1,4,2,0,0,1,0,3,0,0,0,3,1,1,0,0,0,0,0,0,0,0,1,3,3,1,1,0,0,1,0,0,0,0,1,0,0,4,0,1,0,0,0,1,0,0,1,2,1,1,2,0,0,1,0,0,2,0,1,1,2,1,1,2,1,0,1,1,0,2,0,0,2,0,0,0,2,0,0,0,1,2,1,1,0,1,0,1,0,1,0,4,1,1,0,1,4,6,0,0,2,1,2,2,3,0,1,2,0,2,0,0,0,0,1,2,2,0,1,0,2,0,0,1,2,0,0,1,1,1,0,0,0,0,0,2,0,0,0,0,0,4,2,0,1,0,2,0,0,0,0,2,0,0,0,4,0,0,0,0,1,0,0,0,1,0,1,4,0,0,5,1,1,1,1,0,0,1,0,1,2,0,1,0,0,1,0,0,3,0,0,0,2,0,2,2,3,1,2,0,4,0,0,1,0,0,1,1,0,2,2,2,0,0,1,0,1,0,1,0,1,0,2,1,0,0,3,0,0,1,0,4,1,2,0,2,2,1,1,0,0,0,2,2,1,3,4,0,0,0,0,2,2,0,0,2,0,4,0,1,0,0,1,2,2,0,0,0,0,0,1,0,0,5,0,0,0,0,1,1,1,0,0,0,2,3,1,0,2,3,0,1,0,0,1,1,0,1,1,0,0,0,1,1,3,1,0,1,1,4,0,3,3,1,1,1,2,0,0,2,0,0,1,1,1,1,2,0,0,0,4,5,1,0,0,1,2,0,1,2,0,0,1,0,0,0,0,2,1,0,1,0,1,1,3,2,3,5,5,0,2,1,0,4,2,2,0,0,1,0,0,1,0,0,1,0,0,0,1,0,2,1,0,0,0,1,1,0,2,0,1,2,0,0,1,0,0,0,3,0,1,0,3,0,0,0,0,1,2,2,0,0,0,0,2,0,0,0,1,0,0,0,0,1,1,0,0,0,1,1,1,0,0,1,0,1,2,0,0,3,1,2,1,3,0,0,2,3,2,2,0,0,2,1,0,1,3,0,2,0,3,1,1,1,1,0,0,0,1,2,0,0,0,0,0,0,1,1,0,0,5,0,0,0,1,0,1,0,0,1,1,2,0,0,0,0,3,0,1,0,3,2,0,0,0,1,0,0,1,0,1,0,0,0,0,0,0,2,0,3,0,1,0,0,0,1,2,1,0,0,1,2,0,0,0,0,0,0,1,1,0,3,3,0,0,1,1,1,0,3,2,0,0,0,1,0,0,3,0,0,1,0,0,0,3,1,1,0,1,3,0,0,1,3,0,0,0,0,0,0,0,0,0,0,0,3,3,3,3,0,1,0,5,0];


    constructor(IERC721 _citadelCollection, IERC20 _drakma) {
        citadelCollection = _citadelCollection;
        drakma = _drakma;
        //annexation
        techTree[0] = TechTree(0,7,0,false);
        techTree[1] = TechTree(1,9,0,false);
        techTree[2] = TechTree(2,9,0,false);
        techTree[3] = TechTree(3,7,0,false);
        techTree[4] = TechTree(4,7,0,false);
        techTree[5] = TechTree(5,3,0,false);
        techTree[6] = TechTree(6,6,0,false);
        techTree[7] = TechTree(7,5,0,false);
        //autonomous zone
        techTree[8] = TechTree(0,7,0,false);
        techTree[9] = TechTree(1,9,0,false);
        techTree[10] = TechTree(2,9,0,false);
        techTree[11] = TechTree(3,7,0,false);
        techTree[12] = TechTree(4,7,0,false);
        techTree[13] = TechTree(5,3,0,false);
        techTree[14] = TechTree(6,6,0,false);
        techTree[15] = TechTree(7,5,0,false);
        //sanction
        techTree[16] = TechTree(0,7,0,false);
        techTree[17] = TechTree(1,9,0,false);
        techTree[18] = TechTree(2,9,0,false);
        techTree[19] = TechTree(3,7,0,false);
        techTree[20] = TechTree(4,7,0,false);
        techTree[21] = TechTree(5,3,0,false);
        techTree[22] = TechTree(6,6,0,false);
        techTree[23] = TechTree(7,5,0,false);
        //network state
        techTree[24] = TechTree(0,7,0,false);
        techTree[25] = TechTree(1,9,0,false);
        techTree[26] = TechTree(2,9,0,false);
        techTree[27] = TechTree(3,7,0,false);
        techTree[28] = TechTree(4,7,0,false);
        techTree[29] = TechTree(5,3,0,false);
        techTree[30] = TechTree(6,6,0,false);
        techTree[31] = TechTree(7,5,0,false);
    }

    function stake(uint256[] calldata _tokenIds, uint8 techIndex) external nonReentrant {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            stakers[msg.sender].hasTech = false;
        }

        uint256 runningMultiple = 0;
        for (uint256 i; i < _tokenIds.length; ++i) {
            require(
                citadelCollection.ownerOf(_tokenIds[i]) == msg.sender,
                "Can't stake tokens you don't own!"
            );
            citadelCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            uint8 multiple = sektMultiple[_tokenIds[i]];
            uint8 tech = techProp[_tokenIds[i]];
            if(techTree[techIndex].tech == tech) {
                stakers[msg.sender].hasTech = true;
                if(multiple == 16) {
                    techTree[techIndex].hasRelik = true;
                }
            }
            runningMultiple += multiple;
            stakerAddress[_tokenIds[i]] = msg.sender;
        }
        stakers[msg.sender].amountStaked += runningMultiple;
        stakers[msg.sender].timeOfLastUpdate = lastTimeRewardApplicable();
        stakers[msg.sender].techIndex = techIndex;
    }

    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        uint256 runningMultiple = 0;
        for (uint256 i; i < _tokenIds.length; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);
            stakerAddress[_tokenIds[i]] = address(0);
            citadelCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
            runningMultiple += sektMultiple[_tokenIds[i]];
        }
        stakers[msg.sender].hasTech = false;
        stakers[msg.sender].amountStaked -= runningMultiple;
        stakers[msg.sender].timeOfLastUpdate = lastTimeRewardApplicable();
    }


    function claimRewards() external nonReentrant {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = lastTimeRewardApplicable();
        stakers[msg.sender].unclaimedRewards = 0;
        drakma.safeTransfer(msg.sender, rewards);
        
        if(techTree[stakers[msg.sender].techIndex].hasRelik) {
            uint8 techMultiple = stakers[msg.sender].hasTech ? 2 : 1;
            uint256 techRewards = rewards * techMultiple;
            uint256 reseachToComplete = techTree[stakers[msg.sender].techIndex].techLevels * researchPerLevel;
            if (techTree[stakers[msg.sender].techIndex].researchCompleted + techRewards < reseachToComplete) {
                techTree[stakers[msg.sender].techIndex].researchCompleted += techRewards;    
            } else {
                techTree[stakers[msg.sender].techIndex].researchCompleted = reseachToComplete;
            }
        }
    }

    //withdraw leftover DRAKMA when EXORDIUM concludes
    function withdrawDrakma(uint256 amount) external onlyOwner {
        drakma.safeTransfer(msg.sender, amount);
    }
 
    // Views
    function userStakeInfo(address _user)
        public
        view
        returns (uint256 _tokensStaked, uint256 _availableRewards)
    {
        return (stakers[_user].amountStaked, availableRewards(_user));
    }

    function availableRewards(address _user) internal view returns (uint256) {
        uint256 _rewards = stakers[_user].unclaimedRewards +
            calculateRewards(_user);
        return _rewards;
    }

    function getTechTree(uint8 techIndex) public view returns (uint256, bool) {
        return (techTree[techIndex].researchCompleted, techTree[techIndex].hasRelik);
    }

    function getAllTechTree() public view returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](32);
        for (uint i = 0; i < 32; i++) {
            ret[i] = techTree[i].researchCompleted;
        }
        return ret;
    }

    function getCitadelStaker(uint256 tokenId) public view returns (address) {
        return stakerAddress[tokenId];
    }

    function getStaker(address walletAddress) public view returns (uint256, uint256, uint8, bool) {
        return (stakers[walletAddress].amountStaked, stakers[walletAddress].unclaimedRewards, stakers[walletAddress].techIndex, stakers[walletAddress].hasTech);
    }

    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {
        return (((
            ((lastTimeRewardApplicable() - stakers[_staker].timeOfLastUpdate) *
                stakers[msg.sender].amountStaked)
        ) * rewardsPerHour) / 3600);
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }
}