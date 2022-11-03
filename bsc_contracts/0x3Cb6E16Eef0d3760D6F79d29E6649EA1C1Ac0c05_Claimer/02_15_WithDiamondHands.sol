// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './IClaimer.sol';
import './GeneralClaimer.sol';

abstract contract WithDiamondHands is Ownable, AccessControl, GeneralClaimer {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    bytes32 public constant DH_ROLE = keccak256('DH_ROLE');
    
    // Accounts not allowed to claim due to Diamond Hands rule
    EnumerableSet.AddressSet private ineligibleAccounts;
    address public dhTreasury;
    // How many DH "relinquished" tokens was already extracted from the claimer. We don't allow to extract more
    uint256 public withdrawnRelinquishedTokens;
    uint256 public totalRelinquishedTokens;

    event DHRelinquishedWithdrawn(uint256 amount);
    
    modifier onlyOwnerOrDH() {
        require(owner() == _msgSender() || hasRole(DH_ROLE, _msgSender()), 'Adminable: caller is not the owner or DH');
        _;
    }
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    function initDH(address dhManager, address _dhTreasury) external onlyOwner {
        grantRole(DH_ROLE, dhManager);
        dhTreasury = _dhTreasury;
    }
    
    function getIneligibleAccounts(uint256 _unused) external view returns (address[] memory) {
        return ineligibleAccounts.values();
    }
    
    function isAccountEligible(address account) public view returns (bool) {
        return !ineligibleAccounts.contains(account);
    }

    function batchSetDHIneligibleAccounts(bool eligible, address[] calldata addresses) external onlyOwnerOrDH {
        for (uint256 i = 0; i < addresses.length; i++) {
            address account = addresses[i];
            uint256 relinquished = getAccountRemaining(account);
            bool wasEligible = isAccountEligible(account);
            
            if (eligible && !wasEligible) {
                ineligibleAccounts.remove(account);
                totalRelinquishedTokens -= relinquished;
            }
            if (!eligible && wasEligible) {
                ineligibleAccounts.add(account);
                totalRelinquishedTokens += relinquished;
            }
        }
    }
    
    function withdrawRelinquished() external onlyOwnerOrDH {
        require(dhTreasury != address(0), 'DH Treasury is not setup');
        require(totalRelinquishedTokens > withdrawnRelinquishedTokens, 'No more tokens to withdraw');

        uint256 amount = totalRelinquishedTokens - withdrawnRelinquishedTokens;
        transferTokens(dhTreasury, amount);
        withdrawnRelinquishedTokens += amount;
        
        emit DHRelinquishedWithdrawn(amount);
    }
    
    function withdrawRelinquishedAdmin(address to, uint256 amount) external onlyOwner {
        require(totalRelinquishedTokens > withdrawnRelinquishedTokens, 'No more tokens to withdraw');
        uint256 leftAmount = totalRelinquishedTokens - withdrawnRelinquishedTokens;
        require(amount <= leftAmount, 'Not enough tokens to withdraw');
        
        transferTokens(to, amount);
        totalRelinquishedTokens -= amount;
    }
}