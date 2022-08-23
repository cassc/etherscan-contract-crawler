// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@solv/v2-solidity-utils/contracts/access/AdminControl.sol";
import "@solv/v2-solidity-utils/contracts/misc/BokkyPooBahsDateTimeLibrary.sol";
import "@solv/v2-solidity-utils/contracts/misc/StringConvertor.sol";
import "@solv/v2-vnft-core/contracts/interface/IVNFT.sol";
import "../interface/IPriceOracleManager.sol";
import "../interface/IPriceOracle.sol";
import "../interface/IBondVoucher.sol";

contract PriceOracleManager is IPriceOracleManager, AdminControl {

    event NewVoucherOracle(
        address voucher,
        address oldOracle,
        address newOracle
    );

    event NewDefaultOracle(
        address oldOracle, 
        address newOracle
    );

    event SetDefaultPricePeriod(
        uint64 oldPricePeriod,
        uint64 newPricePeriod
    );

    event SetPricePeriod(
        address voucher, 
        uint64 oldPricePeriod,
        uint64 newPricePeriod
    );

    uint64 public defaultPricePeriod;
    IPriceOracle public defaultOracle;

    //voucher => pricePeriod
    mapping(address => uint64) internal _pricePeriods;

    //voucher => IPriceOracle
    mapping(address => IPriceOracle) internal _oracles;

    function initialize(IPriceOracle oracle_) external {
        AdminControl.__AdminControl_init(_msgSender());
        defaultPricePeriod = 7 * 86400;
        defaultOracle = oracle_;
        emit NewDefaultOracle(address(0), address(oracle_));
    }

    function _setVoucherOracle(address voucher_, IPriceOracle oracle_)
        external
        onlyAdmin
    {
        address old = address(_oracles[voucher_]);
        _oracles[voucher_] = oracle_;
        emit NewVoucherOracle(voucher_, old, address(oracle_));
    }

    function _setDefaultOracle(IPriceOracle newOracle_) external onlyAdmin {
        address old = address(defaultOracle);
        defaultOracle = newOracle_;
        emit NewDefaultOracle(old, address(newOracle_));
    }

    function _setDefaultPricePeriod(uint64 pricePeriod_) external onlyAdmin {
        emit SetDefaultPricePeriod(defaultPricePeriod, pricePeriod_);
        defaultPricePeriod = pricePeriod_;
    }

    function _setPricePeriod(address voucher_, uint64 pricePeriod_)
        external
        onlyAdmin
    {
        emit SetPricePeriod(voucher_, _pricePeriods[voucher_], pricePeriod_);
        _pricePeriods[voucher_] = pricePeriod_;
    }

    function getPricePeriod(address voucher_) external view returns (uint64) {
        return _pricePeriods[voucher_];
    }

    function refreshUnderlyingPriceOfTokenId(address voucher_, uint256 tokenId_)
        external
    {
        uint256 slot = IVNFT(voucher_).slotOf(tokenId_);
        refreshUnderlyingPriceOfSlot(voucher_, slot);
    }

    function refreshUnderlyingPriceOfSlot(address voucher_, uint256 slot_)
        public
    {
        IBondPool.SlotDetail memory slotDetail = IBondVoucher(voucher_).getSlotDetail(slot_);

        address currency = slotDetail.fundCurrency;
        uint64 maturity = slotDetail.maturity;

        address underlying = IBondVoucher(voucher_).underlying();
        (uint64 fromDate, uint64 toDate) = _getPeriod(voucher_, maturity);

        getOracle(voucher_).refreshPrice(underlying, currency , fromDate, toDate);
    }

    function getOracle(address voucher_) public view returns (IPriceOracle) {
        return
            address(_oracles[voucher_]) != address(0)
                ? _oracles[voucher_]
                : defaultOracle;
    }

    function _getPeriod(address voucher_, uint64 maturity_)
        internal
        view
        returns (uint64 fromDate_, uint64 toDate_)
    {
        uint64 pricePeriod = _pricePeriods[voucher_] == 0
            ? defaultPricePeriod
            : _pricePeriods[voucher_];
        toDate_ = maturity_;
        fromDate_ = toDate_ - pricePeriod;
    }

    function getPriceOfMaturity(address voucher_, address fundCurrency_, uint64 maturity_)
        public
        view
        virtual
        override
        returns (int256 price_)
    {
        address underlying = IBondVoucher(voucher_).underlying();
        (uint64 fromDate, uint64 toDate) = _getPeriod(voucher_, maturity_);
        return getOracle(voucher_).getPrice(underlying, fundCurrency_, fromDate, toDate);
    }

    function getPriceOfSlot(address voucher_, uint256 slot_) 
        public 
        view 
        virtual
        override
        returns (int256 price_) 
    {
        IBondPool.SlotDetail memory slotDetail = IBondVoucher(voucher_).getSlotDetail(slot_);
        return getPriceOfMaturity(voucher_, slotDetail.fundCurrency, slotDetail.maturity);
    }

    function getPriceOfTokenId(address voucher_, uint256 tokenId_)
        external
        view
        virtual
        override
        returns (int256 price_)
    {
        uint256 slot = IVNFT(voucher_).slotOf(tokenId_);
        return getPriceOfSlot(voucher_, slot);
    }
}