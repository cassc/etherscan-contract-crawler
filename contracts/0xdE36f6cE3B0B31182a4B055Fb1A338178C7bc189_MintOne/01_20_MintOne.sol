// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./ShoutoutNFT.sol";

contract MintOne is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter public nftIdCounter;

    struct Token {
        IERC20 token;
        address[] path;
        uint256 decimals;
    }

    struct Feed {
        AggregatorV3Interface feed;
        uint256 decimals;
        uint256 multiplier0;
        uint256 multiplier1;
    }

    bool public paused = false;
    bool public miscActive = true;

    ShoutoutNFT public shoutoutNFT;

    mapping(uint256 => Feed) public feeds;
    mapping(address => Token) public tokens;
    uint256[] public prices;

    /// @notice _prices must be ordered from low to high
    constructor(address _yfuNFT, uint256[] memory _prices) {
        shoutoutNFT = ShoutoutNFT(_yfuNFT);
        for (uint256 i = 0; i < _prices.length; i++) {
            prices.push(_prices[i]);
        }

        // ETH / USD
        feeds[0] = Feed({
            feed: AggregatorV3Interface(
                0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            ),
            decimals: 8,
            multiplier0: 1e18,
            multiplier1: 1e18
        });
        // DAI / USD
        feeds[1] = Feed({
            feed: AggregatorV3Interface(
                0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9
            ),
            decimals: 8,
            multiplier0: 1e18,
            multiplier1: 1e18
        });
        // USDC / USD
        feeds[2] = Feed({
            feed: AggregatorV3Interface(
                0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6
            ),
            decimals: 18,
            multiplier0: 1e18,
            multiplier1: 1e8
        });
    }

    function activeMisc(bool _val) external onlyOwner {
        miscActive = _val;
    }

    function setTokens(Token[] memory _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens[address(_tokens[i].token)] = Token({
                token: IERC20(_tokens[i].token),
                path: _tokens[i].path,
                decimals: _tokens[i].decimals
            });
        }
    }

    function setFeed(uint256 _feedIdx, Feed memory _feed) external onlyOwner {
        feeds[_feedIdx] = _feed;
    }

    // public
    function mint(address _to) public payable {
        uint256 supply = shoutoutNFT.totalSupply();

        require(!paused, "Paused");
        (bool validValue, uint256 _type) = _checkMsgValue(msg.value);
        require(validValue, "!invalid eth value");
        uint256 _cost = getPrice(0, _type);
        require(msg.value >= _cost, "!cost min amount");

        nftIdCounter.increment();
        shoutoutNFT.mint(_to, nftIdCounter.current());
        if (miscActive) {
            uint256[] memory _ids = new uint256[](1);
            _ids[0] = nftIdCounter.current();
            uint256[] memory _values = new uint256[](1);
            _values[0] = _type;

            shoutoutNFT.setMisc(_ids, _values);
        }
    }

    function mintWithEth(uint256 _type) external payable {
        uint256 supply = shoutoutNFT.totalSupply();
        uint256 usdPrice = prices[_type];
        uint256 _cost = getPrice(0, prices[_type]);
        require(!paused, "Paused");
        require(msg.value >= _cost, "!cost min amount");

        nftIdCounter.increment();
        shoutoutNFT.mint(msg.sender, nftIdCounter.current());
        if (miscActive) {
            uint256[] memory _ids = new uint256[](1);
            _ids[0] = nftIdCounter.current();
            uint256[] memory _values = new uint256[](1);
            _values[0] = _type;

            shoutoutNFT.setMisc(_ids, _values);
        }
    }

    function mintWithToken(address _token, uint256 _type) external {
        uint256 supply = shoutoutNFT.totalSupply();
        require(!paused, "Paused");

        Token memory token = tokens[_token];
        uint256 feed;
        uint256 _cost = getPrice(1, prices[_type]);
        uint256 tokenBalance = IERC20(_token).balanceOf(msg.sender);

        tokenBalance = _handleDecimals(tokenBalance, token.decimals);

        require(tokenBalance >= _cost, "insufficient balance");

        IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            token.decimals == 18 ? _cost : (_cost * 1e6) / 1e18
        );

        nftIdCounter.increment();
        shoutoutNFT.mint(msg.sender, nftIdCounter.current());
        if (miscActive) {
            uint256[] memory _ids = new uint256[](1);
            _ids[0] = nftIdCounter.current();
            uint256[] memory _values = new uint256[](1);
            _values[0] = _type;

            shoutoutNFT.setMisc(_ids, _values);
        }
    }

    function setCost(uint256[] memory _newCosts) public onlyOwner {
        for (uint256 i = 0; i < prices.length; i++) {
            prices.pop();
        }

        for (uint256 i = 0; i < _newCosts.length; i++) {
            prices.push(_newCosts[i]);
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawTokens(address[] memory _tokens, address _escrow)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(
                _escrow,
                IERC20(_tokens[i]).balanceOf(address(this))
            );
        }
    }

    function _calculatePercentage(uint256 _amount, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _percentage) / 10000;
    }

    function _handleDecimals(uint256 _a, uint256 _d)
        internal
        pure
        returns (uint256 result)
    {
        uint256 exp = 18 - _d;
        result = _a * (10**exp);
    }

    function _checkMsgValue(uint256 _value)
        internal
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < prices.length; i++) {
            if (i < prices.length - 1) {
                if (
                    _value >= getPrice(0, prices[i]) &&
                    _value < getPrice(0, prices[i + 1])
                ) {
                    return (true, i);
                }
            } else {
                if (_value >= getPrice(0, prices[i])) {
                    return (true, i);
                }
            }
        }

        return (false, 0);
    }

    function getPrice(uint256 _feed, uint256 _usdBasePrice)
        public
        view
        returns (uint256 _price)
    {
        Feed memory feed = feeds[_feed];
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = feed.feed.latestRoundData();
        uint256 adjustedPrice;

        if (feed.decimals == 18) {
            adjustedPrice = uint256(price);
            _price =
                _usdBasePrice.mul(feed.multiplier0).div(adjustedPrice) *
                feed.multiplier1;
        } else {
            adjustedPrice = uint256(price).div(1e8);
            if (adjustedPrice == 0) {
                _price = _usdBasePrice.mul(feed.multiplier0);
            } else {
                _price = _usdBasePrice.mul(feed.multiplier0).div(adjustedPrice);
            }
        }
        return _price;
    }

    function getPrices() public view returns (uint256[] memory) {
        return prices;
    }
}