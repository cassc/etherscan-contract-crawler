// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Initial is Ownable {
    mapping(address => uint256) public whitelistedCommunitySlug; // max amount allowed for an address
    mapping(address => uint256) public receivedCommunitySlug; // amount received by an address
    bool public paused;
    address public caller; // ERC20 contract

    constructor() {
        paused = true;
    }

    /////////////////////////
    // initial access control
    /////////////////////////
    modifier onlyCaller() {
        require(msg.sender == caller, "Initial: not the ERC20 contract caller");
        _;
    }

    function changeCaller(address _caller) external onlyOwner {
        caller = _caller;
    }

    function setPaused(bool status) external onlyOwner {
        paused = status;
    }

    /////////////////////////
    // whitelist community members
    /////////////////////////
    function whitelistCommunity(address[] calldata members, uint256[] calldata maxAmounts) external onlyOwner {
        require(members.length == maxAmounts.length, "Initial: members and maxAmounts arrays must have the same length");

        for (uint256 i = 0; i < members.length; i++) {
            whitelistedCommunitySlug[members[i]] = maxAmounts[i];
        }
    }

    /////////////////////////
    // function to be called by ERC20 contract
    /////////////////////////
    function initial(address from, address to, uint256 amount) external onlyCaller {
        if (paused && from == owner()) {
            // Allow owner to transact when paused (to add liquidity and transfer)
            return;
        }

        require(!paused, "Initial: transfers are paused");

        // Check if the receiver is within their allowed limit
        if (whitelistedCommunitySlug[to] > 0) {
            receivedCommunitySlug[to] += amount;
            require(receivedCommunitySlug[to] <= whitelistedCommunitySlug[to], "Initial: amount exceeds allowed limit");

        } else {
            // If not whitelisted, they cannot receive tokens
            require(from == owner(), "Initial: transfers not allowed");
        }
    }
}