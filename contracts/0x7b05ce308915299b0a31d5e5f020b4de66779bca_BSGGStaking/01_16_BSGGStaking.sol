// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBSGGStaking.sol";

contract BSGGStaking is IBSGGStaking, ERC721, ERC721Enumerable, Pausable, Ownable {
    uint32 public ticketCounter;
    uint32 public ticketTypeCounter;

    // Stake holders can withdraw the amounts they staked, no profit
    bool public emergencyMode = false;

    // Shortlisted accounts only can by tickets
    bool public privilegedMode = false;

    // Accounts which can buy tickets when privilegedMode is enbabled
    mapping(address => bool) public privilegedAccounts;

    IERC20 public immutable BSGG;

    mapping(uint => Ticket) public tickets;
    mapping(uint => TicketType) public ticketTypes;


    // If min / max limit mode is enabled
    bool public maxLimitMode = false;

    // Limit the min volumes accounts can stake
    uint public minLimitAmount;

    // Limit the max volumes accounts can stake at a time
    uint public maxLimitAmount;
    

    // Total staked amount by the account. Limiting by the maxLimitAmount;
    // ticketType => address => amount
    mapping(uint => mapping(address => uint)) public activeStaked;

    modifier allGood() {
        require(!emergencyMode, "Emergency mode is enabled. Withdrawal only");
        _;
    }

    modifier alarmed() {
        require(emergencyMode, "Emergency mode is not activated");
        _;
    }

    modifier minMaxLimit(uint _ticketTypeId, uint _amount) {
        if (maxLimitMode == true) {
            uint stakedAlready = activeStaked[_ticketTypeId][msg.sender];
            require((_amount + stakedAlready) <= maxLimitAmount, "Max staked amount per account is reached");
            require((stakedAlready + _amount) >= minLimitAmount, "Amount is less than min allowed");
        }
        _;
    }

    constructor(IERC20 _BSGG) ERC721("BSGGStaking", "BSGGStaking") {
        BSGG = _BSGG;
    }

    /// @notice Pause new Staking
    /// @return bool
    function pause() external onlyOwner returns (bool) {
        _pause();
        emit Paused(true);
        return true;
    }

    /// @notice Unpause new Staking
    /// @return bool
    function unpause() external onlyOwner returns (bool){
        _unpause();
        emit Paused(false);
        return true;
    }

    /// @notice Allocate BSGG for distribution
    /// @param _amount Amount of BSGG
    /// @param _ticketTypeId Ticket id that will be funded
    /// @return bool
    function allocateBSGG(uint _amount, uint _ticketTypeId) external onlyOwner allGood returns (bool) {
        require(_ticketTypeId < ticketTypeCounter, "Bad ticket type");
        require(ticketTypes[_ticketTypeId].active == true, "Ticket type must be active");
        require(_amount <= BSGG.balanceOf(msg.sender), "Insuficient funds");
        require(_amount <= BSGG.allowance(msg.sender, address(this)), "Allowance required");
        
        uint16 totalSeasons = uint16(ticketTypes[_ticketTypeId].seasons.length);
        uint16 currentSeason = this.currentSeasonId(_ticketTypeId);

        totalSeasons -= currentSeason;

        uint amountPerSeason = uint(_amount / totalSeasons);
        uint amountLeft = _amount;

        for (uint16 i = currentSeason; i < uint16(ticketTypes[_ticketTypeId].seasons.length); i++) {
            uint currentSeasonAmount = amountPerSeason;

            // Last season takes the rest amount in full
            if (i == (uint16(ticketTypes[_ticketTypeId].seasons.length) - 1)) {
                currentSeasonAmount = amountLeft;
            }

            if (currentSeasonAmount > 0) {
                ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation += currentSeasonAmount;
                ticketTypes[_ticketTypeId].seasons[i].BSGGAllTimeAllocation += currentSeasonAmount;

                amountLeft -= currentSeasonAmount;
            }   
        }

        // Send Tokens to Staking Smart Contract
        bool success = BSGG.transferFrom(msg.sender, address(this), _amount);
        
        require(success == true, "Transfer Failed");

        emit AllocatedNewBSGG(_amount, _ticketTypeId);

        return true;
    }

    /// @notice Creates a new ticket type
    /// @param _minLockAmount Minimal amount of BSGG to stake
    /// @param _lockDuration Fund lock period in seconds
    /// @param _gainMultiplier Total reward rate per stake period (0 - 0%, 1500000 is 150%)
    /// @param _seasons Total number of seasons
    /// @return bool
    function addTicketType(
        uint128 _minLockAmount,
        uint32 _lockDuration,
        uint32 _gainMultiplier,
        uint16 _seasons
    ) external onlyOwner allGood returns (bool) {
        require(_minLockAmount >= 1 ether, "Bad minimum lock amount");
        require(_lockDuration >= 1 hours, "Lock duration is too short");
        require(_gainMultiplier > 0, "Gain multiplier lower or equal to base");
        require(_seasons > 0, "Seasons must be equal to 1 or higher");

        ticketTypes[ticketTypeCounter].id               = ticketTypeCounter;
        ticketTypes[ticketTypeCounter].active           = true;
        ticketTypes[ticketTypeCounter].minLockAmount    = _minLockAmount;
        ticketTypes[ticketTypeCounter].lockDuration     = _lockDuration;
        ticketTypes[ticketTypeCounter].gainMultiplier   = _gainMultiplier;
        ticketTypes[ticketTypeCounter].APR              = uint(_gainMultiplier) * 365 * 86400 / uint(_lockDuration);

        uint timeStart = block.timestamp;

        // Create seasons for ticket type
        for (uint16 i = 0; i < _seasons; i++) {
            Season memory s = Season({
                startTime: timeStart,
                BSGGAllocation: 0,
                BSGGAllTimeAllocation: 0,
                BSGGTotalTokensLocked: 0
            });

            ticketTypes[ticketTypeCounter].seasons.push(s);
            timeStart += _lockDuration;
        }

        ticketTypeCounter++;

        emit TicketTypeAdded(ticketTypeCounter);

        return true;
    }

    /// @notice Updates a ticket type, for new stake holders only
    /// @param _id Ticket type id
    /// @param _minLockAmount Minimal amount of BSGG to stake
    /// @param _lockDuration Fund lock period in seconds
    /// @param _gainMultiplier Total reward rate per stake period (0 - 0%, 1500000 is 150%)
    /// @return bool
    function updateTicketType(
        uint32 _id,
        uint128 _minLockAmount,
        uint32 _lockDuration,
        uint32 _gainMultiplier
    ) external onlyOwner allGood returns(bool) {
        require(_id < ticketTypeCounter, "Invalid ticket type");
        require(_minLockAmount >= 1 ether, "Invalid minimum lock amount");
        require(_lockDuration >= 1 hours, "Lock duration is too short");
        require(_gainMultiplier > 0, "Gain multiplier is lower or equal to base");

        ticketTypes[_id].minLockAmount    = _minLockAmount;
        ticketTypes[_id].lockDuration     = _lockDuration;
        ticketTypes[_id].gainMultiplier   = _gainMultiplier;
        ticketTypes[_id].APR = uint(_gainMultiplier) * 365 * 86400 / uint(_lockDuration);

        emit TicketTypeUpdated(_id);

        return true;
    }

    /// @notice Deactivate a ticket type
    /// @param _ticketTypeId Ticket type id
    /// @return bool
    function deactivateTicketType(uint32 _ticketTypeId) external onlyOwner allGood returns(bool) {
        require( _ticketTypeId < ticketTypeCounter, "Not existing ticket type id");
        ticketTypes[_ticketTypeId].active = false;

        emit TicketTypeUpdated(_ticketTypeId);

        return true;
    }

    /// @notice Activate selected ticket type
    /// @param _ticketTypeId Ticket type id
    /// @return bool
    function activateTicketType(uint32 _ticketTypeId) external onlyOwner allGood returns(bool) {
        require( _ticketTypeId < ticketTypeCounter, "Not existing ticket type id");
        ticketTypes[_ticketTypeId].active = true;

        emit TicketTypeUpdated(_ticketTypeId);

        return true;
    }

    /// @notice Stake and lock BSGG
    /// @param _amount BSGG stake amount
    /// @param _ticketTypeId ticket type id
    /// @param _to ticket receiver
    /// @return bool
    function buyTicket(
        uint _amount, 
        uint32 _ticketTypeId, 
        address _to
    ) external override whenNotPaused allGood minMaxLimit(_ticketTypeId, _amount) returns(bool) {
        require(ticketTypes[_ticketTypeId].active, "Ticket is not available");
        require(_amount >= ticketTypes[_ticketTypeId].minLockAmount, "Too small stake amount");
        require(_amount <= BSGG.balanceOf(msg.sender), "Insuficient funds");
        require(_amount <= BSGG.allowance(msg.sender, address(this)), "Allowance is required");
        
        uint amountToGain = (_amount * ticketTypes[_ticketTypeId].gainMultiplier) / 1e6;

        uint16 currentSeason = this.currentSeasonId(_ticketTypeId);

        require(amountToGain <= ticketTypes[_ticketTypeId].seasons[currentSeason].BSGGAllocation, "Sold out");

        if (privilegedMode == true) {
            require(privilegedAccounts[msg.sender] == true, "Privileged mode is enabled");
        }

        uint32 ticketId = ++ticketCounter;

        tickets[ticketId].id                 = ticketId;
        tickets[ticketId].ticketType         = _ticketTypeId;
        tickets[ticketId].seasonId           = currentSeason;
        tickets[ticketId].mintTimestamp      = block.timestamp;
        tickets[ticketId].lockedToTimestamp  = block.timestamp + ticketTypes[_ticketTypeId].lockDuration;
        tickets[ticketId].amountLocked       = _amount;
        tickets[ticketId].amountToGain       = amountToGain;

        // Re-allocate unused amount from previous seasons
        _reallocateSeasonUnallocated(_ticketTypeId, currentSeason);

        ticketTypes[_ticketTypeId].seasons[currentSeason].BSGGTotalTokensLocked += _amount;
        ticketTypes[_ticketTypeId].seasons[currentSeason].BSGGAllocation -= tickets[ticketId].amountToGain;

        activeStaked[_ticketTypeId][msg.sender] += _amount;

        (bool success) = BSGG.transferFrom(msg.sender, address(this), _amount);
        require(success == true, "Transfer Failed");

        // Mint the token
        _safeMint(_to, ticketId);

        emit TicketBought(
            _to, 
            ticketId, 
            _amount,
            tickets[ticketId].amountToGain, 
            ticketTypes[_ticketTypeId].lockDuration
        );

        return true;
    }

    /// @notice Unlock and send staked tokens and rewards to staker(with or without penalties depending on the time passed).
    /// @param _ticketId ticket type id
    /// @return bool
    function redeemTicket(uint _ticketId) external override allGood returns(bool) {
        require(ownerOf(_ticketId) == msg.sender, "Not token owner");

        (uint pendingStakeAmountToWithdraw, uint pendingRewardTokensToClaim) = this.getPendingTokens(_ticketId);
        uint totalAmountToWithdraw = pendingStakeAmountToWithdraw + pendingRewardTokensToClaim;

        require(totalAmountToWithdraw <= BSGG.balanceOf(address(this)), "Insuficient funds");

        uint totalAmountToReAllocate = (tickets[_ticketId].amountToGain - pendingRewardTokensToClaim) + (tickets[_ticketId].amountLocked - pendingStakeAmountToWithdraw);
        
        ticketTypes[tickets[_ticketId].ticketType].seasons[tickets[_ticketId].seasonId].BSGGAllocation += totalAmountToReAllocate;
        ticketTypes[tickets[_ticketId].ticketType].seasons[tickets[_ticketId].seasonId].BSGGTotalTokensLocked -= tickets[_ticketId].amountLocked;

        activeStaked[tickets[_ticketId].ticketType][msg.sender] -= tickets[_ticketId].amountLocked;

        delete tickets[_ticketId];
        _burn(_ticketId);

        (bool success) = BSGG.transfer(msg.sender, totalAmountToWithdraw);
        require(success == true, "Transfer Failed");

        emit TicketRedeemed(msg.sender, _ticketId);

        return true;
    }

    /// @notice Unlock and send staked tokens in case of emergency, staked amount only
    /// @param _ticketId ticket type id
    /// @return bool
    function redeemTicketEmergency(uint _ticketId) external alarmed returns(bool) {
        require(ownerOf(_ticketId) == msg.sender, "Not token owner");

        require(tickets[_ticketId].amountLocked <= BSGG.balanceOf(address(this)), "Insuficient funds");

        uint amountRedeem = tickets[_ticketId].amountLocked;

        delete tickets[_ticketId];
        _burn(_ticketId);

        (bool success) = BSGG.transfer(msg.sender, amountRedeem);
        require(success == true, "Transfer Failed");

        emit TicketRedeemed(msg.sender, _ticketId);

        return true;
    }

    /// @notice Get amount of staked tokens and reward
    /// @param _ticketId Ticket type id
    /// @return stakeAmount , rewardAmount
    function getPendingTokens(uint _ticketId) external view returns (uint stakeAmount, uint rewardAmount) {
        uint lockDuration = tickets[_ticketId].lockedToTimestamp - tickets[_ticketId].mintTimestamp;
        uint halfPeriodTimestamp = tickets[_ticketId].lockedToTimestamp - (lockDuration / 2);

        if (block.timestamp < tickets[_ticketId].lockedToTimestamp) {
            stakeAmount = (tickets[_ticketId].amountLocked * 800000) / 1e6; // 20% penalty applied to staked amount

            // If staked for at least the half of the period
            if (block.timestamp >= halfPeriodTimestamp){
                uint pendingReward = _calculatePendingRewards(
                    block.timestamp,
                    tickets[_ticketId].mintTimestamp,
                    tickets[_ticketId].lockedToTimestamp,
                    tickets[_ticketId].amountToGain
                );
                rewardAmount = pendingReward / 2; // The account can get 50% of pending rewards
            }
        } else { // Lock period is over. The account can receive all staked and reward tokens.
            stakeAmount = tickets[_ticketId].amountLocked;
            rewardAmount = tickets[_ticketId].amountToGain;
        }
    }

    /// @notice Checks pending rewards by the date. Returns 0 in deleted ticket Id
    /// @param _ticketId Ticket type id
    /// @return amount
    function getPendingRewards(uint _ticketId) external view returns (uint amount) {
        amount = _calculatePendingRewards(
            block.timestamp < tickets[_ticketId].lockedToTimestamp ? block.timestamp : tickets[_ticketId].lockedToTimestamp,
            tickets[_ticketId].mintTimestamp,
            tickets[_ticketId].lockedToTimestamp,
            tickets[_ticketId].amountToGain
        );
    }

    /// @notice Outputs parameters of all account tickets
    /// @param _account Account Address
    /// @return accountInfo
    function getAccountInfo(address _account) external view returns(AccountSet memory accountInfo) {
        uint countOfTicket = balanceOf(_account);
        Ticket[] memory accountTickets = new Ticket[](countOfTicket);
        uint allocatedBSGG;
        uint pendingBSGGEarning;

        for (uint i = 0; i < countOfTicket; i++){
            uint ticketId = tokenOfOwnerByIndex(_account, i);
            accountTickets[i] = tickets[ticketId];
            allocatedBSGG += tickets[ticketId].amountLocked;
            pendingBSGGEarning += this.getPendingRewards(ticketId);
        }

        accountInfo.accountTickets = accountTickets;
        accountInfo.allocatedBSGG = allocatedBSGG;
        accountInfo.pendingBSGGEarning = pendingBSGGEarning;
    }

    /// @notice Returns all available tickets and their parameters
    /// @return allTicketTypes
    function getTicketTypes() external view returns(TicketType[] memory allTicketTypes) {
        allTicketTypes = new TicketType[](ticketTypeCounter);
        for (uint i = 0; i < ticketTypeCounter; i++) {
            allTicketTypes[i] = ticketTypes[i];
        }
    }

    /// @notice TVL across all pools
    /// @return TVL Total Tokens Locked in all ticket types
    function getTVL() external view returns(uint TVL){
        for (uint i = 0; i < ticketTypeCounter; i++) {
            for (uint16 j = 0; j < ticketTypes[i].seasons.length; j++) {
                TVL += ticketTypes[i].seasons[j].BSGGTotalTokensLocked;
                TVL += ticketTypes[i].seasons[j].BSGGAllocation;
            }
        }
    }

    /// @notice Get amount the account has active staked in a ticket type
    /// @param _ticketTypeId Ticket Type ID
    /// @param _account Account
    /// @return uint
    function getActiveStaked(uint _ticketTypeId, address _account) external view returns (uint) {
        return activeStaked[_ticketTypeId][_account];
    }

    /// @notice Set emergency state
    /// @param code A security code. Requiered in case of unaccidentaly call of this function
    /// @return bool
    function triggerEmergency(uint code) external onlyOwner allGood returns(bool) {
        require(code == 111000111, "You need write 111000111");

        emergencyMode = true;
        _pause();

        emit EmergencyModeEnabled();

        return true;
    }

    /// @notice Enable PrivilegedMode, shortlisted accounts only can buy tickets
    /// @return bool
    function enablePrivilegedMode() external onlyOwner returns(bool) {
        privilegedMode = true;
        emit PrivilegedMode(privilegedMode);

        return true;
    }

    /// @notice Disable PrivilegedMode, all accounts can buy tickets
    /// @return bool
    function disablePrivilegedMode() external onlyOwner returns(bool) {
        privilegedMode = false;
        emit PrivilegedMode(privilegedMode);

        return true;
    }

    /// @notice Add previledged accounts
    /// @param _accounts Account to make privileged
    /// @return bool
    function addPrivilegedAccounts(address[] memory _accounts) external onlyOwner returns(bool) {
        require(_accounts.length < 400, "Too many accounts to add");

        for (uint16 i = 0; i < _accounts.length; i++) {
            privilegedAccounts[_accounts[i]] = true;
        }

        emit PrivilegedMode(privilegedMode);

        return true;
    }

    /// @notice Remove previledged accounts
    /// @param _accounts Account to make privileged
    /// @return bool
    function removePrivilegedAccounts(address[] memory _accounts) external onlyOwner returns(bool) {
        require(_accounts.length < 400, "Too many accounts to remove");

        for (uint16 i = 0; i < _accounts.length; i++) {
            privilegedAccounts[_accounts[i]] = false;
        }

        emit PrivilegedMode(privilegedMode);

        return true;
    }

    /// @notice Maximum allocation (balance) available for a season by ticket type id
    /// @param _ticketTypeId Ticket type id
    /// @return uint256
    function maxAllocationSeason(uint _ticketTypeId) external view returns (uint256) {
        uint currentTime = block.timestamp;
        uint maxBalance = 0;

        for (uint16 i = 0; i < ticketTypes[_ticketTypeId].seasons.length; i++) {
            if (ticketTypes[_ticketTypeId].seasons[i].startTime > currentTime) {
                break;
            }

            maxBalance += ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation;
        }

        return maxBalance;
    }

    /// @notice Total staked amount (balance) by users in ticket type id
    /// @param _ticketTypeId Ticket type id
    /// @return uint256
    function amountLockedSeason(uint _ticketTypeId) external view returns (uint256) {
        uint currentTime = block.timestamp;
        uint amount = 0;

        for (uint16 i = 0; i < ticketTypes[_ticketTypeId].seasons.length; i++) {
            if (ticketTypes[_ticketTypeId].seasons[i].startTime > currentTime) {
                break;
            }

            amount += ticketTypes[_ticketTypeId].seasons[i].BSGGTotalTokensLocked;
        }

        return amount;
    }

    /// @notice Get current season id by ticket type id
    /// @param _ticketTypeId Ticket type id
    /// @return uint16
    function currentSeasonId(uint _ticketTypeId) external view returns (uint16) {
        uint currentTime = block.timestamp;

        uint16 seasonId = 0;

        for (uint16 i = 0; i < ticketTypes[_ticketTypeId].seasons.length; i++) {
            if (ticketTypes[_ticketTypeId].seasons[i].startTime > currentTime) {
                break;
            }

            seasonId = i;
        }

        return seasonId;
    }


    /// @notice Withdraw previously allocated BSGG, but only not reserved for accounts
    /// @param _amount Amount of BSGG to remove from allocation
    /// @param _ticketTypeId Ticket type id
    /// @return bool
    function withdrawNonReservedBSGG(uint _amount, uint32 _ticketTypeId, uint16 _seasonId, address _account) external onlyOwner returns(bool) {
        uint withdrawAmount = ticketTypes[_ticketTypeId].seasons[_seasonId].BSGGAllocation >= _amount ? _amount : ticketTypes[_ticketTypeId].seasons[_seasonId].BSGGAllocation;
        
        require(withdrawAmount <= BSGG.balanceOf(address(this)), "Insuficient funds");

        ticketTypes[_ticketTypeId].seasons[_seasonId].BSGGAllTimeAllocation -= withdrawAmount;
        ticketTypes[_ticketTypeId].seasons[_seasonId].BSGGAllocation -= withdrawAmount;

        (bool success) = BSGG.transfer(_account, withdrawAmount);
        require(success == true, "Transfer Failed");

        emit TicketTypeUpdated(_ticketTypeId);

        return true;
    }

    /// @notice Set Max and Min amounts for staking per account
    /// @param _minAmount Min amount
    /// @param _maxAmount Max amount
    /// @param _status Enabled true/ false
    /// @return bool
    function changeMinMaxLimits(uint _minAmount, uint _maxAmount, bool _status) external onlyOwner returns(bool) {
        require(_minAmount <= _maxAmount, "Invalid min and max amounts");

        maxLimitMode = _status;
        minLimitAmount = _minAmount;
        maxLimitAmount = _maxAmount;

        emit MinMaxLimitChanged(_minAmount, _maxAmount, _status);

        return true;
    }

    /// @notice Calculates pending rewards
    /// @return amount amount
    function _calculatePendingRewards(
        uint timestamp,
        uint mintTimestamp,
        uint lockedToTimestamp,
        uint amountToGain
    ) pure internal returns (uint amount){
        return amountToGain * (timestamp - mintTimestamp) / (lockedToTimestamp - mintTimestamp);
    }

    /// @notice Reuse unallocated balance from previous seasons
    /// @param _ticketTypeId Ticket type id
    /// @return amount
    function _reallocateSeasonUnallocated(uint _ticketTypeId, uint16 _currentSeasonId) internal returns (bool){
        uint reAllocationAmount = 0;

        for (uint16 i = 0; i < ticketTypes[_ticketTypeId].seasons.length; i++) {
            // Season is sold out
            if (ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation <= 0) {
                continue;
            }

            // Current season or seson not available yet
            if (i == _currentSeasonId || ticketTypes[_ticketTypeId].seasons[i].startTime >= block.timestamp) {
                break;
            }

            reAllocationAmount += ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation;
            ticketTypes[_ticketTypeId].seasons[i].BSGGAllTimeAllocation -= ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation;
            ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation = 0;
        }

        if (reAllocationAmount > 0) {
            ticketTypes[_ticketTypeId].seasons[_currentSeasonId].BSGGAllTimeAllocation += reAllocationAmount;
            ticketTypes[_ticketTypeId].seasons[_currentSeasonId].BSGGAllocation += reAllocationAmount;
        }

        return true;
    }
    
    function _beforeTokenTransfer(address from, address to, uint ticketId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, ticketId);
    }

    /// @notice The following functions are overrides required by Solidity
    /// @param interfaceId Interface ID
    /// @return bool
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}