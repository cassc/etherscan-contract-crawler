// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./IERC721MultiSaleMultiWallet.sol";
import "../BasicSale.sol";
import "../Sale.sol";
import "../SalesRecord.sol";

abstract contract ERC721MultiSaleMultiWallet is IERC721MultiSaleMultiWallet, BasicSale {
    // ==================================================================
    // Variables
    // ==================================================================
    mapping(uint256 => SalesRecord) internal _salesRecordByBuyer;

    // ==================================================================
    // Modifier
    // ==================================================================
    modifier isNotOverAllowedAmount(uint256 userId, uint256 amount, uint256 allowedAmount) {
        require(
            getBuyCount(userId) + amount <= allowedAmount,
            "claim is over allowed amount."
        );
        _;
    }

    // ==================================================================
    // Function
    // ==================================================================
    // ------------------------------------------------------------------
    // external & public
    // ------------------------------------------------------------------
    function getBuyCount(uint256 userId) public view returns(uint256){
        SalesRecord storage record = _salesRecordByBuyer[userId];

        if (record.id == _currentSale.id) {
            return record.amount;
        } else {
            return 0;
        }
    }

    // ------------------------------------------------------------------
    // internal & private
    // ------------------------------------------------------------------
    function _claim(uint256 userId, uint256 amount, uint256 allowedAmount)
        internal
        virtual
        whenNotPaused
        isNotOverMaxSupply(amount)
        isNotOverMaxSaleSupply(amount)
        isNotOverAllowedAmount(userId, amount, allowedAmount)
        whenClaimSale
    {
        _record(userId, amount);
    }

    function _exchange(uint256 userId, uint256[] calldata burnTokenIds, uint256 allowedAmount)
        internal
        virtual
        whenNotPaused
        isNotOverMaxSaleSupply(burnTokenIds.length)
        isNotOverAllowedAmount(userId, burnTokenIds.length, allowedAmount)
        whenExcahngeSale
    {
        _record(userId, burnTokenIds.length);
    }

    function _record(uint256 userId, uint256 amount) private {
        SalesRecord storage record = _salesRecordByBuyer[userId];

        if (record.id == _currentSale.id) {
            record.amount += amount;
        } else {
            record.id = _currentSale.id;
            record.amount = amount;
        }

        _soldCount += amount;
    }
}