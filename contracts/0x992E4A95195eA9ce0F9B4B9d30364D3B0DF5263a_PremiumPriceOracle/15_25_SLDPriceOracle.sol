// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StablePriceOracle.sol";
import "../universal/UniversalRegistrar.sol";

// SLDPriceOracle sets a price in USD, based on an oracle for each node.
// The registry can set and change default prices. However, if the node owner
// sets their own price, they will override the default.
contract SLDPriceOracle is Ownable {
    using SafeMath for *;
    using StringUtils for *;

    // Rent in base price units by length. Element 0 is for 1-length names, and so on.
    mapping(bytes32 => uint256[]) public rentPrices;
    uint256[] public defaultPrices;

    // Oracle address
    AggregatorInterface public immutable usdOracle;
    // Registrar address
    UniversalRegistrar public registrar;

    /**
     * @dev Throws if called by any account other than the node owner.
     */
    modifier onlyNodeOwner(bytes32 node) {
        require(registrar.ownerOfNode(node) == _msgSender(), "caller is not the node owner");
        _;
    }

    event OracleChanged(address oracle);

    event RentPriceChanged(bytes32 node, uint256[] prices);
    event DefaultRentPriceChanged(uint256[] prices);

    bytes4 private constant INTERFACE_META_ID =
    bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 private constant ORACLE_ID =
    bytes4(keccak256("price(bytes32,string,uint256,uint256)"));

    constructor(UniversalRegistrar _registrar, AggregatorInterface _usdOracle, uint256[] memory _defaultPrices) {
        registrar = _registrar;
        usdOracle = _usdOracle;
        defaultPrices = _defaultPrices;
    }

    function price(bytes32 node, string calldata name, uint256 expires, uint256 duration) external view returns (uint256) {
        uint256 len = name.strlen();
        uint256[] memory prices = rentPrices[node].length > 0 ? rentPrices[node] : defaultPrices;

        if (len > prices.length) {
            len = prices.length;
        }
        require(len > 0);

        uint256 basePrice = prices[len - 1].mul(duration);
        return attoUSDToWei(basePrice);
    }

    /**
     * @dev Sets rent prices for the specified node (can only be called by the node owner)
     * @param _rentPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setPrices(bytes32 node, uint256[] memory _rentPrices) public onlyNodeOwner(node) {
        rentPrices[node] = _rentPrices;
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
        defaultPrices = _defaultPrices;
        emit DefaultRentPriceChanged(_defaultPrices);
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