pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "./SafeMath.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
}


// StablePriceOracle sets a price in USD, based on an oracle.
contract StablePriceOracle is Ownable, PriceOracle {
    using SafeMath for *;
    using StringUtils for *;

    // Price by length. Element 0 is for 1-length names, and so on.
    uint[] public prices;

    // Oracle address
    AggregatorInterface public usdOracle;

    event OracleChanged(address oracle);
    event PriceChanged(uint[] prices);

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ORACLE_ID = bytes4(keccak256("price(string)") ^ keccak256("premium(string)"));

    constructor(AggregatorInterface _usdOracle, uint[] memory _prices) public {
        usdOracle = _usdOracle;
        setPrices(_prices);
    }

    function price(string calldata name) external view override returns(uint) {
        uint len = name.strlen();
        if(len > prices.length) {
            len = prices.length;
        }
        require(len > 0);
        
        uint basePrice = prices[len - 1];
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
    function setPrices(uint[] memory _prices) public onlyOwner {
        prices = _prices;
        emit PriceChanged(_prices);
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
    function premium(string calldata name) external view returns(uint) {
        return attoUSDToWei(_premium(name));
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory name) virtual internal view returns(uint) {
        return 0;
    }

    function attoUSDToWei(uint amount) internal view returns(uint) {
        uint ethPrice = uint(usdOracle.latestAnswer());
        return amount.mul(1e8).div(ethPrice);
    }

    function weiToAttoUSD(uint amount) internal view returns(uint) {
        uint ethPrice = uint(usdOracle.latestAnswer());
        return amount.mul(ethPrice).div(1e8);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}