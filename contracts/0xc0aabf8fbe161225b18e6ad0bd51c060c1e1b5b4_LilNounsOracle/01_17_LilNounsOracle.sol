// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "lil-nouns/interfaces/INounsAuctionHouse.sol";
import "lil-nouns/NounsAuctionHouse.sol";
import "lil-nouns/interfaces/INounsSeeder.sol";
import "lil-nouns/interfaces/INounsDescriptor.sol";

// Use alias in order to resolve naming collisions with a
// different Ownable version used by NounsDescriptor
import "openzeppelin-contracts/contracts/access/Ownable.sol" as OpenZeppelinAccess;

/**
 * @title LilNounsOracle
 * @author nvonpentz
 * @notice LilNounsOracle exposes an endpoint for retrieving the SVG
 * image of the next Lil Noun, and provides a way to start auctions with the guarantee
 * the expected Lil Noun is minted.
 */
contract LilNounsOracle is OpenZeppelinAccess.Ownable {
    NounsAuctionHouse public AuctionHouse;
    INounsSeeder public Seeder;
    INounsDescriptor public Descriptor;
    uint256 public _feeAmount;

    enum AuctionState {
        NOT_STARTED,
        ACTIVE,
        OVER_NOT_SETTLED,
        OVER_AND_SETTLED
    }

    constructor(
        address auctionHouseAddress,
        address seederAddress,
        address descriptorAddress
    ) {
        AuctionHouse = NounsAuctionHouse(auctionHouseAddress);
        Seeder = INounsSeeder(seederAddress);
        Descriptor = INounsDescriptor(descriptorAddress);
    }

    // Receive
    receive() external payable {}

    // Owner interface
    /**
     * @notice Set the fee required to mint through the LilNounsOracle
     * @dev Owner only
     */
    function setFeeAmount(uint256 feeAmount_) external onlyOwner {
        _feeAmount = feeAmount_;
    }

    /**
     * @notice Collect the ether sent the contract
     * @dev Owner only
     */
    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            new bytes(0)
        );
        require(sent, "Withdraw failed.");
    }

    // Public interface
    /**
     * @notice Settle the current Lil Nouns auction, mint the next Lil Noun, and
     * start the next auction if possible.
     * @param invalidAfter is the largest block number for which the transaction is
     * considered valid. If the block.number is greater than invalidAfter when the
     * transaction is processed, it will be immediately reverted, and the Oracle
     * will not attempt to start the auction.
     */
    function settleCurrentAndCreateNewAuction(uint256 invalidAfter)
        external
        payable
    {
        require(
            block.number <= invalidAfter,
            "Refused to start auction: desired Lil Noun expired."
        );
        require(
            msg.value >= _feeAmount,
            "Refused to start auction: fee too low"
        );
        AuctionHouse.settleCurrentAndCreateNewAuction();
    }

    /**
     * @notice Fetch the current auction state and generate the SVG image of
     * the next Lil Noun if it were minted in the current block.
     * @dev This function allows for the calculation of the SVG in a single eth_call
     * @return current block.number, the next nounId, the next Lil Noun's SVG image,
     * and the current auction state
     */
    function fetchNextNounAndAuctionState()
        external
        view
        returns (
            uint256,
            uint256,
            string memory,
            AuctionState
        )
    {
        // Fetch the nounId and auction state
        (
            uint256 nextNounId,
            AuctionState auctionState
        ) = _fetchNextNounIdAndAuctionState();

        // Generate the seed for the next nounId
        INounsSeeder.Seed memory nextNounSeed = Seeder.generateSeed(
            nextNounId,
            Descriptor
        );

        // Generate the SVG from seed using the Descriptor
        string memory svg = Descriptor.generateSVGImage(nextNounSeed);

        return (block.number, nextNounId, svg, auctionState);
    }

    function _fetchNextNounIdAndAuctionState()
        internal
        view
        returns (uint256, AuctionState)
    {
        // Fetch current auction from the AuctionHouse
        (
            uint256 nounId,
            ,
            uint256 startTime,
            uint256 endTime,
            ,
            bool settled
        ) = AuctionHouse.auction();

        // Determine auction state
        AuctionState auctionState;
        if (startTime == 0) {
            auctionState = AuctionState.NOT_STARTED;
        } else if (settled) {
            auctionState = AuctionState.OVER_AND_SETTLED;
        } else if (block.timestamp < endTime) {
            auctionState = AuctionState.ACTIVE;
        } else {
            auctionState = AuctionState.OVER_NOT_SETTLED;
        }

        return (nounId + 1, auctionState);
    }
}