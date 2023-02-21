// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PriceOracle.sol";
import "../midregistrar/StringUtils.sol";

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
}


// StablePriceOracle sets a price in USD, based on an oracle.
contract StablePriceOracle is Ownable, PriceOracle {
    using StringUtils for *;

    // Rent in base price units by length. Element 0 is for 1-length names, and so on.
    uint[] public rentPrices;

    // Oracle address
    AggregatorInterface public usdOracle;

    event OracleChanged(address oracle);

    event RentPriceChanged(uint[] prices);

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ORACLE_ID = bytes4(keccak256("price(string,uint256,uint256)") ^ keccak256("premium(string,uint256,uint256)"));

    constructor(AggregatorInterface _usdOracle, uint[] memory _rentPrices) {
        usdOracle = _usdOracle;
        setPrices(_rentPrices);
    }

    function price(string calldata name, uint expires, uint duration) external view override returns(uint) {
        uint len = name.strlen();

        require(len >= 2, "name too short");
        require(len <= 63, "name too long");

        if(len > rentPrices.length) {
            len = rentPrices.length;
        }
        uint basePrice = rentPrices[len - 1] * duration;
        basePrice = basePrice + _premium(name, expires, duration);

        return attoUSDToWei(basePrice);
    }

    /**
     * @dev Sets rent prices.
     * @param _rentPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setPrices(uint[] memory _rentPrices) public onlyOwner {
        rentPrices = _rentPrices;
        emit RentPriceChanged(_rentPrices);
    }

    /**
     * @dev Sets the price oracle address
     * @param _usdOracle The address of the price oracle to use.
     */
    function setOracle(AggregatorInterface _usdOracle) public onlyOwner {
        usdOracle = _usdOracle;
        emit OracleChanged(address(_usdOracle));
    }

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(string calldata name, uint expires, uint duration) external view returns(uint) {
        return attoUSDToWei(_premium(name, expires, duration));
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory name, uint expires, uint duration) virtual internal view returns(uint) {
        return 0;
    }

    function attoUSDToWei(uint amount) internal view returns(uint) {
        uint ethPrice_ = ethPrice();
        return amount * 1e8 / ethPrice_;
    }

    function weiToAttoUSD(uint amount) internal view returns(uint) {
        uint ethPrice_ = ethPrice();
        return amount * ethPrice_ / 1e8;
    }

    function ethPrice() public view returns(uint) {
        return uint(usdOracle.latestAnswer());
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}