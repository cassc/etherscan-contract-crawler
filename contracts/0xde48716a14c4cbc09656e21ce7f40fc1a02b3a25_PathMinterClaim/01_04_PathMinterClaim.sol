pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PathMinterClaim is Ownable{

    IERC20 private immutable token;

    uint256 public grandTotalClaimed = 0;
    uint256 public immutable startTime;
    uint256 public immutable endVesting;

    uint private totalAllocated;

    struct Allocation {
        uint256 initialAllocation; //Initial token allocated
        uint256 totalAllocated; // Total tokens allocated
        uint256 amountClaimed;  // Total tokens claimed
    }

    mapping (address => Allocation) public allocations;

    event claimedToken(address indexed minter, uint tokensClaimed, uint totalClaimed);

    constructor (address _tokenAddress, uint256 _startTime, uint256 _endVesting) {
        require(_startTime <= _endVesting, "start time should be larger than endtime");
        token = IERC20(_tokenAddress);
        startTime = _startTime;
        endVesting = _endVesting;
    }



    function getClaimTotal(address _recipient) public view returns (uint amount) {
        return  calculateClaimAmount(_recipient) - allocations[_recipient].amountClaimed;
    }

    // view function to calculate claimable tokens
    function calculateClaimAmount(address _recipient) internal view returns (uint amount) {
         uint newClaimAmount;

        if (block.timestamp >= endVesting) {
            newClaimAmount = allocations[_recipient].totalAllocated;
        }
        else {
            newClaimAmount = allocations[_recipient].initialAllocation;
            newClaimAmount += ((allocations[_recipient].totalAllocated - allocations[_recipient].initialAllocation) / (endVesting - startTime)) * (block.timestamp - startTime);
        }
        return newClaimAmount;
    }

    /**
    * @dev Set the minters and their corresponding allocations. Each mint gets 40000 Path Tokens with a vesting schedule
    * @param _addresses The recipient of the allocation
    * @param _totalAllocated The total number of minted NFT
    */
    function setAllocation (address[] memory _addresses, uint[] memory _totalAllocated, uint[] memory _initialPercentage) onlyOwner external {
        //make sure that the length of address and total minted is the same
        require(_addresses.length == _totalAllocated.length, "Input array length not match");
        require(_addresses.length == _initialPercentage.length, "Input array length not match");
        uint amountToTransfer;
        for (uint i = 0; i < _addresses.length; i++ ) {
            uint initialAllocation =  _totalAllocated[i] * _initialPercentage[i] / 100;
            allocations[_addresses[i]] = Allocation(initialAllocation, _totalAllocated[i], 0);
            amountToTransfer += _totalAllocated[i];
            totalAllocated += _totalAllocated[i];
        }
        require(token.transferFrom(msg.sender, address(this), amountToTransfer), "Token Transfer Failed");
    }

    /**
    * @dev Get total remaining amount
    * @param _recipient recipient of allocation
     */
    function getRemainingAmount (address _recipient) external view returns (uint amount) {
        return allocations[_recipient].totalAllocated - allocations[_recipient].amountClaimed;
    }

    /**
    * @dev Allows msg.sender to claim their allocated tokens
     */

    function claim() external {
        require(allocations[msg.sender].amountClaimed < allocations[msg.sender].totalAllocated, "Address should have some allocated tokens");
        require(startTime <= block.timestamp, "Start time of claim should be later than current time");
        //transfer tokens after subtracting tokens claimed
        uint newClaimAmount = calculateClaimAmount(msg.sender);
        uint tokensToClaim = getClaimTotal(msg.sender);
        require(tokensToClaim > 0, "Recipient should have more than 0 tokens to claim");
        allocations[msg.sender].amountClaimed = newClaimAmount;
        grandTotalClaimed += tokensToClaim;
        require(token.transfer(msg.sender, tokensToClaim), "Transfer of token failed");
        emit claimedToken(msg.sender, tokensToClaim, allocations[msg.sender].amountClaimed);
    }


     /**
     * @dev transfers allocated tokens to recipient to their address
     * @param _recipient the addresss to withdraw tokens for
      */
    function transferTokens(address _recipient) external {
        require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated, "Address should have some allocated tokens");
        require(startTime <= block.timestamp, "Start time of claim should be later than current time");
        //transfer tokens after subtracting tokens claimed
        uint newClaimAmount = calculateClaimAmount(_recipient);
        uint tokensToClaim = getClaimTotal(_recipient);
        require(tokensToClaim > 0, "Recipient should have more than 0 tokens to claim");
        allocations[_recipient].amountClaimed = newClaimAmount;
        grandTotalClaimed += tokensToClaim;
        require(token.transfer(_recipient, tokensToClaim), "Transfer of token failed");
        emit claimedToken(_recipient, tokensToClaim, allocations[_recipient].amountClaimed);
    }

    //owner restricted functions
    /**
     * @dev reclaim excess allocated tokens for claiming
     * @param _amount the amount to withdraw tokens for
      */
    function reclaimExcessTokens(uint _amount) external onlyOwner {
        require(_amount <= token.balanceOf(address(this)) - (totalAllocated - grandTotalClaimed), "Amount of tokens to recover is more than what is allowed");
        require(token.transfer(msg.sender, _amount), "Transfer of token failed");
    }
}