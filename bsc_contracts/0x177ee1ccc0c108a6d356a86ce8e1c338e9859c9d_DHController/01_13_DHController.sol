// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import '../interfaces/ILevelManager.sol';
import '../interfaces/IDHController.sol';
import '../interfaces/ILaunchpadIDO.sol';

// Only controls registration and share calculation for DH25/DH75.
// Rewards are paid out by DHTreasury, reward amounts are calculated on the server side.
contract DHController is IDHController, Initializable, OwnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    address public levelManager;
    // Pools eligible for DH25/DH75 rewards
    address[] public eligiblePools;
    // Sales to check DH75 eligibility for each user
    address[] public eligibleSales;

    uint256 public registrationPeriod;
    uint256 public claimPeriod;
    // Year-month-day zero-padded numbers (always 1st day of the month): 2021-01-01 -> 20210101, 2023-03-08 -> 20230308
    uint256 public curDistrIdx;

    // Indexed by year-month-day zero-padded numbers (always 1st day of the month). Current is marked by currentDistributionIndex
    mapping(uint256 => Distribution) public distributions;

    event Registered(
        address indexed user,
        uint256 distributionIndex,
        uint256 dh25Share,
        address[] sales,
        uint256[] dh75Shares
    );
    event NewDistribution(uint256 distributionIndex, uint256 start);

    struct Distribution {
        // Unix timestamp
        uint256 start;
        address[] registrants;
        mapping(address => bool) isRegistered;
        // Sum of all registered AAG participants level multipliers
        uint256 totalDH25Share;
        // User -> DH25 share for the current distribution
        mapping(address => uint256) userDH25Share;
        // Total share for DH75, sum of all registered. Sale -> Share
        mapping(address => uint256) totalDH75Shares;
        // User -> Sale -> Share
        mapping(address => mapping(address => uint256)) userDH75Shares;
    }
    
    function initialize(address _levelManager) public initializer {
        levelManager = _levelManager;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        registrationPeriod = 36 hours;
        claimPeriod = 36 hours;
    }
    
    // Gets called every month by a server to start a new distribution.
    // Year-month-day zero-padded numbers (always 1st day of the month): 2021-01-01 -> 20210101, 2023-03-08 -> 20230308
    function setCurrentDistributionIndex(uint256 _currentDistributionIndex, uint256 _start)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(_currentDistributionIndex > 0, 'DHController: invalid distribution index');
        curDistrIdx = _currentDistributionIndex;
        if (_start > 0) {
            distributions[_currentDistributionIndex].start = _start;
        }
        emit NewDistribution(_currentDistributionIndex, _start);
    }

    function setLevelManager(address _levelManager) external onlyOwner {
        levelManager = _levelManager;
    }

    function setEligiblePools(address[] memory _eligiblePools) external onlyOwner {
        eligiblePools = _eligiblePools;
    }

    function setEligibleSales(address[] memory _eligibleSales) external onlyRole(MANAGER_ROLE) {
        eligibleSales = _eligibleSales;
    }

    function setPeriods(uint256 _registrationPeriod, uint256 _claimPeriod) external onlyOwner {
        registrationPeriod = _registrationPeriod;
        claimPeriod = _claimPeriod;
    }

    function isRegistration() public view override returns (bool) {
        Distribution storage distr = distributions[curDistrIdx];
        return distr.start > 0 && block.timestamp > distr.start - registrationPeriod && block.timestamp < distr.start;
    }

    function isClaiming() external view override returns (bool) {
        Distribution storage distr = distributions[curDistrIdx];
        return distr.start > 0 && block.timestamp >= distr.start && block.timestamp < distr.start + claimPeriod;
    }
    
    function getTimeline(uint256 distrIdx) external view override returns (DistributionTimeline memory) {
        uint256 idx = distrIdx == 0 ? curDistrIdx : distrIdx;
        Distribution storage distr = distributions[idx];
        DistributionTimeline memory v;
        v.start = distr.start;
        v.registrationStart = distr.start > 0 ? distr.start - registrationPeriod : 0;
        v.start = distr.start;
        v.end = distr.start + claimPeriod;
        
        return v;
    }
    
    function getUserDHShares(address account) external view override returns (UserDHShare memory) {
        Distribution storage distr = distributions[curDistrIdx];

        UserDHShare memory v;
        v.isRegistered = distr.isRegistered[account];
        v.totalDH25Share = distr.totalDH25Share;
        v.userDH25Share = distr.userDH25Share[account];
        v.sales = eligibleSales;
        v.totalDH75Shares = new uint256[](eligibleSales.length);
        v.userDH75Shares = new uint256[](eligibleSales.length);
        for (uint256 i = 0; i < eligibleSales.length; i++) {
            v.totalDH75Shares[i] = distr.totalDH75Shares[eligibleSales[i]];
            v.userDH75Shares[i] = distr.userDH75Shares[account][eligibleSales[i]];
        }

        return v;
    }
    

    function getTotalShares()
        external
        view
        override
        returns (
            uint256,
            address[] memory,
            uint256[] memory
        )
    {
        Distribution storage distr = distributions[curDistrIdx];
        uint256[] memory totalDH75Shares = new uint256[](eligibleSales.length);
        for (uint256 i = 0; i < eligibleSales.length; i++) {
            totalDH75Shares[i] = distr.totalDH75Shares[eligibleSales[i]];
        }
        return (distr.totalDH25Share, eligibleSales, totalDH75Shares);
    }

    function getRegistrants(uint256 distrIdx) external view override returns (address[] memory) {
        uint256 idx = distrIdx == 0 ? curDistrIdx : distrIdx;
        return distributions[idx].registrants;
    }

    function register() external override {
        Distribution storage distr = distributions[curDistrIdx];
        address account = msg.sender;

        // Check if user is already registered
        require(!distr.isRegistered[account], 'DHController: already registered');

        // Level check
        ILevelManager.Tier memory tier = ILevelManager(levelManager).getUserTier(account);
        require(tier.multiplier > 0, 'DHController: you must have a level to register');

        // Pool check
        bool stakeInEligiblePool = false;
        for (uint256 i = 0; i < eligiblePools.length; i++) {
            if (tier.pool == eligiblePools[i]) {
                stakeInEligiblePool = true;
                break;
            }
        }
        require(stakeInEligiblePool, 'DHController: the pool where you stake a level is not eligible for DH rewards');

        // Check if registration is open
        require(isRegistration(), 'DHController: registration is closed');

        distr.isRegistered[account] = true;
        distr.registrants.push(account);
        
        bool hasReward = false;

        // DH25 share calculation. Can get DH25 only if staking in the eligible pool and has an AAG level
        if (tier.aag) {
            distr.totalDH25Share += tier.multiplier;
            distr.userDH25Share[account] = tier.multiplier;
            hasReward = true;
        }

        // DH75 share calculation for each sale
        for (uint256 i = 0; i < eligibleSales.length; i++) {
            uint256 contributed = ILaunchpadIDO(eligibleSales[i]).contributed(account);
            if (contributed > 0) {
                hasReward = true;
                distr.userDH75Shares[account][eligibleSales[i]] = contributed;
                distr.totalDH75Shares[eligibleSales[i]] += contributed;
            }
        }
        
        require(hasReward, 'DHController: you have no rewards to claim');
        
        uint256[] memory dh75Shares = new uint256[](eligibleSales.length);
        for (uint256 i = 0; i < eligibleSales.length; i++) {
            dh75Shares[i] = distr.userDH75Shares[account][eligibleSales[i]];
        }
        emit Registered(account, curDistrIdx, distr.userDH25Share[account], eligibleSales, dh75Shares);
    }
}