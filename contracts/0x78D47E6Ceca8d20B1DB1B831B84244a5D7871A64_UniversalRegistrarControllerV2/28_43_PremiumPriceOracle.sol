// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StablePriceOracle.sol";
import "../universal/UniversalRegistrar.sol";
import "./SLDPriceOracle.sol";
import "../universal_v2/Access.sol";

// PremiumPriceOracle a price oracle with support for setting different prices for premium names.
contract PremiumPriceOracle is Ownable, Access {
    using SafeMath for *;
    using StringUtils for *;

    AggregatorInterface public immutable usdOracle;
    SLDPriceOracle public sldPriceOracle;

    // Rent in base price units by length. Element 0 is for 1-length names, and so on.
    uint256[] public defaultPrices;
    mapping(bytes32 => uint256[]) public rentPrices;
    mapping(bytes32 => uint256) public rentPricesUpdated;

    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => uint256))) public premiumPrices;
    mapping(bytes32 => uint256) public premiumPricesVersion;

    event NamePremium(bytes32 indexed node, string name, uint256 price);
    event PremiumsCleared(bytes32 indexed node);
    event RentPriceChanged(bytes32 node, uint256[] prices);
    event DefaultRentPriceChanged(uint256[] prices);

    bytes4 private constant INTERFACE_META_ID =
    bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 private constant ORACLE_ID =
    bytes4(keccak256("price(bytes32,string,uint256,uint256)"));

    constructor(SLDPriceOracle _sldPriceOracle, uint256[] memory _defaultPrices) Access(_sldPriceOracle.registrar()) {
        usdOracle = _sldPriceOracle.usdOracle();
        sldPriceOracle = _sldPriceOracle;
        _setDefaultPrices(_defaultPrices);
    }

    function price(bytes32 node, string calldata name, uint256 expires, uint256 duration) external view returns (uint256) {
        bytes32 label = keccak256(bytes(name));

        // if a premium price exists, return it
        if (premiumPrices[premiumPricesVersion[node]][node][label] != 0) {
            uint256 basePremium = premiumPrices[premiumPricesVersion[node]][node][label];
            return attoUSDToWei(basePremium.mul(duration));
        }

        // fallback to SLDPriceOracle if no prices set
        if (rentPricesUpdated[node] == 0) {
            return sldPriceOracle.price(node, name, expires, duration);
        }

        uint256 len = name.strlen();
        uint256[] memory prices = rentPrices[node].length > 0 ? rentPrices[node] : defaultPrices;

        if (len > prices.length) {
            len = prices.length;
        }
        require(len > 0);

        uint256 basePrice = prices[len - 1].mul(duration);
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

    function premium(bytes32 node, bytes32 label) external view returns (uint256) {
        return premiumPrices[premiumPricesVersion[node]][node][label];
    }

    /**
     * @dev Sets the rent price for a specific name.
     * @param node The node to set the rent price for.
     * @param name The name to set the rent price for.
     * @param _price The rent price. Values are in base
     * price units, equal to one attodollar (1e-18 dollar)
     * each (zero values will clear the price premium).
     */
    function setPremium(bytes32 node, string calldata name, uint256 _price) external nodeOperator(node) {
        bytes32 label = keccak256(bytes(name));
        premiumPrices[premiumPricesVersion[node]][node][label] = _price;
        emit NamePremium(node, name, _price);
    }

    function setPremiums(bytes32 node, string[] calldata names, uint256[] calldata prices) external nodeOperator(node) {
        require(names.length == prices.length, "names and prices must have the same length");
        for (uint i = 0; i < names.length; i++) {
            bytes32 label = keccak256(bytes(names[i]));
            premiumPrices[premiumPricesVersion[node]][node][label] = prices[i];
            emit NamePremium(node, names[i], prices[i]);
        }
    }

    function clearPremiums(bytes32 node) external nodeOperator(node) {
        premiumPricesVersion[node]++;
        emit PremiumsCleared(node);
    }

    /**
     * @dev Sets rent prices for the specified node (can only be called by the node owner)
     * @param _rentPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setPrices(bytes32 node, uint256[] memory _rentPrices) public nodeOperator(node) {
        require(block.timestamp - rentPricesUpdated[node] > 5 minutes);

        rentPrices[node] = _rentPrices;
        rentPricesUpdated[node] = block.timestamp;
        emit RentPriceChanged(node, _rentPrices);
    }

    /**
     * @dev Sets default rent prices to be used by nodes that don't have pricing set.
     * @param _defaultPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setDefaultPrices(uint256[] memory _defaultPrices) public onlyOwner {
        _setDefaultPrices(_defaultPrices);
    }

    function _setDefaultPrices(uint256[] memory _defaultPrices) internal {
        defaultPrices = _defaultPrices;
        emit DefaultRentPriceChanged(_defaultPrices);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool)
    {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}