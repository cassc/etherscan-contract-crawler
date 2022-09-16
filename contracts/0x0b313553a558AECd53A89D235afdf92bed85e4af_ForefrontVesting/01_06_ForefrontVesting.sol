// contracts/ForefrontVesting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
  ______              __                 _   
 |  ____|            / _|               | |  
 | |__ ___  _ __ ___| |_ _ __ ___  _ __ | |_ 
 |  __/ _ \| '__/ _ \  _| '__/ _ \| '_ \| __|
 | | | (_) | | |  __/ | | | | (_) | | | | |_ 
 |_|  \___/|_|  \___|_| |_|  \___/|_| |_|\__|
                                                                         
*/

/// @title Forefront News Vesting Contract
/// @notice A contract used for the vesting entries of contributions made during the Treasury Diversification Round
contract ForefrontVesting is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public vestingToken;
    address public treasury;

    uint256 public startTimestamp;
    uint256 public finishingTimestamp;

    uint256 public globalForefrontVested;

    /// @dev change according to program
    uint256 public constant vestingLength = 365 days;
    /// @dev change according to program
    uint256 public constant cliffLength = 0 days;

    struct Entry {
        uint256 locked;
        uint256 claimed;
        uint256 totalAllocation;
    }

    mapping(address => Entry) private entries;

    event TokenVested(address indexed wallet, uint256 amount);
    event EntryAdded(address indexed wallet, uint256 amount);
    event EntryRemoved(address indexed wallet, uint256 amount);

    constructor(
        uint256 _start,
        address _ffToken,
        address _treasury
    ) {
        startTimestamp = _start;
        finishingTimestamp = _start + vestingLength;
        vestingToken = IERC20(_ffToken);
        treasury = _treasury;
    }

    /* Public Functions */

    function vest() public {
        uint256 amountCanClaim = vestableAmount(msg.sender);
        require(amountCanClaim > 0, "ForefrontVesting: no tokens are vestable");

        entries[msg.sender].locked -= amountCanClaim;
        entries[msg.sender].claimed += amountCanClaim;
        globalForefrontVested -= amountCanClaim;

        vestingToken.safeTransfer(msg.sender, amountCanClaim);

        emit TokenVested(msg.sender, amountCanClaim);
    }

    /* Restricted Functions */

    function addEntries(address[] memory wallets, uint256[] memory allocations)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            if (addEntry(wallets[i], allocations[i])) {
                success = true;
            }
        }
    }

    function addEntry(address wallet, uint256 allocation)
        public
        onlyOwner
        returns (bool success)
    {
        entries[wallet] = Entry(allocation, 0, allocation);
        globalForefrontVested += allocation;
        emit EntryAdded(wallet, allocation);
        success = true;
    }

    function removeEntries(address[] memory wallets)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            if (removeEntry(wallets[i])) {
                success = true;
            }
        }
    }

    function removeEntry(address wallet)
        public
        onlyOwner
        returns (bool success)
    {
        uint256 previousAllocation = entries[wallet].totalAllocation;
        globalForefrontVested -= previousAllocation;
        delete entries[wallet];
        emit EntryRemoved(wallet, previousAllocation);
        success = true;
    }

    function retrieveFunds() public onlyOwner {
        vestingToken.safeTransfer(
            treasury,
            vestingToken.balanceOf(address(this))
        );
    }

    function emergencyWithdraw(address tokenAddress) public onlyOwner {
        IERC20 tokenToWithdraw = IERC20(tokenAddress);
        tokenToWithdraw.safeTransfer(
            treasury,
            tokenToWithdraw.balanceOf(address(this))
        );
    }

    /* Views */

    function vestableAmount(address wallet) public view returns (uint256) {
        if (block.timestamp < startTimestamp + cliffLength) {
            return 0;
        } else if (block.timestamp >= finishingTimestamp) {
            return entries[wallet].locked;
        } else {
            return
                ((entries[wallet].totalAllocation *
                    (block.timestamp - startTimestamp)) / vestingLength) -
                entries[wallet].claimed;
        }
    }

    function claimed(address wallet) public view returns (uint256) {
        return entries[wallet].claimed;
    }

    function locked(address wallet) public view returns (uint256) {
        return entries[wallet].locked;
    }

    function totalAllocation(address wallet) public view returns (uint256) {
        return entries[wallet].totalAllocation;
    }
}