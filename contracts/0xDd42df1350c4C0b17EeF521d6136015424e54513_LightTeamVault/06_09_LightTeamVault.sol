// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { TransferHelper } from "light-lib/contracts/TransferHelper.sol";

contract LightTeamVault is OwnableUpgradeable {

    // locked token address, LT token
    address public token;
    uint256 public startTime;
    // the amount that had already claimed
    uint256 public claimedAmount;
    uint256 public lastClaimedTime;

    uint256 constant public TOTAL_LOCKED = 300_000_000_000 * 1e18; // 0.3 trillion;
    uint256 constant public EPOK = 208 weeks;
    uint256 constant public UNLOCKED_PER_DAY = TOTAL_LOCKED / 208 / 7;

    event ClaimTo(address indexed claimer, address indexed to, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // LT deploy first , then deploy this contract , finally transfer 0.3 trillion to this
    function initialize(address _token) public initializer {
        require(_token != address(0), "LightTeamVault: invalid token"); 
        __Ownable_init();
        token = _token;
        startTime = block.timestamp - 1 days;
    }

    /*
     * @dev: admin operation, claim amount token to to , the amount must within claimable amount 
     */    
    function claimTo(address to) external onlyOwner {
        require(to != address(0), "LightTeamVault: zero address");
        uint amount = getClaimableAmount();
        if (lastClaimedTime > 0)
            require(block.timestamp - lastClaimedTime >= 1 days, "LightTeamVault: claim interval must gt one day");

        claimedAmount += amount;
        lastClaimedTime = block.timestamp;
        TransferHelper.doTransferOut(token, to, amount);
        emit ClaimTo(msg.sender, to, amount);
    }

    /*
     * @dev: get the total unlocked amount from now on
     */    
    function getTotalUnlockedAmount() public view returns (uint256) {
        uint elapsedDays;
        if (block.timestamp - startTime >= EPOK) {
            elapsedDays = EPOK / 1 days;
        } else {
            elapsedDays = (block.timestamp - startTime) / 1 days;
        }

        return elapsedDays * UNLOCKED_PER_DAY;
    }

    /*
     * @dev: get the amount that can be claimed
     */    
    function getClaimableAmount() public view returns (uint256) {
        return getTotalUnlockedAmount() - claimedAmount;
    }
}