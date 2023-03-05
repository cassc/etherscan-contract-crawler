/*
Contract Security Audited by Certik : https://www.certik.com/projects/opticash
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface TransferOPCH {
    function transfer(address recipient, uint256 amount) 
        external 
        returns (bool);
}

contract OPCHMarketingBucket is AccessControlEnumerable {
    TransferOPCH private opchToken;

    struct Bucket {
        uint256 allocation;
        uint256 claimed;
    }

    mapping(address => Bucket) public users;
    bytes32 public constant GRANTER_ROLE = keccak256("GRANTER_ROLE");

    uint256 public constant MAX_LIMIT = 250 * (10**6) * 10**18;
    uint256 public constant VESTING_SECONDS = 365 * 86400;
    uint256 public totalMembers;
    uint256 public allocatedSum;
    uint256 public immutable vestingStartEpoch;

    event GrantAllocationEvent(address allcationAdd, uint256 amount);
    event GrantFundEvent(address allcationAdd, uint256 amount);
    event ClaimAllocationEvent(address addr, uint256 balance);
    event VestingStartedEvent(uint256 epochtime);

    constructor(TransferOPCH tokenAddress) {
        require(address(tokenAddress) != address(0),"Token Address cannot be address 0");
        opchToken = tokenAddress;
        totalMembers = 0;
        allocatedSum = 0;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        vestingStartEpoch = block.timestamp;
        emit VestingStartedEvent(vestingStartEpoch);
    }

    function grantAllocation(address[] calldata _allocationAdd,uint256[] calldata _amount) external {
        require(hasRole(GRANTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"Must have admin or granter role");
        require(_allocationAdd.length == _amount.length,"Count of address and amount do not match");

        uint256 length = _allocationAdd.length;
        for (uint256 i = 0; i < length; ++i) {
            _grantAllocation(_allocationAdd[i], _amount[i]);
        }
    }

    function grantFund(address allocationAdd, uint256 amount) external {
        require(hasRole(GRANTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"Must have admin or granter role");
        require(allocationAdd != address(0), "Invalid allocation address");
        require(amount > 0, "Invalid allocation amount");
        require(allocatedSum + amount <= MAX_LIMIT, "Limit exceeded");

        if (users[allocationAdd].allocation == 0) {
            totalMembers++;
        }
        allocatedSum += amount;
        users[allocationAdd].allocation += amount;
        users[allocationAdd].claimed += amount;
        emit GrantFundEvent(allocationAdd, amount);
        require(opchToken.transfer(allocationAdd, amount),"Token transfer failed!");
    }

    function _grantAllocation(address allocationAdd, uint256 amount) internal {
        require(allocationAdd != address(0), "Invalid allocation address");
        require(amount > 0, "Invalid allocation amount");
        require(amount >= users[allocationAdd].claimed,"Amount cannot be less than already claimed amount");
        require(allocatedSum - users[allocationAdd].allocation + amount <=MAX_LIMIT,"Limit exceeded");

        if (users[allocationAdd].allocation == 0) {
            totalMembers++;
        }
        allocatedSum = allocatedSum - users[allocationAdd].allocation + amount;
        users[allocationAdd].allocation = amount;
        emit GrantAllocationEvent(allocationAdd, amount);
    }

    function getclaimableBalance(address userAddr) public view returns (uint256) {
        Bucket memory userBucket = users[userAddr];
        require(userBucket.allocation != 0, "Address is not registered");

        uint256 totalClaimableBal = userBucket.allocation / 10; // 10% of allocation
        totalClaimableBal = totalClaimableBal + ((block.timestamp - vestingStartEpoch)*(userBucket.allocation - totalClaimableBal)/VESTING_SECONDS);    

        if (totalClaimableBal > userBucket.allocation) {
            totalClaimableBal = userBucket.allocation;
        }

        if (totalClaimableBal <= userBucket.claimed) return 0;
        else return totalClaimableBal - userBucket.claimed;
    }

    function processClaim() external {
        uint256 claimableBalance = getclaimableBalance(_msgSender());
        require(claimableBalance > 0, "Claim amount invalid.");

        users[_msgSender()].claimed += claimableBalance;
        emit ClaimAllocationEvent(_msgSender(), claimableBalance);
        require(opchToken.transfer(_msgSender(), claimableBalance),"Token transfer failed!");
    }
}