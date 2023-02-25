// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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
            uint256 answer,
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
    mapping(bytes32 => address) public _aggregators; //currency => address

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        OPS_ADDR = 0x568532be655163B768826a8Ed7f1680AdB4211B3;
        _aggregators[
            0x4155440000000000000000000000000000000000000000000000000000000000
        ] = 0x77F9710E7d0A19669A13c055F62cd80d313dF022;
        _aggregators[
            0x42524c0000000000000000000000000000000000000000000000000000000000
        ] = 0x971E8F1B779A5F1C36e1cd7ef44Ba1Cc2F5EeE0f;
        _aggregators[
            0x4341440000000000000000000000000000000000000000000000000000000000
        ] = 0xa34317DB73e77d453b1B8d04550c44D10e981C8e;
        _aggregators[
            0x4348460000000000000000000000000000000000000000000000000000000000
        ] = 0x449d117117838fFA61263B61dA6301AA2a88B13A;
        _aggregators[
            0x434e590000000000000000000000000000000000000000000000000000000000
        ] = 0xeF8A4aF35cd47424672E3C590aBD37FBB7A7759a;
        _aggregators[
            0x4555520000000000000000000000000000000000000000000000000000000000
        ] = 0xb49f677943BC038e9857d61E7d053CaA2C1734C1;
        _aggregators[
            0x4742500000000000000000000000000000000000000000000000000000000000
        ] = 0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5;
        _aggregators[
            0x4a50590000000000000000000000000000000000000000000000000000000000
        ] = 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3;
        _aggregators[
            0x4e5a440000000000000000000000000000000000000000000000000000000000
        ] = 0x3977CFc9e4f29C184D4675f4EB8e0013236e5f3e;
        _aggregators[
            0x5452590000000000000000000000000000000000000000000000000000000000
        ] = 0xB09fC5fD3f11Cf9eb5E1C5Dba43114e3C9f477b5;
        currencyMap[
            0x494e520000000000000000000000000000000000000000000000000000000000
        ] = 0;
        currencyMap[
            0x4e474e0000000000000000000000000000000000000000000000000000000000
        ] = 1;
        currencyMap[
            0x5141520000000000000000000000000000000000000000000000000000000000
        ] = 2;
        currencyMap[
            0x5048500000000000000000000000000000000000000000000000000000000000
        ] = 3;

        currencyMap[
            0x5541480000000000000000000000000000000000000000000000000000000000
        ] = 4;
        currencyMap[
            0x5255420000000000000000000000000000000000000000000000000000000000
        ] = 5;
        currencyMap[
            0x5457440000000000000000000000000000000000000000000000000000000000
        ] = 6;
        currencyMap[
            0x4944520000000000000000000000000000000000000000000000000000000000
        ] = 7;
        currencyMap[
            0x484b440000000000000000000000000000000000000000000000000000000000
        ] = 8;
        currencyMap[
            0x564e440000000000000000000000000000000000000000000000000000000000
        ] = 9;
        currencyMap[
            0x5645530000000000000000000000000000000000000000000000000000000000
        ] = 10;
        currencyMap[
            0x5448420000000000000000000000000000000000000000000000000000000000
        ] = 11;
        currencyMap[
            0x504c4e0000000000000000000000000000000000000000000000000000000000
        ] = 12;
        currencyMap[
            0x4d584e0000000000000000000000000000000000000000000000000000000000
        ] = 13;
        currencyMap[
            0x53454b0000000000000000000000000000000000000000000000000000000000
        ] = 14;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setCurrencyMap(uint8 id, bytes32 cur) external onlyOwner {
        currencyMap[cur] = id;
    }

    function setAggregators(address addr, bytes32 cur) external onlyOwner {
        _aggregators[cur] = addr;
    }

    function setAddress(address addr) external onlyOwner {
        OPS_ADDR = addr;
    }

    function setAggregator(
        address[] calldata tokenAddr,
        address[] calldata aggregatorAddr
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            priceFeeds[tokenAddr[i]] = aggregatorAddr[i];
        }
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
        (, uint256 price1, , , ) = priceFeed.latestRoundData();
        price = uint256(price1);
        decimals = priceFeed.decimals();
    }

    function getRate(bytes32 currency) public view returns (uint256 rate) {
        if (
            currency ==
            0x5553440000000000000000000000000000000000000000000000000000000000
        ) {
            return 1000000000000000000;
        }
        if (_aggregators[currency] != address(0)) {
            AggregatorV3Interface priceFeed = AggregatorV3Interface(
                _aggregators[currency]
            );
            (, uint256 price1, , , ) = priceFeed.latestRoundData();
            uint8 decimals = priceFeed.decimals();

            return
                (uint256(10000 ether) / uint256(price1)) * 10**(12 - decimals);
        }

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