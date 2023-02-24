// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PriceAndRate is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address private OPS_ADDR;
    mapping(address => address) public priceFeeds; //token => Aggregrator  (token  => EACAggregatorProxy)
    mapping(uint8 => uint256) public rates; //id => rate
    mapping(bytes32 => uint8) public currencyMap; //currency => id

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setCurrencyMap(bytes32[] calldata list) external onlyOwner {
        for (uint8 i = 0; i < list.length; i++) {
            currencyMap[list[i]] = i;
        }
    }

    function setAddress(address addr) external onlyOwner {
        OPS_ADDR = addr;
    }

    event SetAggregrator(address setAccount, address[] token_, address[] aggrs);

    function setAggregator(
        address[] calldata tokenAddr,
        address[] calldata aggregatorAddr
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            priceFeeds[tokenAddr[i]] = aggregatorAddr[i];
        }

        emit SetAggregrator(msg.sender, tokenAddr, aggregatorAddr);
    }

    function setRates(uint256[] calldata rates_) public {
        require(OPS_ADDR == msg.sender, "invalid address");

        for (uint8 i = 0; i < rates_.length; i++) {
            rates[i] = rates_[i];
        }
    }

    function getPrice(address token)
        public
        view
        returns (uint256 price, uint8 decimals)
    {
        address aggr = priceFeeds[token];
        if (aggr == address(0)) return (0, 0);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(aggr);
        (
            ,
            /*uint80 roundID*/
            int256 price1, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        price = uint256(price1);
        decimals = priceFeed.decimals();
    }

    function getRate(bytes32 currency) public view returns (uint256 rate) {
        return rates[currencyMap[currency]];
    }

    function getPriceAndRate(address token, bytes32 currency)
        public
        view
        returns (
            uint256 price,
            uint8 decimals,
            uint256 rate
        )
    {
        (price, decimals) = getPrice(token);
        rate = getRate(currency);
    }
}