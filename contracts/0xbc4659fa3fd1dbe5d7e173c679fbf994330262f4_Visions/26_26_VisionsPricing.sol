// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../core/NilPassCore.sol";

 abstract contract VisionsPricing is NilPassCore {

    uint256 price;

    constructor(
        string memory name,
        string memory symbol,
        IN n,
        DerivativeParameters memory derivativeParams,
        uint256 price_,
        address masterMint,
        address dao
    )
    NilPassCore(
        name,
        symbol,
        n,
        derivativeParams,
        masterMint,
        dao
    )
    {
        price = price_;
    }

    /**
     * @notice Returns the next price for an N mint
     */
    function getNextPriceForNHoldersInWei(uint256 numberOfMints) public virtual override view returns (uint256) {
        return numberOfMints*price;
    }

    /**
     * @notice Returns the next price for an open mint
     */
    function getNextPriceForOpenMintInWei(uint256 numberOfMints) public virtual override view returns (uint256) {
        return numberOfMints*price;
    }
}