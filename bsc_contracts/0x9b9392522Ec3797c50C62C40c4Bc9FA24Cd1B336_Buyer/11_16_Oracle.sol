// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../security/Administered.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Oracle is Administered {
    // @dev SafeMath library
    using SafeMath for uint256;

    address public _addressOracle = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    uint256 public _addressDecimalOracle = 10;
    bool public _isActive = true;

    /**
     * @dev Returns the latest price
     */
    function getLatestPrice(
        address _oracle,
        uint256 _decimal
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracle);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10 ** _decimal;
    }

    /**
     * @dev get amount in bnb
     */
    function getAmountInBnb(
        uint256 _amount,
        uint256 _bnbInUsd
    ) public pure returns (uint256) {
        uint256 unitaryPrice = _amount.mul(1 ether).div(_bnbInUsd);
        return unitaryPrice;
    }

    /**
     * @dev setting oracle
     */
    function setting(
        uint _type,
        bool _bool,
        address _addrs,
        uint256 _uint
    ) public onlyAdmin {
        if (_type == 1) {
            _isActive = _bool;
        } else if (_type == 2) {
            _addressOracle = _addrs;
        } else if (_type == 2) {
            _addressDecimalOracle = _uint;
        }
    }
}