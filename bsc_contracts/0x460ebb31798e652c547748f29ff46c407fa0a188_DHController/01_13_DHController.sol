// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
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
    
    // List of users eligible for retrospective rewards from the selected sales.
    mapping(address => bool) public isUserRetroEligible;
    // Retro-eligibility works only
    mapping(address => bool) public isSaleRetroEligible;
    
    uint256 public registrationPeriod;
    uint256 public claimPeriod;
    // Year-month-day zero-padded numbers (always 1st day of the month): 2021-01-01 -> 20210101, 2023-03-08 -> 20230308
    uint256 public curDistrIdx;
    
    // Indexed by year-month-day zero-padded numbers (always 1st day of the month). Current is marked by currentDistributionIndex
    mapping(uint256 => Distribution) internal distributions;
    
    // Map of transferred accounts, we always want to check the source one. Old -> new
    mapping(address => address) public transferredAccounts;
    // Inversed map of transferred accounts, so we can trace the new wallet back to the old one. New -> old
    mapping(address => address) public inverseTransferredAccounts;
    
    event Registered(
        address indexed user,
        uint256 distributionIndex,
        uint256 dh25Share,
        address[] sales,
        uint256[] dh75Shares
    );
    event NewDistribution(uint256 distributionIndex, uint256 start);
    
    function initialize(address _levelManager) public initializer {
        OwnableUpgradeable.__Ownable_init();
        AccessControlUpgradeable.__AccessControl_init();
        
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
    
    function setDistributionStart(uint256 _distrIdx, uint256 _start) external onlyRole(MANAGER_ROLE) {
        distributions[_distrIdx == 0 ? curDistrIdx : _distrIdx].start = _start;
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
    
    function setRetroEligibleAddresses(bool status, address[] memory addresses) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            isUserRetroEligible[addresses[i]] = status;
        }
    }
    
    function setRetroEligibleSales(bool status, address[] memory addresses) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            isSaleRetroEligible[addresses[i]] = status;
        }
    }
    
    function getDistributionStatus(Distribution storage distr) internal view returns (DistributionStatus) {
        if (distr.start == 0) {
            return DistributionStatus.NoDate;
        }
        if (block.timestamp < distr.start - registrationPeriod) {
            return DistributionStatus.PreRegistration;
        }
        if (block.timestamp < distr.start) {
            return DistributionStatus.Registration;
        }
        if (block.timestamp < distr.start + claimPeriod) {
            return DistributionStatus.Claiming;
        }
        return DistributionStatus.Finished;
    }
    
    function getDistribution(uint256 distrIdx) public view override returns (DistributionView memory) {
        uint256 idx = distrIdx == 0 ? curDistrIdx : distrIdx;
        Distribution storage distr = distributions[idx];
        
        uint256[] memory totalDH75Shares = new uint256[](eligibleSales.length);
        bool[] memory isRetroSale = new bool[](eligibleSales.length);
        for (uint256 i = 0; i < eligibleSales.length; i++) {
            totalDH75Shares[i] = distr.totalDH75Shares[eligibleSales[i]];
            isRetroSale[i] = isSaleRetroEligible[eligibleSales[i]];
        }
        
        DistributionView memory distrView = DistributionView(
            getDistributionStatus(distr),
            idx,
            distr.start,
            distr.start > 0 ? distr.start - registrationPeriod : 0, // reg start
            distr.start + claimPeriod, // end of claiming period
            distr.registrants.length,
            distr.totalDH25Share,
            distr.totalDH25ShareRetro,
            eligibleSales,
            totalDH75Shares,
            isRetroSale
        );
        
        return distrView;
    }
    
    function getRegistrants(uint256 distrIdx) external view override returns (address[] memory) {
        uint256 idx = distrIdx == 0 ? curDistrIdx : distrIdx;
        return distributions[idx].registrants;
    }
    
    function isStakedInEligiblePool(address pool) internal view returns (bool) {
        for (uint256 i = 0; i < eligiblePools.length; i++) {
            if (pool == eligiblePools[i]) {
                return true;
            }
        }
        return false;
    }
    
    // Gathers the whole chain of user transferred accounts starting from the new one to the oldest one.
    function getTransferredAccounts(address account) internal view returns (address[] memory) {
        address[] memory accounts = new address[](20);
        accounts[0] = account;
        for (uint256 i = 1; i < 20; i++) {
            accounts[i] = inverseTransferredAccounts[accounts[i - 1]];
            if (accounts[i] == address(0)) {
                break;
            }
        }
        
        return accounts;
    }
    
    // Gets the contribution amount for an account, checks the whole chain of transferred accounts:
    // user might have a hacked wallet with which they participated.
    function getAccountSaleContribution(address sale, address[] memory accounts) public view returns (uint256) {
        uint256 contributed;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) break;
            
            try ILaunchpadIDO(sale).contributed(accounts[i]) returns (uint256 amount) {
                contributed = amount;
            } catch {
                contributed = IOldLaunchpadIDO(sale).balances(accounts[i]);
            }
            if (contributed > 0) break;
        }
        
        return contributed;
    }
    
    function getUserDHState(address account) public view override returns (UserDHState memory) {
        ILevelManager.Tier memory tier = ILevelManager(levelManager).getUserTier(account);
        UserDHState memory v;
        
        if (tier.multiplier == 0) {
            v.status = UserStatus.NoTier;
            return v;
        }
        if (!isStakedInEligiblePool(tier.pool)) {
            v.status = UserStatus.NotEligiblePool;
            return v;
        }
        
        v.isRegistered = distributions[curDistrIdx].isRegistered[account];
        v.isRetroEligible = isUserRetroEligible[account];
        // DH25share = tier.multiplier; Can get DH25 only if staking in the eligible pool and has an AAG level
        v.userDH25Share = tier.aag ? tier.amount : 0;
        v.sales = new address[](eligibleSales.length);
        v.userDH75Shares = new uint256[](eligibleSales.length);
        v.hasReward = v.userDH25Share > 0;
        
        address[] memory accounts = getTransferredAccounts(account);
        for (uint256 i = 0; i < eligibleSales.length; i++) {
            v.sales[i] = eligibleSales[i];
            
            // Retro-sales are given only retro-eligible users, so user gets 0 DH75 share if not eligible for a retro sale
            if (isSaleRetroEligible[eligibleSales[i]] && !isUserRetroEligible[account]) {
                v.userDH75Shares[i] = 0;
                continue;
            }
            
            v.userDH75Shares[i] = getAccountSaleContribution(eligibleSales[i], accounts);
            v.hasReward = v.hasReward || v.userDH75Shares[i] > 0;
        }
        
        return v;
    }
    
    function getTestData(address account) external  view returns (uint256, uint256) {
        return (distributions[curDistrIdx].userDH25Share[account], distributions[curDistrIdx].totalDH25Share);
}
    
    function register() external override {
        address account = msg.sender;
        Distribution storage distr = distributions[curDistrIdx];
        distr.status = getDistributionStatus(distr);
        
        require(!distr.isRegistered[account], 'DHController: already registered');
        require(distr.status == DistributionStatus.Registration, 'DHController: registration is closed');
        
        UserDHState memory userState = getUserDHState(account);
        require(userState.status != UserStatus.NoTier, 'DHController: you must have a level to register');
        require(
            userState.status != UserStatus.NotEligiblePool,
            'DHController: the pool where you stake a level is not eligible for DH rewards'
        );
        require(userState.hasReward, 'DHController: you have no rewards to claim');
        
        distr.isRegistered[account] = true;
        distr.registrants.push(account);
        distr.totalDH25Share += userState.userDH25Share;
        distr.totalDH25ShareRetro += userState.isRetroEligible ? userState.userDH25Share : 0;
        distr.userDH25Share[account] = userState.userDH25Share;
        for (uint256 i = 0; i < userState.sales.length; i++) {
            distr.userDH75Shares[account][eligibleSales[i]] = userState.userDH75Shares[i];
            distr.totalDH75Shares[eligibleSales[i]] += userState.userDH75Shares[i];
        }
        
        emit Registered(account, curDistrIdx, distr.userDH25Share[account], eligibleSales, userState.userDH75Shares);
    }
    
    function transferAccount(address oldWallet, address newWallet) external onlyOwner {
        require(oldWallet != address(0), 'DHController: zero address');
        require(newWallet != address(0), 'DHController: zero address');
        require(oldWallet != newWallet, 'DHController: same address');
        require(inverseTransferredAccounts[newWallet] == address(0), 'DHController: already transferred');
        require(transferredAccounts[newWallet] == address(0), 'DHController: already transferred');
        
        inverseTransferredAccounts[newWallet] = oldWallet;
        transferredAccounts[oldWallet] = newWallet;
        isUserRetroEligible[newWallet] = isUserRetroEligible[oldWallet];
        isUserRetroEligible[oldWallet] = false;
    }
}