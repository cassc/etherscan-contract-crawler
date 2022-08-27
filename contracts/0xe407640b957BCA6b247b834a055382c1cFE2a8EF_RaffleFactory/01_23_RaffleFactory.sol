// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/Raffle.sol";

/**
 * @dev This contract is used to create new raffles.
 *
 * Uses `AccessControl` to ensure that only accounts with `CREATOR_ROLE` are able to create new raffles.
 *
 * Stores addresses of all created raffles.
 */
contract RaffleFactory is AccessControl {
    event RaffleCreated(address raffleAddress);

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    Raffle[] private _raffles;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CREATOR_ROLE, msg.sender);
    }

    /**
     * @dev Creates a new raffle.
     *
     * Emits a {RaffleCreated} event.
     */
    function createRaffle(
        address owner,
        address nftContract,
        uint256 nftTokenId,
        uint256 nftStandardId,
        uint16 tickets,
        uint256 ticketPrice,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint64 vrfSubscriptionId,
        address vrfCoordinator,
        bytes32 vrfKeyHash
    ) external {
        require(owner != address(0), "Owner cannot be 0x0");
        require(hasRole(CREATOR_ROLE, msg.sender), "Must have CREATOR_ROLE");

        Raffle raffle = new Raffle(
            nftContract,
            nftTokenId,
            nftStandardId,
            tickets,
            ticketPrice,
            startTimestamp,
            endTimestamp,
            vrfSubscriptionId,
            vrfCoordinator,
            vrfKeyHash
        );
        _raffles.push(raffle);

        emit RaffleCreated(address(raffle));

        raffle.transferOwnership(owner);
    }

    /**
     * @dev Returns raffles address by given index.
     */
    function getRaffle(uint256 index) public view returns (Raffle) {
        return _raffles[index];
    }

    /**
     * @dev Get number of created raffles.
     */
    function getRaffleCount() public view returns (uint256) {
        return _raffles.length;
    }
}