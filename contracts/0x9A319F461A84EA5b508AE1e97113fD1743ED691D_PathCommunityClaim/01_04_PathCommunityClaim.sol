pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PathCommunityClaim is Ownable{

    IERC20 immutable private token;

    uint public grandTotalClaimed = 0;

    uint private totalAllocated;

    struct Allocation {
        uint startVesting; // End vesting 
        uint endVesting; // End vesting 
        uint totalAllocated; // Total tokens allocated
        uint amountClaimed;  // Total tokens claimed
    }

    mapping (address => Allocation) public allocations;

    event claimedToken(address indexed _recipient, uint tokensClaimed, uint totalClaimed);

    constructor (address _tokenAddress) {
        token = IERC20(_tokenAddress);
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
                newClaimAmount = ((allocations[_recipient].totalAllocated)
                	* (block.timestamp - allocations[_recipient].startVesting))
                    / (allocations[_recipient].endVesting - allocations[_recipient].startVesting);

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
        uint[] memory _totalAllocated,
        uint[] memory _startVesting,
        uint[] memory _endVesting) onlyOwner external {
        //make sure that the length of address and total minted is the same
        require(_addresses.length == _totalAllocated.length, "length of array should be the same");
        require(_addresses.length == _startVesting.length, "length of array should be the same");
        require(_addresses.length == _endVesting.length, "length of array should be the same");
        uint amountToTransfer;
        for (uint i = 0; i < _addresses.length; i++ ) {
            allocations[_addresses[i]] = Allocation(
                _startVesting[i],
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
        require(allocations[_recipient].startVesting <= block.timestamp, "Start time of claim should be later than start of vesting time");
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