// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IMinimalChainlinkFeedRegistry.sol";
import "../interfaces/IEACAggregatorProxy.sol";

// Minimal Chainlink Feedregistry
contract MinimalChainlinkFeedRegistry is IMinimalChainlinkFeedRegistry, AccessControl {
    bytes32 public constant ORACLE_ADMIN = keccak256(abi.encode("ORACLE_ADMIN"));

    struct Feed {
        address oracle;
        uint8 decimals;
    }

    mapping(address => mapping(address => Feed)) public feeds;
    
    constructor() {
        _setupRole(ORACLE_ADMIN, msg.sender);
    }
    
    function getFeed(address _base, address _quote) public view returns (Feed memory) {
        return feeds[_base][_quote];
    }
    
    function decimals(address _base, address _quote) external view override returns (uint8) {
        Feed memory feed = getFeed(_base, _quote);
        require(feed.oracle != address(0), "Feed not found");
        return feed.decimals;
    }
    
    function latestRoundData(address _base, address _quote) external view override
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) {
        Feed memory feed = getFeed(_base, _quote);
        require(feed.oracle != address(0), "Feed not found");
        return IEACAggregatorProxy(feed.oracle).latestRoundData();
    }

    function registerFeed(address _base, address _quote, address _oracle, uint8 _decimals) 
        external onlyRole(ORACLE_ADMIN) {
        require(_base != address(0) && _quote != address(0) && _oracle != address(0), "ERR_ZERO_ADDRESS");
        feeds[_base][_quote].oracle = _oracle;
        feeds[_base][_quote].decimals = _decimals;
    }
    
    function initialize(address[] calldata bases, address[] calldata quotes, address[] calldata oracles, uint8[] calldata decimals)
        external onlyRole(ORACLE_ADMIN) {
        require(bases.length == quotes.length && quotes.length == oracles.length && oracles.length == decimals.length, 'ERR_ARRAY_LENGTH');
        for (uint256 i = 0; i < bases.length; i++) {
            require(bases[i] != address(0) && quotes[i] != address(0) && oracles[i] != address(0), 'ERR_ADDRESS_ZERO');
            Feed storage feed = feeds[bases[i]][quotes[i]];
            feed.oracle = oracles[i];
            feed.decimals = decimals[i];
        }
    }
}