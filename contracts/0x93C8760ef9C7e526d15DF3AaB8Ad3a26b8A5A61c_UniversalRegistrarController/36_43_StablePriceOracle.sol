// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IPriceOracle.sol";
import "./SafeMath.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

// StablePriceOracle sets a price in USD, based on an oracle.
contract StablePriceOracle is Ownable, IPriceOracle {
    using SafeMath for *;
    using StringUtils for *;

    // Base price units by length. Element 0 is for 1-length names, and so on.
    uint256[] public prices;

    // Oracle address
    AggregatorInterface public immutable usdOracle;

    event OracleChanged(address oracle);

    event PriceChanged(uint256[] prices);

    bytes4 private constant INTERFACE_META_ID =
    bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ORACLE_ID =
    bytes4(
        keccak256("price(string,uint256,uint256)") ^
        keccak256("premium(string,uint256,uint256)")
    );

    constructor(AggregatorInterface _usdOracle, uint256[] memory _prices) {
        usdOracle = _usdOracle;
        setPrices(_prices);
    }

    function price(string calldata name) external view override returns (uint256) {
        uint256 len = name.strlen();
        if (len > prices.length) {
            len = prices.length;
        }
        require(len > 0);

        uint256 basePrice = prices[len - 1];
        basePrice = basePrice.add(_premium(name));

        return attoUSDToWei(basePrice);
    }

    /**
     * @dev Sets prices.
     * @param _prices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setPrices(uint256[] memory _prices) public onlyOwner {
        prices = _prices;
        emit PriceChanged(_prices);
    }

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(
        string calldata name
    ) external view returns (uint256) {
        uint256 weiPrice = attoUSDToWei(_premium(name));
        return weiPrice;
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(
        string memory name
    ) internal view virtual returns (uint256) {
        return 0;
    }

    function attoUSDToWei(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer()); //2
        return amount.mul(1e8).div(ethPrice);
    }

    function weiToAttoUSD(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return amount.mul(ethPrice).div(1e8);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool)
    {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}