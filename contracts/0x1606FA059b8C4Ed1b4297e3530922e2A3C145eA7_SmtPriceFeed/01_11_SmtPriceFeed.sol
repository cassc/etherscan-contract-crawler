//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";
import "./interfaces/IBPool.sol";
import "./interfaces/IBRegistry.sol";
import "./interfaces/IEurPriceFeedForSmtPriceFeed.sol";
import "./interfaces/IXTokenWrapper.sol";

interface IDecimals {
    function decimals() external view returns (uint8);
}

/**
 * @title SmtPriceFeed
 * @author Protofire
 * @dev Contract module to retrieve SMT price per asset.
 */
contract SmtPriceFeed is Ownable {
    using SafeMath for uint256;

    // it represents usdc
    uint256 public immutable decimals;
    uint256 public constant ONE_BASE18 = 10**18;
    address public immutable USDC_ADDRESS;
    uint256 public immutable ONE_ON_USDC;

    /// @dev Address smtTokenAddress
    address public smtTokenAddress;
    /// @dev Address of BRegistry
    IBRegistry public registry;
    /// @dev Address of EurPriceFeed module
    IEurPriceFeedForSmtPriceFeed public eurPriceFeed;
    /// @dev Address of XTokenWrapper module
    IXTokenWrapper public xTokenWrapper;
    /// @dev price of SMT measured in WETH stored, used to decouple price querying and calculating
    uint256 public currentPrice;

    /**
     * @dev Emitted when `registry` address is set.
     */
    event RegistrySet(address registry);

    /**
     * @dev Emitted when `eurPriceFeed` address is set.
     */
    event EurPriceFeedSet(address eurPriceFeed);

    /**
     * @dev Emitted when `smtTokenAddress` address is set.
     */
    event SmtSet(address smtTokenAddress);

    /**
     * @dev Emitted when `xTokenWrapper` address is set.
     */
    event XTokenWrapperSet(address xTokenWrapper);

    /**
     * @dev Emitted when someone executes computePrice.
     */
    event PriceComputed(address caller, uint256 price);

    modifier onlyValidAsset(address _asset) {
        require(xTokenWrapper.xTokenToToken(_asset) != address(0), "invalid asset");
        _;
    }

    /**
     * @dev Sets the values for {registry}, {eurPriceFeed} {smtTokenAddress} and {xTokenWrapper} and {USDC_ADDRESS}.
     *
     * Sets ownership to the account that deploys the contract.
     *
     */
    constructor(
        address _registry,
        address _eurPriceFeed,
        address _smt,
        address _xTokenWrapper,
        address _usdcAddress
    ) {
        _setRegistry(_registry);
        _setEurPriceFeed(_eurPriceFeed);
        _setSmt(_smt);
        _setXTokenWrapper(_xTokenWrapper);

        require(_usdcAddress != address(0), "err: _usdcAddress is ZERO address");
        USDC_ADDRESS = _usdcAddress;
        uint8 usdcDecimals = IDecimals(_usdcAddress).decimals();
        decimals = usdcDecimals;
        ONE_ON_USDC = 10**usdcDecimals;
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function setRegistry(address _registry) external onlyOwner {
        _setRegistry(_registry);
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EurPriceFeed.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the EurPriceFeed.
     */
    function setEurPriceFeed(address _eurPriceFeed) external onlyOwner {
        _setEurPriceFeed(_eurPriceFeed);
    }

    /**
     * @dev Sets `_smt` as the new Smt.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_smt` should not be the zero address.
     *
     * @param _smt The address of the Smt.
     */
    function setSmt(address _smt) external onlyOwner {
        _setSmt(_smt);
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function setXTokenWrapper(address _xTokenWrapper) external onlyOwner {
        _setXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function _setRegistry(address _registry) internal {
        require(_registry != address(0), "registry is the zero address");
        emit RegistrySet(_registry);
        registry = IBRegistry(_registry);
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EurPriceFeed.
     *
     * Requirements:
     *
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the EurPriceFeed.
     */
    function _setEurPriceFeed(address _eurPriceFeed) internal {
        require(_eurPriceFeed != address(0), "eurPriceFeed is the zero address");
        emit EurPriceFeedSet(_eurPriceFeed);
        eurPriceFeed = IEurPriceFeedForSmtPriceFeed(_eurPriceFeed);
    }

    /**
     * @dev Sets `_smt` as the new Smt.
     *
     * Requirements:
     *
     * - `_smt` should not be the zero address.
     *
     * @param _smtTokenAddress The address of the Smt.
     */
    function _setSmt(address _smtTokenAddress) internal {
        require(_smtTokenAddress != address(0), "smtTokenAddress is the zero address");
        emit SmtSet(_smtTokenAddress);
        smtTokenAddress = _smtTokenAddress;
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function _setXTokenWrapper(address _xTokenWrapper) internal {
        require(_xTokenWrapper != address(0), "xTokenWrapper is the zero address");
        emit XTokenWrapperSet(_xTokenWrapper);
        xTokenWrapper = IXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Gets the price of `_asset` in SMT.
     *
     * @param _asset address of asset to get the price.
     * response should be on base 18 as it represent xSMT which is base 18
     */
    function getPrice(address _asset) external view onlyValidAsset(_asset) returns (uint256) {
        uint8 assetDecimals = IDecimals(_asset).decimals();
        return calculateAmount(_asset, 10**assetDecimals);
    }

    /**
     * @dev Gets how many SMT represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the amount.
     * @param _assetAmountIn amount of `_asset` should be on asset digits
     * response should be on base 18 as it represent xSMT which is base 18
     */
    function calculateAmount(address _asset, uint256 _assetAmountIn)
        public
        view
        onlyValidAsset(_asset)
        returns (uint256)
    {
        // get the xSmt to search the pools
        address xSMT = xTokenWrapper.tokenToXToken(smtTokenAddress);

        // if _asset is xSMT, don't modify the token amount
        if (_asset == xSMT) {
            return _assetAmountIn;
        }

        // get amount from the pools if the asset/xSMT pair exists
        // how many xSMT are needed to buy the entered qty of asset
        uint256 amount = getAvgAmountFromPools(_asset, xSMT, _assetAmountIn);

        // no pool with xSMT/asset pair
        // calculate base on xSMT/xUSDC pool and Asset/USD external price feed
        if (amount == 0) {
            // to get pools including the xUSDC / xSMT
            address xUSDC = xTokenWrapper.tokenToXToken(USDC_ADDRESS);

            // how many xSMT are needed to buy 1 xUSDC
            // response in base 18
            uint256 xUsdcForSmtAmount = getAvgAmountFromPools(xUSDC, xSMT, ONE_ON_USDC);
            require(xUsdcForSmtAmount > 0, "no xUSDC/xSMT pool to get _asset price");

            // get EUR price for asset for the entered amount (18 digits)
            uint256 eurAmountForAsset = eurPriceFeed.calculateAmount(_asset, _assetAmountIn);
            if (eurAmountForAsset == 0) {
                return 0;
            }

            uint256 eurPriceFeedDecimals = eurPriceFeed.RETURN_DIGITS_BASE18();
            // EUR/USD feed. It returs how many USD is 1 EUR.
            address eurUsdFeedAddress = eurPriceFeed.eurUsdFeed();

            // get how many USD is 1 EUR (8 digits)
            // convert the amount to 18 digits
            uint256 eurUsdDecimals = AggregatorV2V3Interface(eurUsdFeedAddress).decimals();
            int256 amountUsdToGetEur = AggregatorV2V3Interface(eurUsdFeedAddress).latestAnswer();
            if (amountUsdToGetEur == 0) {
                return 0;
            }
            uint256 amountUsdToGetEur18 = uint256(amountUsdToGetEur).mul(
                10**(eurPriceFeedDecimals.sub(eurUsdDecimals))
            );

            // convert the eurAmountForAsset in USDC
            uint256 assetAmountInUSD = amountUsdToGetEur18.mul(eurAmountForAsset).div(ONE_BASE18);

            // having the entered amount of the asset in USD
            // having how much xSMT are needed to buy 1 USDC
            // multiply those qtys
            // the result should be how many xSMT are needed for the entered amount
            amount = assetAmountInUSD.mul(xUsdcForSmtAmount).div(ONE_BASE18);
        }
        return amount;
    }

    /**
     * @dev Gets SMT/USDC based on the last executiong of computePrice.
     *
     * To be consume by EurPriceFeed module as the `assetFeed` from xSMT.
     * response should be on base 6 (USDC) as it represent usdc amount to buy xSMT
     */
    function latestAnswer() external view returns (int256) {
        return int256(currentPrice);
    }

    /**
     * @dev Computes xSMT/xUSDC based on the avg price from pools containig the pair.
     *
     * To be consume by EurPriceFeed module as the `assetFeed` from xSMT.
     */
    function computePrice() public {
        // pools will include the wrapepd SMT and xUSDC
        // how much xUSDC are needed to buy xSmt
        currentPrice = getAvgAmountFromPools(
            xTokenWrapper.tokenToXToken(smtTokenAddress),
            xTokenWrapper.tokenToXToken(USDC_ADDRESS),
            ONE_BASE18
        );

        emit PriceComputed(msg.sender, currentPrice);
    }

    function getAvgAmountFromPools(
        address _assetIn,
        address _assetOut,
        uint256 _assetAmountIn
    ) internal view returns (uint256) {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(_assetIn, _assetOut, 10);

        uint256 totalAmount;
        uint256 totalQty = 0;
        uint256 singlePoolOutGivenIn = 0;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            singlePoolOutGivenIn = calcOutGivenIn(poolAddresses[i], _assetIn, _assetOut, _assetAmountIn);

            if (singlePoolOutGivenIn > 0) {
                totalQty = totalQty.add(1);
                totalAmount = totalAmount.add(singlePoolOutGivenIn);
            }
        }
        uint256 amountToReturn = 0;
        if (totalAmount > 0 && totalQty > 0) {
            amountToReturn = totalAmount.div(totalQty);
        }

        return amountToReturn;
    }

    function calcOutGivenIn(
        address poolAddress,
        address _assetIn,
        address _assetOut,
        uint256 _assetAmountIn
    ) internal view returns (uint256) {
        IBPool pool = IBPool(poolAddress);
        uint256 tokenBalanceIn = pool.getBalance(_assetIn);
        uint256 tokenBalanceOut = pool.getBalance(_assetOut);

        if (tokenBalanceIn == 0 || tokenBalanceOut == 0) {
            return 0;
        } else {
            uint256 tokenWeightIn = pool.getDenormalizedWeight(_assetIn);
            uint256 tokenWeightOut = pool.getDenormalizedWeight(_assetOut);
            uint256 amount = pool.calcOutGivenIn(
                tokenBalanceIn,
                tokenWeightIn,
                tokenBalanceOut,
                tokenWeightOut,
                _assetAmountIn,
                0
            );
            return amount;
        }
    }
}