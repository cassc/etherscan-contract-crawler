// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

/// @dev Abstract contract used in the 'NFTDataOperator' contract.
abstract contract INFTDataOperator {

    // -----------------------------------------------------------------------
    //                                Errors
    // -----------------------------------------------------------------------
    
    error Unauthorized();

    error MaxCapMustBeGreaterThanMinCap();

    error MinCapMustBeLowerThanMaxCap();

    // -----------------------------------------------------------------------
    //                               Structs
    // -----------------------------------------------------------------------

    /// @dev Used in 'fulfillTholPerNft' function as parameter.
    struct Request {
        /// @dev Current NFT collection floor price in WETH.
        uint128 currentFloorPrice;
        /// @dev NFT collection floor price 30 days ago in WETH.
        uint128 previousFloorPrice;
        /// @dev NFT collection volume in current month (0 - 30 days ago) in WETH.
        uint128 currentVolume;
        /// @dev NFT collection volume in previous month (30 - 60 days ago) in WETH.
        uint128 previousVolume;
    }

    // -----------------------------------------------------------------------
    //                                Events
    // -----------------------------------------------------------------------

    event LocalMaxPercentageUpdated(int128 value);

    event LocalMinPercentageUpdated(int128 value);

    event TholPerNftFulfilled(uint96 tholPerNft, uint256 timestamp);

    // -----------------------------------------------------------------------
    //                           Public functions
    // -----------------------------------------------------------------------

    // Calculate THOL amount for given WETH amount.
    function calculateWethToThol(uint128 currentFloorPrice) public virtual view returns (uint256 tholAmount);

    // -----------------------------------------------------------------------
    //                          External functions
    // -----------------------------------------------------------------------

    // Calculate and set 'tholPerNft' in the staking contract.
    function fulfillTholPerNft(Request memory request) external virtual;

}