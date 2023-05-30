// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @dev Interface of the OpenOracleFramework contract
 */
interface IOpenOracleFramework {
    /**
    * @dev initialize function lets the factory init the cloned contract and set it up
    *
    * @param signers_ array of signer addresses
    * @param signerThreshold_ the threshold which has to be met for consensus
    * @param payoutAddress_ the address where all fees will be sent to. 0 address for an even split across signers
    * @param subscriptionPassPrice_ the price for an oracle subscription pass
    * @param factoryContract_ the address of the factory contract
    */
    function initialize(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_,
        address factoryContract_
    ) external;

    /**
    * @dev getHistoricalFeeds function lets the caller receive historical values for a given timestamp
    *
    * @param feedIDs the array of feedIds
    * @param timestamps the array of timestamps
    */
    function getHistoricalFeeds(uint256[] memory feedIDs, uint256[] memory timestamps) external view returns (uint256[] memory);

    /**
    * @dev getFeeds function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedIDs the array of feedIds
    */
    function getFeeds(uint256[] memory feedIDs) external view returns (uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    * @dev getFeed function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedID the array of feedId
    */
    function getFeed(uint256 feedID) external view returns (uint256, uint256, uint256);

    /**
    * @dev getFeedList function returns the metadata of a feed
    *
    * @param feedIDs the array of feedId
    */
    function getFeedList(uint256[] memory feedIDs) external view returns(string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    * @dev withdrawFunds function sends the collected fees to the given address
    */
    function withdrawFunds() external;

    /**
    * @dev creates new oracle data feeds
    *
    * @param names the names of the new feeds
    * @param descriptions the description of the new feeds
    * @param decimals the decimals of the new feeds
    * @param timeslots the timeslots of the new feeds
    * @param feedCosts the costs of the new feeds
    * @param revenueModes the revenue modes of the new feeds
    */
    function createNewFeeds(string[] memory names, string[] memory descriptions, uint256[] memory decimals, uint256[] memory timeslots, uint256[] memory feedCosts, uint256[] memory revenueModes) external;

    /**
    * @dev submits multiple feed values
    *
    * @param feedIDs the array of feedId
    * @param values the values to submit
    */
    function submitFeed(uint256[] memory feedIDs, uint256[] memory values) external;

    /**
    * @dev signs a given proposal
    *
    * @param proposalId the id of the proposal
    */
    function signProposal(uint256 proposalId) external;

    /**
    * @dev creates a new proposal
    *
    * @param uintValue value in uint representation
    * @param addressValue value in address representation
    * @param proposalType type of the proposal
    * @param feedId the feed id if needed
    */
    function createProposal(uint256 uintValue, address addressValue, uint256 proposalType, uint256 feedId) external;

    /**
    * @dev buys a subscription to a feed
    *
    * @param feedIDs the feeds to subscribe to
    * @param durations the durations to subscribe
    * @param buyer the address which should be subscribed to the feeds
    */
    function subscribeToFeed(uint256[] memory feedIDs, uint256[] memory durations, address buyer) payable external;

    /**
    * @dev buys a subscription pass for the oracle
    *
    * @param buyer the address which owns the pass
    * @param duration the duration to subscribe
    */
    function buyPass(address buyer, uint256 duration) payable external;

    /**
    * @dev supports given Feeds
    *
    * @param feedIds the array of feeds to support
    * @param values the array of amounts of ETH to send to support
    */
    function supportFeeds(uint256[] memory feedIds, uint256[] memory values) payable external;
}