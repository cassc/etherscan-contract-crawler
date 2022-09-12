// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "lil-nouns/NounsAuctionHouse.sol";
import "lil-nouns/NounsToken.sol";
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

    // Receive
    receive() external payable {}

    // Owner interface
    /**
     * @notice Collect the ether sent the contract
     * @dev Owner only
     */
    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            new bytes(0)
        );
        require(sent, "Withdraw failed");
    }

    // Public interface
    /**
     * @notice Settle the current Lil Nouns auction, mint the next Lil Noun, and
     * start the next auction if possible.
     * @param expectedParentBlockhash is the expected value of the previous block's hash.
     * If the previous block's hash is not the same as expectedParentBlockhash, the
     * transaction will be immediately reverted, and no auction will be started,
     * as it means an unexpected noun would be minted.
     */
    function settleAuction(bytes32 expectedParentBlockhash) external payable {
        require(
            blockhash(block.number - 1) == expectedParentBlockhash,
            "Lil Noun expired"
        );
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
     * @dev This function allows for the calculation of the SVG in a single eth_call
     * @return parent blockhash (blockhash of the previous block), the next nounId,
     * the next Lil Noun's SVG image, the current auction state, and next noun seed
     */
    function fetchNextNoun()
        external
        view
        returns (
            bytes32,
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
        nounId += 1;

        // Generate the seed for the next nounId
        INounsSeeder.Seed memory nextNounSeed = seeder.generateSeed(
            nounId,
            descriptor
        );

        // Generate the SVG from seed using the descriptor
        string memory svg = descriptor.generateSVGImage(nextNounSeed);
        return (
            blockhash(block.number - 1),
            nounId,
            svg,
            auctionState,
            nextNounSeed
        );
    }
}