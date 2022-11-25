// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StablePriceOracle.sol";
import "./UniversalRegistrar.sol";

// SLDPriceOracle sets a price in USD, based on an oracle for each node.
// The registry can set and change default and specific tld prices
contract SLDPriceOracle is Ownable {
    using SafeMath for *;
    using StringUtils for *;

    // Base price units by length. Element 0 is for 1-length names, and so on.
    uint256[] public defaultPrices;
    mapping(bytes32 => uint256[]) public prices;

    // Oracle address
    AggregatorInterface public usdOracle;
    // Registrar address
    UniversalRegistrar public registrar;
    
    event OracleChanged(address oracle);

    event PriceChanged(bytes32 node, uint256[] prices);
    event DefaultPriceChanged(uint256[] prices);

    bytes4 private constant INTERFACE_META_ID =
    bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 private constant ORACLE_ID =
    bytes4(keccak256("price(bytes32,string)"));

    constructor(UniversalRegistrar _registrar, AggregatorInterface _usdOracle, uint256[] memory _defaultPrices) {
        registrar = _registrar;
        usdOracle = _usdOracle;
        defaultPrices = _defaultPrices;
    }

    function price(bytes32 node, string calldata name) external view returns (uint256) {
        uint256 len = name.strlen();
        uint256[] memory _prices = prices[node].length > 0 ? prices[node] : defaultPrices;

        if (len > _prices.length) {
            len = _prices.length;
        }

        require(len > 0, "Name has no Length");

        uint256 basePrice = _prices[len - 1];
        return attoUSDToWei(basePrice);
    }

    function attoUSDToWei(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer()); //2
        return amount.mul(1e8).div(ethPrice);
    }

    function weiToAttoUSD(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return amount.mul(ethPrice).div(1e8);
    }

    /**
     * @dev Set USD Oracle
     * @param _usdOracle USD Oracle
     */
    function setUSDOracle(AggregatorInterface _usdOracle) public onlyOwner {
        usdOracle = _usdOracle;
        emit OracleChanged(address(_usdOracle));
    }

    /**
     * @dev Sets prices for the specified node (can only be called by the node owner)
     * @param _prices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setPrices(bytes32 node, uint256[] memory _prices) public onlyOwner {
        prices[node] = _prices;
        emit PriceChanged(node, _prices);
    }

    /**
     * @dev Sets default prices to be used by nodes that don't have pricing set.
     * @param _defaultPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setDefaultPrices(uint256[] memory _defaultPrices) public onlyOwner {
        defaultPrices = _defaultPrices;
        emit DefaultPriceChanged(_defaultPrices);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool)
    {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}