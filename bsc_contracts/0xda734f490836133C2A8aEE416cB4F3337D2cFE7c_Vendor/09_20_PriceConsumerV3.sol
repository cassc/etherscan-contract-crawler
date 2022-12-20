// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
/// @dev stardanrt contract
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../security/Administered.sol";

contract PriceConsumerV3 is Administered {
    /// @dev SafeMath library
    using SafeMath for uint256;

    struct StructOracle {
        address _addr;
        uint256 _decimal;
    }

    StructOracle[] public OracleList;

    /// @dev price tokens
    uint256 public priceTokens = 0.1 ether;

    constructor() {
        /// @dev production
        OracleList.push(StructOracle(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE, 10)); /// BNB / USD
        OracleList.push(StructOracle(0xcBb98864Ef56E9042e7d2efef76141f15731B82f, 10)); /// BUSD / USD
        OracleList.push(StructOracle(0xB97Ad0E74fa7d920791E90258A6E2085088b4320, 10)); /// USDT / USD
    }

    /// set change price tokens
    function setPriceTokens(uint256 newValue) external onlyAdmin {
        priceTokens = newValue;
    }

    /// @dev get price token
    function getPriceToken() public view returns (uint256) {
        return priceTokens;
    }

    /// @dev get oracle
    function getOracle(uint256 _index) public view returns (address, uint256) {
        StructOracle storage oracle = OracleList[_index];
        return (oracle._addr, oracle._decimal);
    }

    /// @dev Returns the latest price
    function getLatestPrice(address _oracle, uint256 _decimal)
        public
        view
        returns (uint256)
    {
        require(
            _oracle != address(0),
            "Get Latest Price: address must be the same as the contract address"
        );

        AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracle);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10**_decimal;
    }

    /// @notice Parse on 18 decimals
    /// @dev Parse amount to 18 decimals
    /// @param _amount                          Amount to convert
    /// @param _decimal                         Decimal to convert
    /// @return value                           Amount parsed to 18 decimals
    function transformAmountTo18Decimal(uint256 _amount, uint256 _decimal)
        internal
        pure
        returns (uint256)
    {
        if (_decimal == 18) {
            return _amount;
        } else if (_decimal == 8) {
            return _amount.mul(10**10);
        } else if (_decimal == 6) {
            return _amount.mul(10**12);
        } else if (_decimal == 3) {
            return _amount.mul(10**15);
        } else if (_decimal == 0) {
            return _amount.mul(10**18);
        }
        return 0;
    }
}