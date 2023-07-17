// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../core/NilPassCore.sol";

abstract contract UnfoldrianPricing is NilPassCore {
    uint256 nPrice;
    uint256 openPrice;

    constructor(
        string memory name,
        string memory symbol,
        IN n,
        DerivativeParameters memory derivativeParams,
        uint256 nPrice_,
        uint256 openPrice_,
        address masterMint,
        address dao
    ) NilPassCore(name, symbol, n, derivativeParams, masterMint, dao) {
        nPrice = nPrice_;
        openPrice = openPrice_;
    }

    /**
     * @notice Returns the next price for an N mint
     */
    function getNextPriceForNHoldersInWei(
        uint256 numberOfMints,
        address,
        bytes memory
    ) public view virtual override returns (uint256) {
        return numberOfMints * nPrice;
    }

    /**
     * @notice Returns the next price for an open mint
     */
    function getNextPriceForOpenMintInWei(
        uint256 numberOfMints,
        address,
        bytes memory
    ) public view virtual override returns (uint256) {
        return numberOfMints * openPrice;
    }
}