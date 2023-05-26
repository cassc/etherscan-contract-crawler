// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISynthetix.sol";
import "../interfaces/IExperiPie.sol";
import "../interfaces/IPriceReferenceFeed.sol";

contract RSISynthetixManager {

    address public immutable assetShort;
    address public immutable assetLong;
    bytes32 public immutable assetShortKey;
    bytes32 public immutable assetLongKey;

    // Value under which to go long (30 * 10**18 == 30)
    int256 public immutable rsiBottom;
    // Value under which to go short
    int256 public immutable rsiTop;

    IPriceReferenceFeed public immutable priceFeed;
    IExperiPie public immutable basket;
    ISynthetix public immutable synthetix;

    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt; 
        uint256 updatedAt; 
        uint80 answeredInRound;
    }

    event Rebalanced(address indexed basket, address indexed fromToken, address indexed toToken);

    constructor(
        address _assetShort,
        address _assetLong,
        bytes32 _assetShortKey,
        bytes32 _assetLongKey,
        int256 _rsiBottom,
        int256 _rsiTop,
        address _priceFeed,
        address _basket,
        address _synthetix
    ) {
        assetShort = _assetShort;
        assetLong = _assetLong;
        assetShortKey = _assetShortKey;
        assetLongKey = _assetLongKey;

        require(_assetShort != address(0), "INVALID_ASSET_SHORT");
        require(_assetLong != address(0), "INVALID_ASSET_LONG");
        require(_assetShortKey != bytes32(0), "INVALID_ASSET_SHORT_KEY");
        require(_assetLongKey != bytes32(0), "INVALID_ASSET_LONG_KEY");

        require(_rsiBottom < _rsiTop, "RSI bottom should be bigger than RSI top");
        require(_rsiBottom > 0, "RSI bottom should be bigger than 0");
        require(_rsiTop < 100 * 10**18, "RSI top should be less than 100");

        require(_priceFeed != address(0), "INVALID_PRICE_FEED");
        require(_basket != address(0), "INVALID_BASKET");
        require(_synthetix != address(0), "INVALID_SYNTHETIX");

        rsiBottom = _rsiBottom;
        rsiTop = _rsiTop;

        priceFeed = IPriceReferenceFeed(_priceFeed);
        basket = IExperiPie(_basket);
        synthetix = ISynthetix(_synthetix);
    }


    function rebalance() external {
        RoundData memory roundData = readLatestRound();
        require(roundData.updatedAt > 0, "Round not complete");

        if(roundData.answer <= rsiBottom) {
            // long
            long();
            return;
        } else if(roundData.answer >= rsiTop) {
            // Short
            short();
            return;
        }
    }

    function long() internal {
        IERC20 currentToken = IERC20(getCurrentToken());
        require(address(currentToken) == assetShort, "Can only long when short");

        uint256 currentTokenBalance = currentToken.balanceOf(address(basket));

        address[] memory targets = new address[](4);
        bytes[] memory data = new bytes[](4);
        uint256[] memory values = new uint256[](4);

        // lock pool
        targets[0] = address(basket);
        // lock for 30
        data[0] = setLockData(block.number + 30);

        // Swap on synthetix
        targets[1] = address(synthetix);
        data[1] = abi.encodeWithSelector(synthetix.exchange.selector, assetShortKey, currentTokenBalance, assetLongKey);


        // Remove current token
        targets[2] = address(basket);
        data[2] = abi.encodeWithSelector(basket.removeToken.selector, assetShort);

        // Add new token
        targets[3] = address(basket);
        data[3] = abi.encodeWithSelector(basket.addToken.selector, assetLong);

        // Do calls
        basket.call(targets, data, values);

        // sanity checks
        require(currentToken.balanceOf(address(basket)) == 0, "Current token balance should be zero");
        require(IERC20(assetLong).balanceOf(address(basket)) >= 10**6, "Amount too small");

        emit Rebalanced(address(basket), assetShort, assetLong);
    }

    function short() internal {
        IERC20 currentToken = IERC20(getCurrentToken());
        require(address(currentToken) == assetLong, "Can only short when long");

        uint256 currentTokenBalance = currentToken.balanceOf(address(basket));

        address[] memory targets = new address[](4);
        bytes[] memory data = new bytes[](4);
        uint256[] memory values = new uint256[](4);

        // lock pool
        targets[0] = address(basket);
        // lock for 30
        data[0] = setLockData(block.number + 30);

        // Swap on synthetix
        targets[1] = address(synthetix);
        data[1] = abi.encodeWithSelector(synthetix.exchange.selector, assetLongKey, currentTokenBalance, assetShortKey);

        // Remove current token
        targets[2] = address(basket);
        data[2] = abi.encodeWithSelector(basket.removeToken.selector, assetLong);

        // Add new token
        targets[3] = address(basket);
        data[3] = abi.encodeWithSelector(basket.addToken.selector, assetShort);

        // Do calls
        basket.call(targets, data, values);

        // sanity checks
        require(currentToken.balanceOf(address(basket)) == 0, "Current token balance should be zero");
        
        // Catched by addToken in the basket itself
        // require(IERC20(assetShort).balanceOf(address(basket)) >= 10**6, "Amount too small");

        emit Rebalanced(address(basket), assetShort, assetLong);
    }

    function getCurrentToken() public view returns(address) {
        address[] memory tokens = basket.getTokens();
        require(tokens.length == 1, "RSI Pie can only have 1 asset at the time");
        return tokens[0];
    }


    function setLockData(uint256 _block) internal returns(bytes memory data) {
        bytes memory data = abi.encodeWithSelector(basket.setLock.selector, _block);
        return data;
    }
    function readRound(uint256 _round) public view returns(RoundData memory data) {
        (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        ) = priceFeed.getRoundData(uint80(_round));

        return RoundData({
            roundId: roundId,
            answer: answer,
            startedAt: startedAt,
            updatedAt: updatedAt,
            answeredInRound: answeredInRound
        });
    }

    function readLatestRound() public view returns(RoundData memory data) {
        (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return RoundData({
            roundId: roundId,
            answer: answer,
            startedAt: startedAt,
            updatedAt: updatedAt,
            answeredInRound: answeredInRound
        });
    }

}