pragma solidity ^0.8.9;

import "../../lib/Timers.sol";

abstract contract BondStatusLending {
    using Timers for Timestamp;
    event TimePhaseUpdated(uint64 active, uint64 maturity);
    event BondMatured(uint256 maturity);
    enum Status {
        Pending,
        OnSale,
        Active,
        Matured,
        Commit,
        Distribution,
        Canceled,
        Liquidated
    }

    enum UnderlyingAssetStatus {
        Pending,
        OnHold,
        Liquidated,
        ReadyToClaim,
        Refunded,
        Canceled
    }

    struct StatusData {
        // packed slot
        // timestamp
        Timestamp startSale;
        Timestamp active;
        Timestamp maturity;
        Timestamp commit;
        Timestamp distribution;
        // end timestamp
        uint8 underlyingAssetStatus; // 0: pending, 1: on hold, 2: liquidated, 3: ready to claim, 4: refunded, 5: Canceled
    }

    StatusData private statusData;

    Timestamp private duration;

    modifier onlyOnSaleOrActive() {
        require(_isOnSale() || _isActive(), "only on sale or active");
        _;
    }

    modifier onlyPending() {
        require(_isPending(), "only pending");
        _;
    }

    modifier onlyCanceled() {
        require(_isCanceled(), "only canceled");
        _;
    }

    modifier onlyOnSale() {
        require(_isOnSale(), "only on sale");
        _;
    }

    modifier onlyActive() {
        require(_isActive(), "only active");
        _;
    }

    modifier onlyMatured() {
        require(_isMatured(), "only matured");
        _;
    }


    modifier onlyReadyToClaimFaceValue() {
        require(
            _isReadyToClaim() || _isRefunded(),
            "only ready to claim face value"
        );
        _;
    }

    modifier onlyLiquidated() {
        require(_isLiquidated(), "only liquidated");
        _;
    }

    function getStatus() public view virtual returns (Status) {
        //save gas
        StatusData memory _statusData = statusData;
        if (_statusData.underlyingAssetStatus == 0) {
            return Status.Pending;
        } else if (_statusData.underlyingAssetStatus == 2) {
            return Status.Liquidated;
        } else if (_statusData.underlyingAssetStatus == 5) {
            return Status.Canceled;
        } else {
            if (_statusData.maturity.passed(_now())) {
                return Status.Matured;
            }
            if (_statusData.active.passed(_now())) {
                return Status.Active;
            }
            if (_statusData.startSale.passed(_now())) {
                return Status.OnSale;
            }
            return Status.Pending;
        }
    }

    function getUnderlyingAssetStatus()
        public
        view
        virtual
        returns (UnderlyingAssetStatus)
    {
        StatusData memory _statusData = statusData;
        if (_statusData.underlyingAssetStatus == 0) {
            return UnderlyingAssetStatus.Pending;
        } else if (_statusData.underlyingAssetStatus == 1) {
            return UnderlyingAssetStatus.OnHold;
        } else if (_statusData.underlyingAssetStatus == 2) {
            return UnderlyingAssetStatus.Liquidated;
        } else if (_statusData.underlyingAssetStatus == 3) {
            return UnderlyingAssetStatus.ReadyToClaim;
        } else if (_statusData.underlyingAssetStatus == 4) {
            return UnderlyingAssetStatus.Refunded;
        } else return UnderlyingAssetStatus.Canceled;
    }

    function getStatusData() public view virtual returns (StatusData memory) {
        return statusData;
    }

    function active(
        uint64 _startSale,
        uint64 _active,
        uint64 _maturity
    ) public virtual {
        require(statusData.underlyingAssetStatus == 0, "!pending");
        require(_startSale < _active && _active < _maturity, "!time");
        _transferUnderlyingAsset();
        statusData = StatusData({
            startSale: Timestamp.wrap(_startSale),
            active: Timestamp.wrap(_active),
            maturity: Timestamp.wrap(_maturity),
            commit: Timestamp.wrap(0),
            distribution: Timestamp.wrap(0),
            underlyingAssetStatus: 1
        });
    }

    function _setUnderlyingAssetStatusPending() internal virtual {
        statusData.underlyingAssetStatus = 0;
    }

    function _setUnderlyingAssetStatusOnHold() internal virtual {
        statusData.underlyingAssetStatus = 1;
    }

    function _setUnderlyingAssetStatusLiquidated() internal virtual {
        statusData.underlyingAssetStatus = 2;
    }

    function _setUnderlyingAssetStatusReadyToClaim() internal virtual {
        require(
            getUnderlyingAssetStatus() == UnderlyingAssetStatus.OnHold,
            "!OnHold"
        );
        statusData.underlyingAssetStatus = 3;
    }

    function _setUnderlyingAssetStatusRefunded() internal virtual {
        statusData.underlyingAssetStatus = 4;
    }

    function _setUnderlyingAssetCanceled() internal virtual {
        statusData.underlyingAssetStatus = 5;
    }

    function _isCanceled() internal virtual returns (bool) {
        return getStatus() == Status.Canceled;
    }

    function _isPending() internal view virtual returns (bool) {
        return getStatus() == Status.Pending;
    }

    function _isOnSale() internal view virtual returns (bool) {
        return getStatus() == Status.OnSale;
    }

    function _isActive() internal view virtual returns (bool) {
        return getStatus() == Status.Active;
    }

    function _isMatured() internal view virtual returns (bool) {
        return getStatus() == Status.Matured;
    }

    function _isReadyToClaim() internal view virtual returns (bool) {
        return getUnderlyingAssetStatus() == UnderlyingAssetStatus.ReadyToClaim;
    }

    function _isLiquidated() internal view virtual returns (bool) {
        return getUnderlyingAssetStatus() == UnderlyingAssetStatus.Liquidated;
    }

    function _isRefunded() internal view virtual returns (bool) {
        return getUnderlyingAssetStatus() == UnderlyingAssetStatus.Refunded;
    }

    //for injeting test
    function _now() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _bondTransferable() internal virtual returns (bool) {
        Status _status = getStatus();
        return
            _status == Status.Active ||
            _status == Status.Matured ||
            _status == Status.Liquidated;
    }

    function _transferUnderlyingAsset() internal virtual {}

    function getDuration() public view returns (uint64) {
        return duration.unwrap();
    }

    function _updateTimePhase() internal virtual {
        uint64 _active = uint64(_now());
        uint64 _maturity = uint64(_now() + duration.unwrap());
        statusData.active = Timestamp.wrap(_active);
        statusData.maturity = Timestamp.wrap(_maturity);
        emit TimePhaseUpdated(_active, _maturity);
    }

    function matured() internal virtual {
        statusData.maturity = Timestamp.wrap(uint64(_now()));
        emit BondMatured(uint64(_now()));
    }

    function setDuration(uint64 duration_) internal {
        duration = Timestamp.wrap(duration_ * 1 days);
    }
}