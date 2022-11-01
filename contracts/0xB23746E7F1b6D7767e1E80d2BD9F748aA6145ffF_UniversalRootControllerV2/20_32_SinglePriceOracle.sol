// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./StablePriceOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// SinglePriceOracle sets a price in USD, based on an oracle.
contract SinglePriceOracle is Ownable {
    using SafeMath for *;

    //  price in attodollars (1e-18 USD).
    uint256 public usdPrice;

    // Oracle address
    AggregatorInterface public immutable usdOracle;

    event OracleChanged(address oracle);
    event PriceChanged(uint256 price);

    bytes4 private constant INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ORACLE_ID = bytes4(keccak256("price()"));

    constructor(AggregatorInterface _usdOracle, uint256 _usdPrice) {
        usdOracle = _usdOracle;
        setPrice(_usdPrice);
    }

    function price() external view returns (uint256) {
        return attoUSDToWei(usdPrice);
    }

    /**
     * @dev Sets price.
     * @param _usdPrice The price in attodollars.
     */
    function setPrice(uint256 _usdPrice) public onlyOwner {
        usdPrice = _usdPrice;
        emit PriceChanged(usdPrice);
    }

    function attoUSDToWei(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return amount.mul(1e8).div(ethPrice);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool)
    {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}