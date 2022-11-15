// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./BondDepositoryStorage.sol";
import "./common/ProxyAccessCommon.sol";

import "./libraries/SafeERC20.sol";

import "./interfaces/IBondDepository.sol";
import "./interfaces/IBondDepositoryEvent.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
// import "hardhat/console.sol";

interface IIIERC20 {
    function decimals() external view returns (uint256);
}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IITOSValueCalculator {
    function convertAssetBalanceToWethOrTos(address _asset, uint256 _amount)
        external view
        returns (bool existedWethPool, bool existedTosPool,  uint256 priceWethOrTosPerAsset, uint256 convertedAmount);
}

interface IITreasury {

    function getETHPricePerTOS() external view returns (uint256 price);
    function getMintRate() external view returns (uint256);
    function mintRateDenominator() external view returns (uint256);

    function requestMint(uint256 _mintAmount, uint256 _payout, bool _distribute) external ;
    function addBondAsset(address _address) external;
}

contract BondDepository is
    BondDepositoryStorage,
    ProxyAccessCommon,
    IBondDepository,
    IBondDepositoryEvent
{
    using SafeERC20 for IERC20;

    modifier nonEndMarket(uint256 id_) {
        require(markets[id_].endSaleTime > block.timestamp, "BondDepository: closed market");
        require(markets[id_].capacity > 0 , "BondDepository: zero capacity" );
        _;
    }

    modifier isEthMarket(uint256 id_) {
        require(markets[id_].quoteToken == address(0) && markets[id_].endSaleTime > 0,
            "BondDepository: not ETH market"
        );
        _;
    }

    modifier nonEthMarket(uint256 id_) {
        require(
            markets[id_].quoteToken != address(0) && markets[id_].endSaleTime > 0,
            "BondDepository: ETH market"
        );
        _;
    }

    modifier nonZeroPayout(uint256 id_) {
        require(
            markets[id_].maxPayout > 0,
            "BondDepository: non-exist market"
        );
        _;
    }
    constructor() {

    }

    ///////////////////////////////////////
    /// onlyPolicyOwner
    //////////////////////////////////////

    function setCalculator(
        address _calculator
    )
        external nonZeroAddress(_calculator) onlyProxyOwner
    {
        require(calculator != _calculator, "same address");
        calculator = _calculator;

        emit SetCalculator(_calculator);
    }

    /// @inheritdoc IBondDepository
    function create(
        address _token,
        uint256[4] calldata _market
    )
        external
        override
        onlyPolicyOwner
        nonZero(_market[0])
        nonZero(_market[2])
        nonZero(_market[3])
        returns (uint256 id_)
    {
        require(_market[0] > 100 ether, "need the totalSaleAmount > 100");
        id_ = staking.generateMarketId();
        require(markets[id_].endSaleTime == 0, "already registered market");
        require(_market[1] > block.timestamp, "endSaleTime has passed");

        markets[id_] = LibBondDepository.Market({
                            quoteToken: _token,
                            capacity: _market[0],
                            endSaleTime: _market[1],
                            maxPayout: _market[3],
                            tosPrice: _market[2]
                        });

        marketList.push(id_);
        if (_token != address(0)) IITreasury(treasury).addBondAsset(_token);

        emit CreatedMarket(id_, _token, _market);
    }


    /// @inheritdoc IBondDepository
    function changeCapacity(
        uint256 _marketId,
        bool _increaseFlag,
        uint256 _increaseAmount
    )   external override onlyPolicyOwner
        nonZero(_increaseAmount)
        nonZeroPayout(_marketId)
    {
        LibBondDepository.Market storage _info = markets[_marketId];

        if (_increaseFlag) _info.capacity += _increaseAmount;
        else {
            if (_increaseAmount < _info.capacity) _info.capacity -= _increaseAmount;
            else {
                _info.capacity = 0;
                emit ClosedMarket(_marketId);
            }
        }

        emit ChangedCapacity(_marketId, _increaseFlag, _increaseAmount);
    }

    /// @inheritdoc IBondDepository
    function changeCloseTime(
        uint256 _marketId,
        uint256 closeTime
    )   external override onlyPolicyOwner
        //nonEndMarket(_marketId)
        //nonZero(closeTime)
        nonZeroPayout(_marketId)
    {
        require(closeTime > block.timestamp, "past closeTime");

        LibBondDepository.Market storage _info = markets[_marketId];
        _info.endSaleTime = closeTime;

        emit ChangedCloseTime(_marketId, closeTime);
    }

    /// @inheritdoc IBondDepository
    function changeMaxPayout(
        uint256 _marketId,
        uint256 _amount
    )   external override onlyPolicyOwner
        nonEndMarket(_marketId)
        nonZero(_amount)
    {
        LibBondDepository.Market storage _info = markets[_marketId];
        _info.maxPayout = _amount;

        emit ChangedMaxPayout(_marketId, _amount);
    }

    /// @inheritdoc IBondDepository
    function changePrice(
        uint256 _marketId,
        uint256 _tosPrice
    )   external override onlyPolicyOwner
        nonEndMarket(_marketId)
        nonZero(_tosPrice)
    {
        LibBondDepository.Market storage _info = markets[_marketId];
        _info.tosPrice = _tosPrice;

        emit ChangedPrice(_marketId, _tosPrice);
    }

    /// @inheritdoc IBondDepository
    function close(uint256 _id) public override onlyPolicyOwner {
        require(markets[_id].endSaleTime > 0, "empty market");
        require(markets[_id].endSaleTime > block.timestamp || markets[_id].capacity == 0, "already closed");
        LibBondDepository.Market storage _info = markets[_id];
        _info.endSaleTime = block.timestamp;
        _info.capacity = 0;
        emit ClosedMarket(_id);
    }

    ///////////////////////////////////////
    /// Anyone can use.
    //////////////////////////////////////

    /// @inheritdoc IBondDepository
    function ETHDeposit(
        uint256 _id,
        uint256 _amount
    )
        external payable override
        nonEndMarket(_id)
        isEthMarket(_id)
        nonZero(_amount)
        returns (uint256 payout_)
    {
        require(msg.value == _amount, "Depository: ETH amounts do not match");

        uint256 _tosPrice = 0;

        (payout_, _tosPrice) = _deposit(msg.sender, _amount, _id);

        uint256 stakeId = staking.stakeByBond(msg.sender, payout_, _id, _tosPrice);

        payable(treasury).transfer(msg.value);

        emit ETHDeposited(msg.sender, _id, stakeId, _amount, payout_);
    }


    /// @inheritdoc IBondDepository
    function ETHDepositWithSTOS(
        uint256 _id,
        uint256 _amount,
        uint256 _lockWeeks
    )
        external payable override
        nonEndMarket(_id)
        isEthMarket(_id)
        nonZero(_amount)
        nonZero(_lockWeeks)
        returns (uint256 payout_)
    {
        require(msg.value == _amount, "Depository: ETH amounts do not match");
        require(_lockWeeks > 1, "_lockWeeks must be greater than 1 week.");
        uint256 _tosPrice = 0;
        (payout_, _tosPrice) = _deposit(msg.sender, _amount, _id);

        uint256 stakeId = staking.stakeGetStosByBond(msg.sender, payout_, _id, _lockWeeks, _tosPrice);

        payable(treasury).transfer(msg.value);

        emit ETHDepositedWithSTOS(msg.sender, _id, stakeId, _amount, _lockWeeks, payout_);
    }


    function _deposit(
        address user,
        uint256 _amount,
        uint256 _marketId
    ) internal nonReentrant returns (uint256 _payout, uint256 _tosPrice) {
        LibBondDepository.Market storage market = markets[_marketId];
        _tosPrice = market.tosPrice;
        require(_amount <= purchasableAssetAmountAtOneTime(_tosPrice, market.maxPayout), "Depository : over maxPay");

        _payout = calculateTosAmountForAsset(_tosPrice, _amount);
        require(_payout > 0, "zero staking amount");

        uint256 mrAmount = _amount * IITreasury(treasury).getMintRate() / 1e18;
        require(mrAmount >= _payout, "mintableAmount is less than staking amount.");
        require(_payout <= market.capacity, "Depository: sold out");

        market.capacity -= _payout;

        //check closing
        if (market.capacity <= 100 ether) {
           market.capacity = 0;
           emit ClosedMarket(_marketId);
        }

        IITreasury(treasury).requestMint(mrAmount, _payout, true);

        emit Deposited(user, _marketId, _amount, _payout, true, mrAmount);
    }

    ///////////////////////////////////////
    /// VIEW
    //////////////////////////////////////

    /// @inheritdoc IBondDepository
    function calculateTosAmountForAsset(
        uint256 _tosPrice,
        uint256 _amount
    )
        public override
        pure
        returns (uint256 payout)
    {
        return (_amount * _tosPrice / 1e18);
    }

    /// @inheritdoc IBondDepository
    function purchasableAssetAmountAtOneTime(
        uint256 _tosPrice,
        uint256 _maxPayout
    )
        public override pure returns (uint256 maxPayout_)
    {
        return ( _maxPayout *  1e18 / _tosPrice );
    }

    /// @inheritdoc IBondDepository
    function getBonds() external override view
        returns (
            uint256[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 len = marketList.length;
        uint256[] memory _marketIds = new uint256[](len);
        address[] memory _quoteTokens = new address[](len);
        uint256[] memory _capacities = new uint256[](len);
        uint256[] memory _endSaleTimes = new uint256[](len);
        uint256[] memory _pricesTos = new uint256[](len);

        for (uint256 i = 0; i < len; i++){
            _marketIds[i] = marketList[i];
            _quoteTokens[i] = markets[_marketIds[i]].quoteToken;
            _capacities[i] = markets[_marketIds[i]].capacity;
            _endSaleTimes[i] = markets[_marketIds[i]].endSaleTime;
            _pricesTos[i] = markets[_marketIds[i]].tosPrice;
        }
        return (_marketIds, _quoteTokens, _capacities, _endSaleTimes, _pricesTos);
    }

    /// @inheritdoc IBondDepository
    function getMarketList() external override view returns (uint256[] memory) {
        return marketList;
    }

    /// @inheritdoc IBondDepository
    function totalMarketCount() external override view returns (uint256) {
        return marketList.length;
    }

    /// @inheritdoc IBondDepository
    function viewMarket(uint256 _marketId) external override view
        returns (
            address quoteToken,
            uint256 capacity,
            uint256 endSaleTime,
            uint256 maxPayout,
            uint256 tosPrice
            )
    {
        return (
            markets[_marketId].quoteToken,
            markets[_marketId].capacity,
            markets[_marketId].endSaleTime,
            markets[_marketId].maxPayout,
            markets[_marketId].tosPrice
        );
    }

    /// @inheritdoc IBondDepository
    function isOpened(uint256 _marketId) external override view returns (bool closedBool)
    {
        return block.timestamp < markets[_marketId].endSaleTime && markets[_marketId].capacity > 0;
    }

}