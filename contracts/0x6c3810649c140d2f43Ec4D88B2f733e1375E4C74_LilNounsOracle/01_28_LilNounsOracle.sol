// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "lil-nouns/NounsAuctionHouse.sol";
import "lil-nouns/NounsToken.sol";
import "lil-nouns/interfaces/INounsSeeder.sol";
import "lil-nouns/interfaces/INounsDescriptor.sol";

/**
 * @title LilNounsOracle
 * @author nvonpentz
 * @notice LilNounsOracle exposes an endpoint for previewing the next Lil Noun
 * and provides a way to start auctions with the guarantee the expected Lil Noun
 * is minted.
 */
contract LilNounsOracle {
    NounsToken public lilNounsToken;
    NounsAuctionHouse public auctionHouse;
    INounsSeeder public seeder;
    INounsDescriptor public descriptor;

    enum AuctionState {
        NOT_STARTED,
        ACTIVE,
        OVER_NOT_SETTLED,
        OVER_AND_SETTLED
    }

    constructor(
        address lilNounsTokenAddress,
        address auctionHouseAddress,
        address seederAddress,
        address descriptorAddress
    ) {
        lilNounsToken = NounsToken(lilNounsTokenAddress);
        auctionHouse = NounsAuctionHouse(auctionHouseAddress);
        seeder = INounsSeeder(seederAddress);
        descriptor = INounsDescriptor(descriptorAddress);
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
    function settleAuction(uint256 invalidAfter) external {
        require(block.number <= invalidAfter, "Lil Noun expired.");
        auctionHouse.settleCurrentAndCreateNewAuction();
    }

    /**
     * @notice Update the descriptor, seeder, and auctionHouse contract addresses
     * to those used by the Lil Nouns token contract in case they have changed.
     */
    function refreshContractAddresses() external {
        auctionHouse = NounsAuctionHouse(lilNounsToken.minter());
        seeder = INounsSeeder(lilNounsToken.seeder());
        descriptor = INounsDescriptor(lilNounsToken.descriptor());
    }

    /**
     * @notice Fetch the current auction state and generate the SVG image of
     * the next Lil Noun if it were minted in the current block.
     * @dev This function should be called with 'pending' blockTag to get the
     * correct next noun.
     * @return parent blockhash (blockhash of the previous block), the next nounId,
     * the next Lil Noun's SVG image, the current auction state, and next noun seed
     */
    function fetchNextNoun()
        external
        view
        returns (
            uint256,
            uint256,
            string memory,
            AuctionState,
            INounsSeeder.Seed memory
        )
    {
        // Fetch the nounId and auction state
        (
            uint256 nounId,
            ,
            uint256 startTime,
            uint256 endTime,
            ,
            bool settled
        ) = auctionHouse.auction();
        nounId += 1;

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

        // Generate the seed for the next nounId
        INounsSeeder.Seed memory nextNounSeed = seeder.generateSeed(
            nounId,
            descriptor
        );

        // Generate the SVG from seed using the descriptor
        string memory svg = descriptor.generateSVGImage(nextNounSeed);
        return (block.number, nounId, svg, auctionState, nextNounSeed);
    }
}