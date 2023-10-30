// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./currency/ICurrencyFeed.sol";
import "./Members.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract CrowdSale is Context, ReentrancyGuard, Ownable, Members {
    using SafeMath  for uint256;
    using SafeERC20 for IERC20;
    IERC20 private  _token;

    address payable private _devWallet;
    address payable private _refWallet;

    uint64 private DEFAULT_RATE = 20;

    ICurrencyFeed _currencyFeed;
    bool private _enabled;

    struct Shares {
        uint256 beneficiaryTokenWei;
        uint256 devWei;
        uint256 refWei;
        uint256 refTokenWei;
    }

    struct Quote{
        uint80  roundId;
        string  symbol;
        uint256 unitPrice; 
        uint256 min;
        uint256 max;
        uint256 rate;
        uint256 weiInCents;
        uint256 tokenWei; 
        bool    whiteListed;
    }

    event TokensPurchased(
        address Beneficiary,
        string  Pair,
        uint256 Wei,
        uint256 Usd,
        uint256 Tokens,
        uint256 DQuote,
        uint256 RBase,
        uint256 RQuote
    );

    constructor(
        IERC20 tokenContract,
        address payable wallet 
    ) 
    {
        require(wallet != address(0x0), "wallet: zero address");
        require(address(tokenContract) != address(0x0), "token : zero address");
        _token = tokenContract;
        _devWallet = wallet;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    receive() external payable 
    {
        revert();
        // buyTokens("ETH", msg.value, DEFAULT_REFERRER); // only eth; eth decimals 18
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function buyTokens(string memory symbol, uint256 weiAmount, uint256 code, uint80 roundId ) 
    public 
    _whenSaleEnabled(_enabled)
    payable nonReentrant
    {
        address _beneficiary = _msgSender();
        uint256 _weiAmount   = weiAmount;

        Referrer memory referrer = getMemberOrDefault(code);
        _refWallet = payable(referrer.member.wallet);

        require(_beneficiary != _refWallet, "Referral: Not allowed");

        if(referrer.member.whiteList) {
            require(isWhiteListed(code, _beneficiary), "Whitelist: Not found");
        }

        ICurrencyFeed.Price memory _price = _weiUnitPrice(symbol, roundId);
        uint256 _weiInCents = _weiToCents(_price.currency.decimals, _weiAmount, _price.unitPrice);

        Shares memory _share = _processShares(_weiAmount, _weiInCents, referrer);

        if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("ETH"))) {
            require(_weiAmount == msg.value, "Wei mismatch");
            // // send tokens to beneficiary
            _token.safeTransfer(_beneficiary, _share.beneficiaryTokenWei);
            // forward receied eth to dev wallet
            _devWallet.transfer(_share.devWei);
            // deliver commission to referrer
            _refWallet.transfer(_share.refWei);
            _token.safeTransfer(_refWallet, _share.refTokenWei);
        } else {
            IERC20 _quoteToken = _price.currency.tokenContract;
            require(_quoteToken.allowance(_msgSender(), address(this)) >= _weiAmount, "Beneficiary: Not enough allowance");
            // forward receied quote currency to dev wallet        
            _quoteToken.safeTransferFrom(_beneficiary, _devWallet , _share.devWei);
            // process commissions : quote currency
            _quoteToken.safeTransferFrom(_beneficiary, _refWallet , _share.refWei);

            // send tokens to beneficiary
            _token.safeTransfer(_beneficiary, _share.beneficiaryTokenWei);
            // process commissions : base currency
            _token.safeTransfer(_refWallet, _share.refTokenWei);
        }

        string memory _pair = _salePairName(symbol);
        
        emit TokensPurchased(
            _beneficiary,
            _pair,
            _weiAmount,
            _weiInCents,
            _share.beneficiaryTokenWei,
            _share.devWei,
            _share.refTokenWei,
            _share.refWei
        );
    }

    /**
     * @return the token being sold.
     */
    function getToken() 
    public view 
    returns (IERC20) 
    {
        return _token;
    }

    function setToken(IERC20 token) 
    external 
    onlyOwner
    {
        _token = token;
    }

    /**
     * @return the address where funds are collected.
     */
    function getWallet() 
    external view 
    returns (address payable) 
    {
        return _devWallet;
    }

    function setWallet(address payable  wallet) 
    external
    onlyOwner
    {
        _devWallet = wallet;
    }

    function getDefaultRate() 
    external view 
    returns (uint64) 
    {
        return DEFAULT_RATE;
    }

    function setDefaultRate(uint64 rate) 
    public 
    onlyOwner 
    {
        DEFAULT_RATE = rate;
    }

    function getCurrencyFeed() 
    public view
    returns(ICurrencyFeed feed)
    {
        return _currencyFeed;
    }

    function setCurrencyFeed(address feed) 
    external 
    onlyOwner 
    {
        _currencyFeed = ICurrencyFeed(feed);
    }

    function getRate(uint256 cents, Range memory range, bool isCommission)
    internal view
    returns (uint64)
    {
        if(isCommission)
            return DEFAULT_RATE;

        for (uint256 i = 0; i < range.size; i++) {
            if (cents >= range.limits[i].min && cents <= range.limits[i].max)
                return range.limits[i].rate;
        }
        return DEFAULT_RATE;
    }

    function getRange(Range memory range) 
    internal pure
    returns (uint256, uint256)
    {
        return (range.limits[0].min, range.limits[range.size - 1].max);
    }

    function setEnabled(bool enabled) 
    external onlyOwner 
    {
        _enabled = enabled;
    }
    
    function getEnabled() 
    external view returns(bool) 
    {
        return _enabled;
    }

    function _processShares(
        uint256 weiAmount,
        uint256 weiInCents,
        Referrer memory referrer
    )
    internal view
    _whenValidAmount(weiInCents, referrer.range)
    _whenValidUser(referrer.member.wallet)
    returns (Shares memory)
    {
        (, uint256 _benefTokenWei) = _centsToTokenWei(weiInCents, referrer.range, false);

        uint256 _refWei = _percentageOf(weiAmount, referrer.commission.quote);
        uint256 _refCents = _percentageOf(weiInCents, referrer.commission.quote);
        (, uint256 _refTokenWei) = _centsToTokenWei(_refCents, referrer.range, true);

        uint256 _devWei = weiAmount - _refWei;
        return Shares(_benefTokenWei, _devWei, _refWei, _refTokenWei);
    }

    /*
     *  @param currency  : Currency object
     *  @param weiAmount : amount in smallest units of ETH/ERC20(USDT) Token to be converted
     *  @param unitPrice : unit price of ETH/ERC20(USDT) in cents
     */
    function _weiToCents(uint256 weiDecimals, uint256 weiAmount, uint256 unitPrice) 
    internal pure returns (uint256) 
    {
        return unitPrice.mul(weiAmount).div(10**weiDecimals);
    }

    function _weiUnitPrice(string memory symbol) 
    internal view
    returns (ICurrencyFeed.Price memory)
    {
        ICurrencyFeed.Price memory price = _currencyFeed.getPrice(symbol);
        return price;
    }

    function _weiUnitPrice(string memory symbol, uint80 roundId) 
    internal view
    returns (ICurrencyFeed.Price memory)
    {
        ICurrencyFeed.Price memory price = _currencyFeed.getPrice(symbol, roundId);
        return price;
    }

    function _centsToTokenWei(uint256 cents, Range memory range, bool isCommission) 
    internal view
    returns (uint256, uint256)
    {
        uint256 rate = getRate(cents, range, isCommission);
        return (rate, _oneCentToTokenWei(rate).mul(cents));
    }

    function _oneCentToTokenWei(uint256 rate ) 
    internal view 
    returns (uint256) 
    {
        uint256 _decimals = ERC20(address(_token)).decimals();
        return rate.mul(10**_decimals).div(1e2);
    }

    function _salePairName(string memory symbol)
    internal view
    returns (string memory)
    {
        return string(abi.encodePacked(ERC20(address(_token)).symbol(), symbol));
    }

    function _percentageOf(uint256 total, uint256 percent)
    internal pure
    returns (uint256)
    {
        return total.mul(percent).div(100);
    }

    // code = memeberid
    function getQuote(string memory symbol, uint256 weiAmount, uint256 code) 
    external view 
    returns(Quote memory quote)
    {
        Referrer memory referrer = getMemberOrDefault(code);
        (uint256 min, uint256 max) = getRange(referrer.range);
        ICurrencyFeed.Price memory _price = _weiUnitPrice(symbol);
        uint256 _weiInCents = _weiToCents(_price.currency.decimals, weiAmount, _price.unitPrice);
        (uint256 _rate, uint256 _tokenWei) = _centsToTokenWei(_weiInCents, referrer.range, false);
        if(_weiInCents < min || _weiInCents > max)
        {
            _tokenWei = 0;
        }
        return Quote(_price.priceRound.roundId, _price.currency.symbol, _price.unitPrice, min, max, _rate, _weiInCents, _tokenWei, referrer.member.whiteList);
    }

    function balance(IERC20 token) 
    public view 
    onlyOwner
    returns(uint256) 
    {
        return IERC20(token).balanceOf(address(this));
    }

    function recover(IERC20 token) 
    public 
    onlyOwner 
    {
        IERC20(token).safeTransfer(_devWallet, balance(token));
    }

    modifier _whenValidAmount(uint256 weiInCents, Range memory range) 
    {
        (uint256 min, uint256 max) = getRange(range);
        require(weiInCents >= min && weiInCents <= max, "Invalid amount");
        _;
    }

    modifier _whenCurrencyFeed(ICurrencyFeed feed) 
    {
        require(address(feed) != address(0), "CurrencyFeed unavailable");
        _;
    }

    modifier _whenSaleEnabled(bool enabled)
    {
        require(enabled == true, "Sale : Not active");
        _;
    }

    modifier _whenValidUser(address referrer) {
        require(msg.sender !=referrer, "Error: Self reference");
        _;
    }
}