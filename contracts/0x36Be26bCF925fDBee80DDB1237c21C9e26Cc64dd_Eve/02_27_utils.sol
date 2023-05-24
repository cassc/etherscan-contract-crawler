// SPDX-License-Identifier: Unlicense
// Version 0.0.1

pragma solidity ^0.8.17;

/**
 * @dev Collection of utility functions
 */
library Utils {
    /**
     * Default admin is zero address
     */
    error AdminIsZeroAddress();

    /**
     * Default owner is zero address
     */
    error OwnerIsZeroAddress();

    /**
     * Royalty is zero
     */
    error RoyaltyIsZero();

    /**
     * The signature is invalid
     */
    error InvalidSignature();

    /**
     * The number of NFTs exceeds the limit
     */
    error NFTQuantityExceedsLimit();

    /**
     * Transfer ownership to zero address
     */
    error TransferOwnershipToZeroAddress();

    /**
     * Unmatched Array lengths
     */
    error UnmatchedArrayLengths();

    /**
     * Contract does not exist at the address
     */
    error ContractDoesNotExist();

    /**
     * Staking Period Is Zero
     */
    error StakingPeriodIsZero();

    /**
     * Quantity Is Zero
     */
    error QuantityIsZero();

    /**
     * Allowed Quantity Is Zero
     */
    error AllowedQuantityIsZero();

    /**
     * Input quantity exceeds allowed quantity
     */
    error ExceedsAllowedQuantity();

    /**
     * The person is not whitelisted
     */
    error NotWhitelisted();

    /**
     * Token Already Staked
     */
    error TokenAlreadyStaked();

    /**
     * Not The Owner Of The Token
     */
    error NotTheOwnerOfTheToken();

    /**
     * Not enough staked Genesis Stones
     */
    error NotEnoughStakedGenesisStones();

    /**
     * Already Minted with the method
     */
    error AlreadyMinted();

    /**
     * Not Staked
     */
    error NotStaked();

    /**
     * Staking Not Completed
     */
    error StakingNotCompleted();

    /**
     * Invalid addrses
     */
    error InvalidAddress();

    /**
     * Token Is Staked
     */
    error TokenIsStaked();

    /**
     * Not A Mythic Stone
     */
    error NotAMythicStone();

    /**
     * Not A Normal Stone
     */
    error NotANormalStone();

    /**
     * Incorrect NFT Id 
     */
    error IncorrectNFTId();

    /**
     * Incorrect Data
     */
    error IncorrectData();

    function contractExists(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }
}