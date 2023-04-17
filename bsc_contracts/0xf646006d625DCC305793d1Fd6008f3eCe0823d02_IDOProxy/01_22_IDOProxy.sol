// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import './LaunchpadIDO.sol';
import '../interfaces/ILevelManager.sol';

contract IDOProxy {
    ILevelManager public levelManager;
    
    struct UserState {
        bool isWhitelisted;
        bool isRegistered;
        bool isLottery;
        bool isLotteryWinner;
        // wlAlloc + fcfsAlloc + levelAlloc
        uint256 totalAlloc;
        uint256 wlAlloc;
        uint256 fcfsAlloc;
        uint256 levelAlloc;
        string tierId;
        uint256 weight;
        uint256 contributed;
        uint256 balance;
    }
    
    constructor(address _levelManager) {
        levelManager = ILevelManager(_levelManager);
    }
    
    function getUserState(address payable sale, address account) public view returns (UserState memory) {
        LaunchpadIDO ido = LaunchpadIDO(sale);
        
        bool levelsOpen = ido.levelsOpenAll();
        UserState memory state;
        
        state.isRegistered = ido.levelsEnabled() && bytes(ido.userLevel(account)).length > 0;
        state.isWhitelisted = ido.whitelistEnabled() && ido.whitelisted(account);
        ILevelManager.Tier memory tier = levelsOpen
        ? levelManager.getUserTier(account)
        : levelManager.getTierById(state.isRegistered ? ido.userLevel(account) : 'none');
        state.tierId = tier.id;
        state.isLottery = tier.random;
        // For non-registered in non-FCFS = 0
        state.weight = ido.levelsEnabled() ? (levelsOpen ? tier.multiplier : ido.userWeight(account)) : 0;
        state.levelAlloc = (state.weight * ido.baseAllocation()) / ido.WEIGHT_DECIMALS();
        
        // Winner when: tier must be random, and winners must be picked, and user must be registered
        state.isLotteryWinner =
        state.isRegistered &&
        state.isLottery &&
        ido.levelWinners(tier.id, 0) != address(0x0) &&
        ido.userWeight(account) > 0;
        
        // FCFS alloc:
        // Registered, guaranteed or won lottery: baseAlloc + fcfsAlloc
        // Registered, lost lottery: fcfsAlloc
        // Not registered: 0 when < FCFS_3, fcfsAlloc when >= FCFS_3
        uint16 fcfsMultiplier = ido.getFcfsAllocationMultiplier();
        uint256 fcfsAlloc = (state.levelAlloc * fcfsMultiplier) / 100;
        if (state.isRegistered) {
            state.fcfsAlloc = fcfsAlloc;
            bool lostLottery = state.isLottery && !state.isLotteryWinner;
            state.totalAlloc = lostLottery ? fcfsAlloc : state.levelAlloc + fcfsAlloc;
            if (lostLottery) {
                state.levelAlloc = 0;
            }
        } else if (fcfsMultiplier >= ido.FCFS_3()) {
            state.levelAlloc = 0;
            state.totalAlloc = state.fcfsAlloc = fcfsAlloc;
        } else {
            // Not-registered in FCFS < FCFS_3
            state.tierId = 'none';
            state.levelAlloc = 0;
            state.weight = 0;
        }
        
        // Whitelist alloc adds to the level alloc, but does not affect FCFS alloc.
        if (state.isWhitelisted) {
            state.wlAlloc = ido.calculatePurchaseAmount(ido.maxSell());
            state.totalAlloc += state.wlAlloc;
        }
        
        state.contributed = ido.contributed(account);
        state.balance = ido.contributed(account);
        
        return state;
    }
}