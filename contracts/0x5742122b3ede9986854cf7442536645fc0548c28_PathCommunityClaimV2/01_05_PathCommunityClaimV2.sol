pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


contract PathCommunityClaimV2 is Ownable{

    IERC20 immutable private token;

    uint public grandTotalClaimed = 0;

    uint private grandTotalAllocated;

    struct Allocation {
        uint startVesting; // End vesting 
        uint endVesting; // End vesting 
        uint totalAllocated; // Total tokens allocated
        uint amountClaimed;
        bool revocable;
    }

    mapping (address => Allocation[]) public allocations;

    event claimedToken(address indexed _recipient, uint tokensClaimed, uint totalClaimed);

    constructor (address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function getClaimSingleAlloc(address _recipient, uint _index) public view returns (uint amount) {
        uint claimAmount;
        if (allocations[_recipient][_index].revocable) {
            claimAmount = 0;
        }
        else {
            claimAmount = calculateClaimAmount(_recipient, _index) - allocations[_recipient][_index].amountClaimed;
        }
        return claimAmount;
    }

    // view function to calculate claimable tokens
    function calculateClaimAmount(address _recipient, uint _index) internal view returns (uint amount) {
        uint newClaimAmount;
        if (block.timestamp <= allocations[_recipient][_index].startVesting || allocations[_recipient][_index].revocable) {
            newClaimAmount = 0;
        }
        else if (block.timestamp >= allocations[_recipient][_index].endVesting) {
            newClaimAmount = allocations[_recipient][_index].totalAllocated;
        }
        else {
                newClaimAmount = ((allocations[_recipient][_index].totalAllocated)
                    * (block.timestamp - allocations[_recipient][_index].startVesting))
                    / (allocations[_recipient][_index].endVesting - allocations[_recipient][_index].startVesting);
            }
        return newClaimAmount;
    }

    /**
    * @dev Set the addresses and their corresponding allocations
    * @param _addresses The recipient of the allocation
    * @param _totalAllocated The total number of minted NFT
    */
    function setAllocation(
        address[] memory _addresses,
        uint[] memory _totalAllocated,
        uint[] memory _startVesting,
        uint[] memory _endVesting) onlyOwner external {
        //make sure that the length of address and total minted is the same
        require(_addresses.length == _totalAllocated.length, "length of array should be the same");
        require(_addresses.length == _startVesting.length, "length of array should be the same");
        require(_addresses.length == _endVesting.length, "length of array should be the same");
        uint amountToTransfer;
        for (uint i = 0; i < _addresses.length; i++ ) {
            allocations[_addresses[i]].push(Allocation(
                _startVesting[i],
                _endVesting[i],
                _totalAllocated[i],
                0,
                false));
            amountToTransfer += _totalAllocated[i];
            grandTotalAllocated += _totalAllocated[i];
        }
        require(token.transferFrom(msg.sender, address(this), amountToTransfer), "Token transfer failed");
    }

    /**
    * @dev Get total allocated amount
    * @param _recipient recipient of allocation
     */
    function getTotalAllocated(address _recipient) public view returns (uint amount) {
        uint totalAllocated;
        for (uint i = 0; i < allocations[_recipient].length; i++) {
            if (!allocations[_recipient][i].revocable) {
                totalAllocated += allocations[_recipient][i].totalAllocated;
            }
        }
        return totalAllocated;
    }

    /**
    * @dev Get total claimed amount
    * @param _recipient recipient of allocation
     */
    function getTotalClaimed(address _recipient) public view returns (uint amount) {
        uint totalClaimed;
        for (uint i = 0; i < allocations[_recipient].length; i++) {
            totalClaimed += allocations[_recipient][i].amountClaimed;
        }
        return totalClaimed;
    }

    /**
    * @dev Check remaining claimable amount
    * @param _recipient recipient of allocation
     */
    function getRemainingAmount(address _recipient) external view returns (uint amount) {
        uint remainingClaimable;
        for (uint i = 0; i < allocations[_recipient].length; i++) {
            if (!allocations[_recipient][i].revocable) {
                remainingClaimable += (allocations[_recipient][i].totalAllocated - allocations[_recipient][i].amountClaimed);
            }
        }
        return remainingClaimable;
    }

    /**
    * @dev Check current claimable amount
    * @param _recipient recipient of allocation
     */

    function getClaimAllAlloc(address _recipient) external view returns (uint amount) {
        uint claimableTokens;
        for (uint i = 0; i < allocations[_recipient].length; i++) {
            claimableTokens += getClaimSingleAlloc(_recipient, i);
        }
        return claimableTokens;
    }

     /**
     * @dev transfers allocated tokens to recipient to their address
     * @param _recipient the addresss to withdraw tokens for
      */
    function transferTokens(address _recipient) external {
        require(getTotalClaimed(_recipient) < getTotalAllocated(_recipient), "Address should have some allocated tokens");
        //transfer tokens after subtracting tokens claimed
        uint tokensToClaim;
        for (uint i = 0; i < allocations[_recipient].length; i++) {
            uint newClaimAmount = calculateClaimAmount(_recipient, i);
            tokensToClaim += getClaimSingleAlloc(_recipient, i);
            allocations[_recipient][i].amountClaimed = newClaimAmount;
        }
        require(tokensToClaim > 0, "Recipient should have more than 0 tokens to claim");
        grandTotalClaimed += tokensToClaim;
        require(token.transfer(_recipient, tokensToClaim), "Token transfer failed");
        emit claimedToken(_recipient, tokensToClaim, getTotalClaimed(_recipient));
    }

     /**
     * @dev transfers allocated tokens of that index to recipient
     * @param _recipient the addresss to withdraw tokens for
     * @param _index the allocated index in the list
      */
    function transferSingleAlloc(address _recipient, uint _index) external {
        require(allocations[_recipient][_index].amountClaimed < allocations[_recipient][_index].totalAllocated, "Address should have some allocated tokens");
        require(allocations[_recipient][_index].startVesting <= block.timestamp, "Start time of claim should be later than start of vesting time");
        //transfer tokens after subtracting tokens claimed
        uint newClaimAmount = calculateClaimAmount(_recipient, _index);
        uint tokensToClaim = getClaimSingleAlloc(_recipient, _index);
        require(tokensToClaim > 0, "Recipient should have more than 0 tokens to claim");
        allocations[_recipient][_index].amountClaimed = newClaimAmount;
        grandTotalClaimed += tokensToClaim;
        require(token.transfer(_recipient, tokensToClaim), "Token transfer failed");
        emit claimedToken(_recipient, tokensToClaim, allocations[_recipient][_index].amountClaimed);
    }

    //owner restricted functions
    /**
     * @dev reclaim excess allocated tokens for claiming
     * @param _amount the amount to withdraw tokens for
      */
    function reclaimExcessTokens(uint _amount) external onlyOwner {
        require(_amount <= token.balanceOf(address(this)) - (grandTotalAllocated - grandTotalClaimed), "Amount of tokens to recover is more than what is allowed");
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }

    /**
     * @dev revoke allocations and claim back unclaimed tokens
     * @param _recipient address to claim back allocation
     * @param _index index of allocation
      */
    function revokeAllocation(address _recipient, uint _index) external onlyOwner {
        allocations[_recipient][_index].revocable = true;
        uint revokedAllocation = allocations[_recipient][_index].totalAllocated - allocations[_recipient][_index].amountClaimed;
        grandTotalAllocated -= revokedAllocation;
        require(token.transfer(msg.sender, revokedAllocation), "Token transfer failed");
    }
}