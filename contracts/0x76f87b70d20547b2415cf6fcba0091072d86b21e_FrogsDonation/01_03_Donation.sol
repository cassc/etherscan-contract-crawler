//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FrogsDonation is Ownable {

    // State Variables //

    uint8 private donationState;
    uint256 public minimumDonation = 0.0069 ether;
    address public treasureContract = 0x34a2989271fe71B27A10AD1d563a3cEa565f2D74;
    address[] private donors;

    mapping(address => uint256) public donations;

    // Struct to structure leaderboard data
    struct donation {
        address donor;
        uint256 amount;
    }

    // GETTER FUNCTIONS //

    /**
     * @dev used to check whether donation is active or not
     * @return bool returns true if donation is active, otherwise false
     */
    function isDonationActive() external view returns (bool) {
        return donationState == 0 ? true : false;
    }

    // ADMIN & SETUP FUNCTIONS //
    
    /**
     * @dev admins can use to toggle donation state controlling donation
     */
    function toggleDonationState() external onlyOwner {
        donationState = donationState == 0 ? 1 : 0;
    }

    /**
     * @dev admins can use to update treasureContract
     * @param _treasureContract address to which treasureContract to be set to
     */
    function setTreasureContract(address _treasureContract) external onlyOwner {
        treasureContract = _treasureContract;
    }

    /**
     * @dev admins can update minimum donation limit set for new donaters
     * @param _minimumDonation new minimum donation admin wants to set
     */
    function setMinimumDonation(uint256 _minimumDonation) external onlyOwner {
        minimumDonation = _minimumDonation;
    }

    // PUBLIC FUNCTIONS //

    /**
     * @dev allows user to donate
     * @param amount amout of eth that sender what's to donate
     */
    function ruggMeDaddy(uint256 amount) external payable {
        require(donationState == 0, "donation is not acitve right now");
        bool alreadyBidder = alreadyBid(msg.sender);
        if(!alreadyBidder) {
            require(amount >= minimumDonation, "cannot donate less than minimum");
            donors.push(msg.sender);
        }
        require(amount == msg.value, "invalid amount sent");
        sendEther();
        donations[msg.sender] += amount;
    }

    /**
     * @dev returns leaderboard of all donations, sorted
     */
    function leaderBoard() external view returns (donation[] memory) {
        uint256 numberOfBidders = donors.length;
        if(numberOfBidders == 0) {
            return new donation[](0);
        }
        donation[] memory leaderboard = new donation[](numberOfBidders);
        for(uint256 i; i < numberOfBidders;) {
            address currentDonor = donors[i];
            leaderboard[i].donor = currentDonor;
            leaderboard[i].amount = donations[currentDonor];
            unchecked{
                i++;
            }
        }

        for(uint256 i; i < numberOfBidders - 1;) {
            for(uint256 j; j < numberOfBidders - i - 1;) {
                if(leaderboard[j].amount < leaderboard[j + 1].amount) {
                    (leaderboard[j], leaderboard[j + 1]) = (leaderboard[j + 1], leaderboard[j]);
                }
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
        return leaderboard;
    }

    // MISC. & INTERNAL FUNCTIONS //

    /**
     * @dev checks whether given address has already bid or not
     * @param bidder address which you want to check
     */
    function alreadyBid(address bidder) internal view returns (bool) {
        return donations[bidder] != 0;
    }

    /**
     * @dev transfers msg.value to treasureContract and requires it's success
     */
    function sendEther() internal {
        (bool sent,) = treasureContract.call{value: msg.value}("");
        require(sent, "eth transfer failed");
    }
}