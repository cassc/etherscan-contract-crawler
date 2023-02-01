// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {Auth, Authority} from "solmate/src/auth/Auth.sol";

contract CharlieHelpers is Auth {
    /// @dev The shape of the call.
    struct Call {
        address target;
        bytes callData;
        uint256 value;
    }

    /// @dev The shape of the response.
    struct Response {
        bool success;
        uint256 blockNumber;
        bytes result;
    }

    /// @dev Event used to track when a user calls a function.
    event CharlieCalled(address indexed caller, Response[] results);

    /// @dev Instantiate the ownership of Charlie.
    constructor(address _authority) Auth(msg.sender, Authority(_authority)) {}

    /**
     * @dev Get the balance of an address.
     * @param addr The address to get the balance of.
     * @return balance The balance of the address.
     */
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /**
     * @dev Get the block hash of a block.
     * @param blockNumber The block number to get the hash of.
     * @return blockHash The block hash of the block.
     */
    function getBlockHash(uint256 blockNumber)
        public
        view
        returns (bytes32 blockHash)
    {
        blockHash = blockhash(blockNumber);
    }

    /**
     * @dev Get the block hash of the last block.
     * @return blockHash The block hash of the last block.
     */
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    /**
     * @dev Get the timestamp the chain is running on.
     * @return timestamp The timestamp the chain is running on.
     */
    function getCurrentBlockTimestamp()
        public
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    /**
     * @dev Get the difficulty of the current block.
     * @return difficulty The difficulty of the current block.
     */
    function getCurrentBlockDifficulty()
        public
        view
        returns (uint256 difficulty)
    {
        difficulty = block.difficulty;
    }

    /**
     * @dev Get the gas limit of the current block.
     * @return gaslimit The gas limit of the current block.
     */
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    /**
     * @dev Get the coinbase of the current block.
     * @return coinbase The coinbase of the current block.
     */
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}