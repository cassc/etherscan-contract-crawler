pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PathPrivateBClaim is Ownable{

    IERC20 immutable private token;

    uint public grandTotalClaimed = 0;
    uint immutable public startTime;

    uint private totalAllocated;
    

    struct Allocation {
        uint TGEAllocation; //tokens allocateed at TGE
        uint initialAllocation; //Initial token allocated after first cliff
        uint endInitial; // Initial token claim locked until 
        uint endCliff; // Vested Tokens are locked until
        uint endVesting; // End vesting 
        uint totalAllocated; // Total tokens allocated
        uint amountClaimed;  // Total tokens claimed
    }

    mapping (address => Allocation) public allocations;

    event claimedToken(address indexed _recipient, uint tokensClaimed, uint totalClaimed);

    constructor (address _tokenAddress, uint _startTime) {
        require(_startTime >= 1638896400, "start time should be larger or equal to TGE");
        token = IERC20(_tokenAddress);
        startTime = _startTime;
    }

    function getClaimTotal(address _recipient) public view returns (uint amount) {
        return  calculateClaimAmount(_recipient) - allocations[_recipient].amountClaimed;
    }

    // view function to calculate claimable tokens
    function calculateClaimAmount(address _recipient) internal view returns (uint amount) {
         uint newClaimAmount;

        if (block.timestamp >= allocations[_recipient].endVesting) {
            newClaimAmount = allocations[_recipient].totalAllocated;
        }
        else {
            newClaimAmount = allocations[_recipient].TGEAllocation;
            if (block.timestamp >=  allocations[_recipient].endInitial) {
                newClaimAmount += allocations[_recipient].initialAllocation;
            }
            if (block.timestamp >= allocations[_recipient].endCliff) {
                newClaimAmount += ((allocations[_recipient].totalAllocated - allocations[_recipient].initialAllocation - allocations[_recipient].TGEAllocation)
                	* (block.timestamp - allocations[_recipient].endCliff))
                    / (allocations[_recipient].endVesting - allocations[_recipient].endCliff);
            }
        }
        return newClaimAmount;
    }

    /**
    * @dev Set the minters and their corresponding allocations. Each mint gets 40000 Path Tokens with a vesting schedule
    * @param _addresses The recipient of the allocation
    * @param _totalAllocated The total number of minted NFT
    */
    function setAllocation(
        address[] memory _addresses,
        uint[] memory _TGEAllocation,
        uint[] memory _totalAllocated,
        uint[] memory _initialAllocation,
        uint[] memory _endInitial,
        uint[] memory _endCliff,
        uint[] memory _endVesting) onlyOwner external {
        //make sure that the length of address and total minted is the same
        require(_addresses.length == _totalAllocated.length, "length of array should be the same");
        require(_addresses.length == _initialAllocation.length, "length of array should be the same");
        require(_addresses.length == _endInitial.length, "length of array should be the same");
        require(_addresses.length == _endCliff.length, "length of array should be the same");
        require(_addresses.length == _endVesting.length, "length of array should be the same");
        uint amountToTransfer;
        for (uint i = 0; i < _addresses.length; i++ ) {
            require(_endInitial[i] <= _endCliff[i], "Initial claim should be earlier than end cliff time");
            allocations[_addresses[i]] = Allocation(
                _TGEAllocation[i],
                _initialAllocation[i],
                _endInitial[i],
                _endCliff[i],
                _endVesting[i],
                _totalAllocated[i],
                0);
            amountToTransfer += _totalAllocated[i];
            totalAllocated += _totalAllocated[i];
        }
        require(token.transferFrom(msg.sender, address(this), amountToTransfer), "Token transfer failed");
    }

    /**
    * @dev Check current claimable amount
    * @param _recipient recipient of allocation
     */
    function getRemainingAmount (address _recipient) external view returns (uint amount) {
        return allocations[_recipient].totalAllocated - allocations[_recipient].amountClaimed;
    }


     /**
     * @dev transfers allocated tokens to recipient to their address
     * @param _recipient the addresss to withdraw tokens for
      */
    function transferTokens(address _recipient) external {
        require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated, "Address should have some allocated tokens");
        require(startTime <= block.timestamp, "Start time of claim should be later than current time");
        require(startTime <= allocations[_recipient].endInitial, "Initial claim should be later than current time");
        //transfer tokens after subtracting tokens claimed
        uint newClaimAmount = calculateClaimAmount(_recipient);
        uint tokensToClaim = getClaimTotal(_recipient);
        require(tokensToClaim > 0, "Recipient should have more than 0 tokens to claim");
        allocations[_recipient].amountClaimed = newClaimAmount;
        grandTotalClaimed += tokensToClaim;
        require(token.transfer(_recipient, tokensToClaim), "Token transfer failed");
        emit claimedToken(_recipient, tokensToClaim, allocations[_recipient].amountClaimed);
    }

    //owner restricted functions
    /**
     * @dev reclaim excess allocated tokens for claiming
     * @param _amount the amount to withdraw tokens for
      */
    function reclaimExcessTokens(uint _amount) external onlyOwner {
        require(_amount <= token.balanceOf(address(this)) - (totalAllocated - grandTotalClaimed), "Amount of tokens to recover is more than what is allowed");
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }
}