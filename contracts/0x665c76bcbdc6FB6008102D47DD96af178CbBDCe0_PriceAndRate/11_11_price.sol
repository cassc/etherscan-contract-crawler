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
    mapping(bytes32 => uint256) public rates; //currency => rate
    mapping(address => bool) public dataUsers; //feedData

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

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

    function setRates(bytes32[] calldata currencys, uint256[] calldata rates_)
        public
    {
        require(OPS_ADDR == msg.sender, "invalid address");
        require(currencys.length == rates_.length, "len unequal");
        for (uint256 i = 0; i < currencys.length; i++) {
            rates[currencys[i]] = rates_[i];
        }
        emit SetRates(msg.sender, currencys, rates_);
    }

    event SetRates(address setAccount, bytes32[] currencys, uint256[] rates_);

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
        return rates[currency];
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