// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISimpleToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply
    ) external payable;
}

interface IStandardToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees
    ) external payable;
}

interface IReflectionToken {
    function initialize(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees
    ) external payable;
}

interface IDividendToken {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee
    ) external payable;
}

interface ISimpleTokenWithAntiBot {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address _gemAntiBot
    ) external payable;
}

interface IStandardTokenWithAntiBot {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees,
        address _gemAntiBot
    ) external payable;
}

interface IReflectionTokenWithAntiBot {
    function initialize(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees,
        address _gemAntiBot
    ) external payable;
}

interface IDividendTokenWithAntiBot {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee,
        address _gemAntiBot
    ) external payable;
}

contract TokenFactory is Ownable {
    using Counters for Counters.Counter;

    enum TokenType {
        SIMPLE,
        STANDARD,
        REFELCTION,
        DIVIDEND,
        SIMPLE_ANTIBOT,
        STANDARD_ANTIBOT,
        REFELCTION_ANTIBOT,
        DIVIDEND_ANTIBOT
    }

    struct Token {
        address tokenAddress;
        TokenType tokenType;
    }

    Counters.Counter private tokenCounter;
    mapping(uint256 => Token) public tokens;

    address[8] implementations = [
        0xbeF3722808c168976A9020Af564F429De9187476,
        0xc518b2976eB3fED233715d8B2Cfa5dFc249F41ff,
        0x70AafA63a483d237D22373b6BB34624870c23e29,
        0xD2f62E7800e8EaC6848865F1Fd5a290571468C6b,
        0x5Ed11eA5Ae0F7674a7BABF184c5957BBF36C056a,
        0xB67D1e00909B1F2e1718Ed76C793cb7CB6f13158,
        0x90e9eBBa63A812cCc0Ea032107e15f3B5990ED32,
        0x3CCBDBB61de286c57331cc0049AF793CD03F229B
    ];

    uint256[4] fees = [0.1 ether, 0.1 ether, 0.1 ether, 0.1 ether];

    constructor() {}

    function createSimpleToken(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply
    ) external payable {
        require(msg.value >= fees[0], "createSimpleToken::Fee is not enough");
        address newToken = Clones.clone(implementations[0]);
        ISimpleToken(newToken).initialize{value: msg.value}(
            _name,
            _symbol,
            __decimals,
            _totalSupply
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.SIMPLE;
        tokenCounter.increment();
    }

    function createStandardToken(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees
    ) external payable {
        require(msg.value >= fees[1], "createStandardToken::Fee is not enough");
        address newToken = Clones.clone(implementations[1]);
        IStandardToken(newToken).initialize{value: msg.value}(
            _name,
            _symbol,
            __decimals,
            _totalSupply,
            _maxWallet,
            _maxTransactionAmount,
            _accounts,
            _isMarketingFeeBaseToken,
            _fees
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.STANDARD;
        tokenCounter.increment();
    }

    function createReflectionToken(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees
    ) external payable {
        require(
            msg.value >= fees[2],
            "createReflectionToken::Fee is not enough"
        );
        address newToken = Clones.clone(implementations[2]);
        IReflectionToken(newToken).initialize{value: msg.value}(
            __name,
            __symbol,
            __decimals,
            _totalSupply,
            _maxWallet,
            _maxTransactionAmount,
            _accounts,
            _isMarketingFeeBaseToken,
            _fees
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.REFELCTION;
        tokenCounter.increment();
    }

    function createDividendToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee
    ) external payable {
        require(msg.value >= fees[3], "createDividendToken::Fee is not enough");
        address newToken = Clones.clone(implementations[3]);
        IDividendToken(newToken).initialize{value: msg.value}(
            name_,
            symbol_,
            decimals_,
            totalSupply_,
            _maxWallet,
            _maxTransactionAmount,
            addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
            feeSettings, // rewards, liquidity, marketing
            minimumTokenBalanceForDividends_,
            _tokenForMarketingFee
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.DIVIDEND;
        tokenCounter.increment();
    }

    function createSimpleTokenWithAntiBot(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address _gemAntiBot
    ) external payable {
        require(msg.value >= fees[0], "createSimpleToken::Fee is not enough");
        address newToken = Clones.clone(implementations[4]);
        ISimpleTokenWithAntiBot(newToken).initialize{value: msg.value}(
            _name,
            _symbol,
            __decimals,
            _totalSupply,
            _gemAntiBot
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.SIMPLE_ANTIBOT;
        tokenCounter.increment();
    }

    function createStandardTokenWithAntiBot(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees,
        address _gemAntiBot
    ) external payable {
        require(msg.value >= fees[1], "createStandardToken::Fee is not enough");
        address newToken = Clones.clone(implementations[5]);
        IStandardTokenWithAntiBot(newToken).initialize{value: msg.value}(
            _name,
            _symbol,
            __decimals,
            _totalSupply,
            _maxWallet,
            _maxTransactionAmount,
            _accounts,
            _isMarketingFeeBaseToken,
            _fees,
            _gemAntiBot
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.STANDARD_ANTIBOT;
        tokenCounter.increment();
    }

    function createReflectionTokenWithAntiBot(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees,
        address _gemAntiBot
    ) external payable {
        require(
            msg.value >= fees[2],
            "createReflectionToken::Fee is not enough"
        );
        address newToken = Clones.clone(implementations[6]);
        IReflectionTokenWithAntiBot(newToken).initialize{value: msg.value}(
            __name,
            __symbol,
            __decimals,
            _totalSupply,
            _maxWallet,
            _maxTransactionAmount,
            _accounts,
            _isMarketingFeeBaseToken,
            _fees,
            _gemAntiBot
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.REFELCTION_ANTIBOT;
        tokenCounter.increment();
    }

    function createDividendTokenWithAntiBot(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee,
        address _gemAntiBot
    ) external payable {
        require(msg.value >= fees[3], "createDividendToken::Fee is not enough");
        address newToken = Clones.clone(implementations[7]);
        IDividendTokenWithAntiBot(newToken).initialize{value: msg.value}(
            name_,
            symbol_,
            decimals_,
            totalSupply_,
            _maxWallet,
            _maxTransactionAmount,
            addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
            feeSettings, // rewards, liquidity, marketing
            minimumTokenBalanceForDividends_,
            _tokenForMarketingFee,
            _gemAntiBot
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.DIVIDEND_ANTIBOT;
        tokenCounter.increment();
    }

    function getAllTokens() external view returns (Token[] memory) {
        Token[] memory _tokens = new Token[](tokenCounter.current());
        for (uint256 i = 0; i < tokenCounter.current(); i++) {
            _tokens[i].tokenAddress = tokens[i].tokenAddress;
            _tokens[i].tokenType = tokens[i].tokenType;
        }
        return _tokens;
    }

    receive() external payable {}
}