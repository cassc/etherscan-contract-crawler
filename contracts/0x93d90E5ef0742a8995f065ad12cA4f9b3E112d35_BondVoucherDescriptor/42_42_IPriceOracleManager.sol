// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPriceOracleManager {
    
    function getPriceOfMaturity(address voucher_, address fundCurrency_, uint64 maturity_)
        external
        view
        returns (int256 price_);

    function getPriceOfSlot(address voucher_, uint256 slot_) 
        external 
        view 
        returns (int256 price_);

    function getPriceOfTokenId(address voucher_, uint256 tokenId_)
        external
        view
        returns (int256 price_);
}