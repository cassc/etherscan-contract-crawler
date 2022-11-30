//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./utils/Withdrawable.sol";

contract Auction is Ownable, Withdrawable {
    uint256 public startTimestamp;

    /// @notice maximum time (in seconds) to submit an offer from the start of the lot
    uint256 public batchLifetime = 2 hours;

    bytes32 public whitelistRoot;

    uint256 public offersSold;

    mapping(address => bool) public currencies;

    event OfferAccepted(uint256 index, uint256 indexed lotKey, address indexed account, uint256 amount, uint256 timestamp);

    modifier onlyWhitelisted(bytes32[] memory proof) {
        bool whitelistIsRequired = whitelistRoot != bytes32(0);

        require(!whitelistIsRequired || MerkleProof.verify(proof, whitelistRoot, keccak256(abi.encode(_msgSender()))), "Account is not whitelisted");
        _;
    }

    /* Configuration
     ****************************************************************/

    function schedule(uint256 startTimestamp_, uint256 batchLifetime_) external onlyOwner {
        startTimestamp = startTimestamp_;
        batchLifetime = batchLifetime_;
    }

    function setWhitelistRoot(bytes32 whitelistRoot_) external onlyOwner {
        whitelistRoot = whitelistRoot_;
    }

    function enableCurrency(address currency) external onlyOwner {
        currencies[currency] = true;
    }

    function disableCurrency(address currency) external onlyOwner {
        currencies[currency] = false;
    }

    /* Utils
     ****************************************************************/

    function isAvailableCurrency(address currency) public view returns (bool) {
        return currencies[currency];
    }

    function getCurrentBatchIndex() public view returns (uint256) {
        require(startTimestamp != 0 && block.timestamp >= startTimestamp, "Auction not started");

        if (batchLifetime == 0) return 0;

        return (block.timestamp - startTimestamp) / batchLifetime;
    }

    function getBatchForTimestamp(uint256 timestamp) internal view returns (uint256 batchZeroIndex) {
        require(startTimestamp != 0 && timestamp >= startTimestamp, "Auction not started");

        if (batchLifetime == 0) return 0;

        return (timestamp - startTimestamp) / batchLifetime;
    }
}