pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Constants.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract ExchangeRate is Constants, AccessControl {
    address public usdEthPairAddress;
    uint256 constant cUsdDecimals = 2;
    IUniswapV2Pair usdEthPair;

    event UpdateUsdToEthPair(address _usdToEthPairAddress);

    constructor(address _usdEthPairAddress) {
        usdEthPairAddress = _usdEthPairAddress;
        usdEthPair = IUniswapV2Pair(_usdEthPairAddress);
    }

    /// @notice Set the uniswap liquidity pool used to determine exchange rate
    /// @param _usdEthPairAddress address of the contract
    function updateUsdToEthPair(address _usdEthPairAddress) public {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        usdEthPairAddress = _usdEthPairAddress;
        usdEthPair = IUniswapV2Pair(usdEthPairAddress);
        emit UpdateUsdToEthPair(_usdEthPairAddress);
    }

    /// @notice Calculate Wei price dynamically based on reserves on Uniswap for ETH / DAI pair
    /// @param _amountInUsd the amount to convert, in USDx100, e.g. 186355 for $1863.55 USD
    /// @return amount of wei needed to buy _amountInUsd
    function getWeiPrice(uint256 _amountInUsd) public view returns (uint256) {
        (uint112 usdReserve, uint112 ethReserve, uint32 blockTimestampLast) =
            usdEthPair.getReserves();
        return _calcWeiFromUsd(usdReserve, ethReserve, _amountInUsd);
    }

    function _calcWeiFromUsd(
        uint112 _usdReserve,
        uint112 _ethReserve,
        uint256 _amountInUsd
    ) public pure returns (uint256) {
        return
            (_amountInUsd * _ethReserve * (10**18)) /
            (_usdReserve * (10**cUsdDecimals));
    }
}