// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * DonationFacetLib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * DonationFacet - it facilitates diamond storage and shared
 * functionality.
/**************************************************************/

library DonationFacetLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("auctionfacet.storage");
    
    // Struct for all variables required in AuctionFacet
    struct state {
        uint8 donationState;
        uint256 minimumDonation;
        address treasureContract;
        address[] bidders;

        mapping(address => uint256) donation;
    }

    /**
     * @dev Return stored state struct
     */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly{
            _state.slot := position
        }
    }
}

/**************************************************************\
 * DonationFacet authored by Sibling Labs
 * Version 0.1.0
 * 
 * This facet contract has been written specifically for
 * Frog Project
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";

contract DonationFacet {

    /**
     * @dev struct to structure leaderboard
     */
    struct donation {
        address bidder;
        uint256 amount;
    }

    // GETTER FUNCTIONS //
    
    /**
     * @dev used to check whether donation is active or not
     * @return bool returns true if donation is active, otherwise false
     */
    function isDonationActive() external view returns (bool) {
        return DonationFacetLib.getState().donationState == 0 ? false : true; 
    }

    /**
     * @dev used to get address where all the eth is sent and stored
     * @return address returns the address where it is stored
     */
    function treasureContract() external view returns (address) {
        return DonationFacetLib.getState().treasureContract;
    }

    /**
     * @dev used to get minium donation requirement
     * @return uint256 minimum donation set by admins
     */
    function minimumDonation() external view returns (uint256) {
        return DonationFacetLib.getState().minimumDonation;
    }

    // SETTER & ADMINS FUNCTIONS //

    /**
     * @dev admins can use to update treasureContract
     * @param _treasureContract address to which treasureContract to be set to
     */
    function setTreasureContract(address _treasureContract) external {
        GlobalState.requireCallerIsAdmin();
        DonationFacetLib.getState().treasureContract = _treasureContract;
    }

    /**
     * @dev admins can use to toggle donation state controlling donation
     */
    function toggleDonationState() external {
        GlobalState.requireCallerIsAdmin();
        DonationFacetLib.state storage s = DonationFacetLib.getState();
        s.donationState = s.donationState == 0 ? 1 : 0;
    }

    /**
     * @dev admins can update minimum donation limit set for new donaters
     * @param _minimumDonation new minimum donation admin wants to set
     */
    function setMinimumDonation(uint256 _minimumDonation) external {
        GlobalState.requireCallerIsAdmin();
        DonationFacetLib.getState().minimumDonation = _minimumDonation;
    }

    /**
     * @dev admins can use this to retrieve any eth stored in the contract
     */
    function withdraw() external {
        GlobalState.requireCallerIsAdmin();
        DonationFacetLib.getState().treasureContract.call{value: address(this).balance}("");
    }
 
    // PUBLIC FUNCTIONS //

    /**
     * @dev allows user to donate
     * @param amount amout of eth that sender what's to donate
     */
    function ruggMeDaddy(uint256 amount) external payable {
        DonationFacetLib.state storage s = DonationFacetLib.getState();
        require(s.donationState == 1, "DonationFacet: donation is not acitve right now");
        bool alreadyBidder = alreadyBid(msg.sender);
        if(!alreadyBidder) {
            require(amount > s.minimumDonation, "DonationFacet: cannot donate less than minimum");
            s.bidders.push(msg.sender);
        }
        require(amount == msg.value, "DonationFacet: invalid amount sent");
        sendEther();
        s.donation[msg.sender] += amount;
    }

    // LEADERBOARD FUNCTIONS //

    /**
     * @dev returns leaderboard of all donations, sorted
     */
    function leaderBoard() external view returns (donation[] memory) {
        DonationFacetLib.state storage s = DonationFacetLib.getState();
        uint256 numberOfBidders = s.bidders.length;
        if(numberOfBidders == 0) {
            return new donation[](0);
        }
        donation[] memory leaderboard = new donation[](numberOfBidders);
        for(uint256 i; i < numberOfBidders;) {
            address currentBidder = s.bidders[i];
            leaderboard[i].bidder = currentBidder;
            leaderboard[i].amount = s.donation[currentBidder];
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
        return DonationFacetLib.getState().donation[bidder] != 0;
    }

    /**
     * @dev transfers msg.value to treasureContract and requires it's success
     */
    function sendEther() internal {
        (bool sent,) = DonationFacetLib.getState().treasureContract.call{value: msg.value}("");
        require(sent, "DonationFacet: eth transfer failed");
    }

}