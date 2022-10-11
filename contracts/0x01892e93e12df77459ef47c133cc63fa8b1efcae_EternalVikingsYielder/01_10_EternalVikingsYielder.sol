// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IEternalVikings.sol";
import "../interfaces/IEternalVikingsGoldToken.sol";
import "../interfaces/IEternalVikingsStaking.sol";

contract EternalVikingsYielder is OwnableUpgradeable {
    IEternalVikings public EVNFT;
    IEternalVikingsGoldToken public EVGoldToken;
    IEternalVikingsStaking public EVStakingModule;

    uint256 public baseYield;
    uint256 public yieldPeriod;

    uint256 public decayStart;
    uint256 public decayPeriod;
    uint256 public decaySteps;
    mapping(uint256 => uint256) public decayYields;
    mapping(uint256 => uint256) public decayTimestamps;

    mapping(address => uint256) public walletTransactions;
    mapping(address => uint256) public walletShadowEarnings;

    address public sacrificeModule;

    constructor(
        address ev,
        address gold
    ) {}

    function initialize(
        address ev,
        address gold
    ) public initializer {
        __Ownable_init();
        EVNFT = IEternalVikings(ev);
        EVGoldToken = IEternalVikingsGoldToken(gold);

        baseYield = 10 ether;
        yieldPeriod = 1 days;

        decayStart = block.timestamp;        
        decayPeriod = 4 weeks;
        decaySteps = 6;

        decayYields[0] = 0;
        decayYields[1] = 2.5 ether;
        decayYields[2] = 5 ether;
        decayYields[3] = 8 ether;
        decayYields[4] = 8.5 ether;
        decayYields[5] = 9 ether;

        for (uint i = 0; i < decaySteps; i++) {
            decayTimestamps[i] = block.timestamp + decayPeriod * (i + 1);
        }
    }

    receive() external payable {
        payable(owner()).transfer(address(this).balance);
    }

    function getCurrentShadowEarnings(address user) public view returns (uint256) {
        uint256 stakedVikings = EVStakingModule.walletEVStakeCount(user);
        uint256 lastTxtimestamp = walletTransactions[user];

        if (lastTxtimestamp == 0)
            return 0;

        uint256 shadowEarnings;
        for (uint i = 0; i < decaySteps; i++) {
            uint256 yieldAtLevel = baseYield - decayYields[i];
            uint256 timestampAtLevel = decayTimestamps[i];
            bool isFullPeriod = true;

            if (lastTxtimestamp > timestampAtLevel)
                continue;

            if (block.timestamp - lastTxtimestamp < decayPeriod) {
                if (block.timestamp < timestampAtLevel) {
                    shadowEarnings += (block.timestamp - lastTxtimestamp) * yieldAtLevel * stakedVikings / yieldPeriod;
                    break;
                }
            }
            
            if (timestampAtLevel - lastTxtimestamp < decayPeriod) {
                shadowEarnings += (timestampAtLevel - lastTxtimestamp) * yieldAtLevel * stakedVikings / yieldPeriod;
                isFullPeriod = false;
            }
            
            if (block.timestamp < timestampAtLevel ) {                
                uint256 prevLevel = timestampAtLevel - decayPeriod;
                if (block.timestamp < prevLevel)
                    break;                    
                if (block.timestamp - prevLevel < decayPeriod) {
                    shadowEarnings += (block.timestamp  - prevLevel) * yieldAtLevel * stakedVikings / yieldPeriod;
                    isFullPeriod = false;
                }                
            }
            
            if (isFullPeriod) {
                shadowEarnings += decayPeriod * yieldAtLevel * stakedVikings / yieldPeriod;
            }
        }
        return shadowEarnings;
    }

    function getUserPendingEarnings(address user) external view returns(uint256) {
        uint256 currentShadowEarnings = getCurrentShadowEarnings(user);
        uint256 shadowEarnings = walletShadowEarnings[user];
        return currentShadowEarnings + shadowEarnings;
    }

    function getCurrentEarningsRate() external view returns(uint256) {
        uint256 currentDecayValue = decayYields[decaySteps - 1];
        for (uint i = 0; i < decaySteps; i++) {
            uint256 timestampAtLevel = decayTimestamps[i];
            if (block.timestamp > timestampAtLevel)
                continue;
            
            if (timestampAtLevel - block.timestamp <= decayPeriod)
                currentDecayValue = decayYields[i];
        }

        return baseYield - currentDecayValue;
    }

    function registerShadowEarnings(address user) external {
        require(msg.sender == address(EVStakingModule), "Register: Not Staker");
        require(address(EVStakingModule) != address(0), "Null: Staker");

        uint256 currentShadowEarnings = getCurrentShadowEarnings(user);
        walletShadowEarnings[user] += currentShadowEarnings;
        walletTransactions[user] = block.timestamp;
    }

    function takeGoldReward() external {
        uint256 currentShadowEarnings = getCurrentShadowEarnings(msg.sender);
        uint256 shadowEarnings = walletShadowEarnings[msg.sender];

        delete walletShadowEarnings[msg.sender];
        walletTransactions[msg.sender] = block.timestamp;

        EVGoldToken.reward(msg.sender, currentShadowEarnings + shadowEarnings);
    }

    function rewardGold(address to, uint256 amount) external {
        require(sacrificeModule != address(0));
        require(msg.sender == sacrificeModule);
        EVGoldToken.reward(to, amount);
    }

    function setSacrificer(address sacrificer) external onlyOwner {
        sacrificeModule = sacrificer;
    }

    function setEVNFT(address evNFT) external onlyOwner {
        EVNFT = IEternalVikings(evNFT);
    }

    function setEVGold(address evGold) external onlyOwner {
        EVGoldToken = IEternalVikingsGoldToken(evGold);
    }

    function setStakingModule(address stakingAddress) external onlyOwner {
        EVStakingModule = IEternalVikingsStaking(stakingAddress);
    }

    function setBaseYield(uint256 newYield) external onlyOwner {
        baseYield = newYield;
    }

    function setYieldPeriod(uint256 newPeriod) external onlyOwner {
        yieldPeriod = newPeriod;
    }

    function setDecayStart(uint256 newStart) external onlyOwner {
        decayStart = newStart;
    }

    function setDecayPeriod(uint256 newPeriod) external onlyOwner {
        decayPeriod = newPeriod;
    }

    function setDecaySteps(uint256 newSteps) external onlyOwner {
        decaySteps = newSteps;
    }
}