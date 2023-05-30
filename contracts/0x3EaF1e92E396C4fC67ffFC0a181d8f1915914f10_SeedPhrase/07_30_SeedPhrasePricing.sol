// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../core/NilPassCore.sol";

abstract contract SeedPhrasePricing is NilPassCore {
    uint256 preSalePrice;
    uint256 publicSalePrice;

    constructor(
        string memory name,
        string memory symbol,
        IN n,
        DerivativeParameters memory derivativeParams,
        uint256 preSalePrice_,
        uint256 publicSalePrice_,
        address masterMint,
        address dao
    ) NilPassCore(name, symbol, n, derivativeParams, masterMint, dao) {
        preSalePrice = preSalePrice_;
        publicSalePrice = publicSalePrice_;
    }

    enum PreSaleType {
        GenesisSketch,
        OG,
        GM,
        Karma,
        N,
        None
    }

    function _canMintPresale(
        address addr,
        uint256 amount,
        bytes memory data
    ) internal view virtual returns (bool, PreSaleType);

    function _isPublicSaleActive() internal view virtual returns (bool);

    /**
     * @notice Returns the next price for an N mint
     */
    function getNextPriceForNHoldersInWei(
        uint256 numberOfMints,
        address account,
        bytes memory data
    ) public view override returns (uint256) {
        (bool preSaleEligible, ) = _canMintPresale(account, numberOfMints, data);
        uint256 price = preSaleEligible && !_isPublicSaleActive() ? preSalePrice : publicSalePrice;
        return numberOfMints * price;
    }

    /**
     * @notice Returns the next price for an open mint
     */
    function getNextPriceForOpenMintInWei(
        uint256 numberOfMints,
        address account,
        bytes memory data
    ) public view override returns (uint256) {
        (bool preSaleEligible, ) = _canMintPresale(account, numberOfMints, data);
        uint256 price = preSaleEligible && !_isPublicSaleActive() ? preSalePrice : publicSalePrice;
        return numberOfMints * price;
    }
}