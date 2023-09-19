// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Input, Bid} from "../lib/BidStructs.sol";

interface IPunksBids {
    /**
     * @dev Get the current nonce of a wallet
     * @param wallet Wallet address
     * @return The current nonce of the wallet
     */
    function nonces(address wallet) external view returns (uint256);

    /**
     * @dev Unpause PunksBids smart contract - bids can only be executed while unpaused
     */
    function unpause() external;

    /**
     * @dev Pause PunksBids smart contract - No bid can be executed while paused
     */
    function pause() external;

    /**
     * @dev Cancel a Bid
     * @param bid Bid
     */
    function cancelBid(Bid calldata bid) external;

    /**
     * @dev Cancel Bids
     * @param bids Bids
     */
    function cancelBids(Bid[] calldata bids) external;

    /**
     * @dev Increment the nonce of msg.sender
     */
    function incrementNonce() external;

    /**
     * @dev Execute a match between a Bid and a Punk
     * @param buy Input of a Bid and its matching signature
     * @param punkIndex Punk Index
     */
    function executeMatch(Input calldata buy, uint256 punkIndex) external;
}