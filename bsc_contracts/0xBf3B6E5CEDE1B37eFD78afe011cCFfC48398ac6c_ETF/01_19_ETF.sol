// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IETF.sol";
import "./pancake/libraries/PancakeLibrary.sol";
import "./pancake/interfaces/IPancakeRouter02.sol";


contract ETF is IETF, ERC20, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /* Structs */
    struct ETFTokenConfiguration {
        address token;
        uint256 weight;
        address[] intermediaries; // token => native order
    }

    struct ConstructorERC20 {
        string name;
        string symbol;
    }

    struct ConstructorAddresses {
        address router;
        address native;
        address ownerSource;
        address treasury;
    }

    struct ConstructorQuantitative {
        uint256 joinFee;
        uint256 exitFee;
        uint256 swapFee;
        uint256 maxDeviationPercent;
    }

    /* Public constants */
    uint256 constant public DIVIDER = 10000;
    uint256 constant public PRECISION = 1e18;

    /* Public variables */
    address public factory;
    address public router;
    uint256 public swapFee;
    address public ownerSource;
    address public treasury;
    address public native;
    uint256 public joinFee;
    uint256 public exitFee;

    uint256 public maxDeviationPercent;

    mapping(address => address[]) public swapPathsTokenToNative;
    mapping(address => address[]) public swapPathsNativeToToken;
    mapping(address => uint256) public weights;

    /* Private variables */
    EnumerableSet.AddressSet private _tokens;

    function tokensCount() external view returns (uint256) {
        return _tokens.length();
    }

    function tokens(uint256 _index) external view returns (address) {
        return _tokens.at(_index);
    }

    function tokensContains(address token_) external view returns (bool) {
        return _tokens.contains(token_);
    }

    function tokensList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 tokensLength = _tokens.length();
        if (offset >= tokensLength) return output;
        uint256 to = offset + limit;
        if (tokensLength < to) to = tokensLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _tokens.at(offset + i);
    }

    function weightsList(address[] memory tokens_) external view returns (uint256[] memory output) {
        uint256 tokensLength = tokens_.length;
        output = new uint256[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) output[i] = weights[tokens_[i]];
    }

    /* Events */
    event Updated(ETFTokenConfiguration[] configurations);
    event Joined(address indexed caller, uint256 amountIn, uint256 mintAmount);
    event Exited(address indexed caller, uint256 amountIn, uint256 amountOut);
    event MultiExited(address indexed caller, uint256 amountIn, uint256[] amountsOut);

    constructor(
        ConstructorERC20 memory erc20Config,
        ConstructorAddresses memory addresses,
        ConstructorQuantitative memory quantitative,
        ETFTokenConfiguration[] memory configurations
    ) ERC20(erc20Config.name, erc20Config.symbol) {
        // TODO: internal/external setters with validations and events
        native = addresses.native;
        router = addresses.router;
        factory = IPancakeRouter02(router).factory(); 
        ownerSource = addresses.ownerSource;
        treasury = addresses.treasury;
        joinFee = quantitative.joinFee;
        exitFee = quantitative.exitFee;
        swapFee = quantitative.swapFee;
        maxDeviationPercent = quantitative.maxDeviationPercent;
        uint256 weightSum = 0;
        for (uint256 i = 0; i < configurations.length; i++) {
            ETFTokenConfiguration memory tokenConfiguration = configurations[i];
            _tokens.add(tokenConfiguration.token);
            require(tokenConfiguration.weight != 0, "ETF: Token weight should be neq zero");
            weights[tokenConfiguration.token] = tokenConfiguration.weight;
            swapPathsTokenToNative[tokenConfiguration.token] = _preparePath(
                tokenConfiguration.token,
                native,
                tokenConfiguration.intermediaries
            );
            swapPathsNativeToToken[tokenConfiguration.token] = _preparePath(
                native,
                tokenConfiguration.token,
                tokenConfiguration.intermediaries
            );
            weightSum += tokenConfiguration.weight;
        }
        require(_tokens.contains(native), "ETF: Tokens not contains native");
        require(weightSum == DIVIDER, "ETF: Tokens weight sum neq DIVIDER");
    }

    function update(ETFTokenConfiguration[] memory configurations) public onlyOwner returns (bool) {
        uint256 weightSum = 0;
        uint256 configurationsLength = configurations.length;
        for (uint256 i = 0; i < _tokens.length(); i++) {
            address currentToken = _tokens.at(i);
            uint256 currentBalance = IERC20(currentToken).balanceOf(address(this));
            bool isTokenInNewSet;
            for (uint256 j = 0; j < configurationsLength; i++) {
                if (currentToken == configurations[j].token) {
                    isTokenInNewSet = true;
                    break;
                }
            }
            if (!isTokenInNewSet) {
                IERC20(currentToken).approve(router, currentBalance);
                _swapTokenToNative(currentToken, currentBalance, address(this));
                _tokens.remove(currentToken);
            }
        }
        for (uint256 i = 0; i < configurationsLength; i++) {
            ETFTokenConfiguration memory tokenConfiguration = configurations[i];
            _tokens.add(tokenConfiguration.token);
            require(tokenConfiguration.weight != 0, "ETF: Token weight should be neq zero");
            weights[tokenConfiguration.token] = tokenConfiguration.weight;
            swapPathsTokenToNative[tokenConfiguration.token] = _preparePath(
                tokenConfiguration.token,
                native,
                tokenConfiguration.intermediaries
            );
            swapPathsNativeToToken[tokenConfiguration.token] = _preparePath(
                native,
                tokenConfiguration.token,
                tokenConfiguration.intermediaries
            );
            weightSum += tokenConfiguration.weight;
        }
        require(_tokens.contains(native), "ETF: Tokens not contains native");
        require(weightSum == DIVIDER, "ETF: New tokens weight sum neq DIVIDER");
        require(_tokens.length() == configurationsLength, "ETF: Configurations is incorrect");
        rebalance();
        emit Updated(configurations);
        return true;
    }

    function join(
        uint256 amountIn
    ) public whenNotPaused nonReentrant returns (uint256 mintAmount) {
        uint256 syntheticSupply = totalSupply();
        if (syntheticSupply == 0) require(msg.sender == Ownable(ownerSource).owner(), "ETF: Price initialization can be called only by owner");
        uint256 oldCalculationInNative = _calculationNativeForAllTokens();
        IERC20(native).safeTransferFrom(msg.sender, address(this), amountIn);
        if (_needForRebalance()) rebalance();
        uint256 newCalculationInNative = _calculationNativeForAllTokens();
        mintAmount = syntheticSupply > 0
            ? (newCalculationInNative - oldCalculationInNative) * syntheticSupply / oldCalculationInNative
            : PRECISION;
        uint256 joinFeeAmount = mintAmount * joinFee / DIVIDER;
        mintAmount -= joinFeeAmount;
        _mint(treasury, joinFeeAmount);
        _mint(msg.sender, mintAmount);
        emit Joined(msg.sender, amountIn, mintAmount);
    }

    function exit(uint256 amountIn) public nonReentrant returns (uint256 amountOut) {
        if (_needForRebalance()) rebalance();
        uint256 syntheticSupply = totalSupply();
        uint256 exitFeeAmount = amountIn * exitFee / DIVIDER;
        _burn(msg.sender, amountIn);
        _mint(treasury, exitFeeAmount);
        amountIn -= exitFeeAmount;
        for (uint256 i = 0; i < _tokens.length(); i++) {
            address token_ = _tokens.at(i);
            uint256 tokenAmountOut = amountIn * IERC20(token_).balanceOf(address(this)) / syntheticSupply;
            if (token_ == native) amountOut += tokenAmountOut;
            else {
                IERC20(token_).approve(router, tokenAmountOut);
                uint256 nativeAmountOut = _swapTokenToNative(token_, tokenAmountOut, address(this));
                amountOut += nativeAmountOut;
            }
        }
        IERC20(native).safeTransfer(msg.sender, amountOut);
        emit Exited(msg.sender, amountIn, amountOut);
    }

    function exitMulti(uint256 amountIn) public nonReentrant returns (uint256[] memory amountsOut) {
        uint256 len = _tokens.length();
        amountsOut = new uint256[](len);
        if (_needForRebalance()) rebalance();
        uint256 syntheticSupply = totalSupply();
        uint256 exitFeeAmount = amountIn * exitFee / DIVIDER;
        _burn(msg.sender, amountIn);
        _mint(treasury, exitFeeAmount);
        amountIn -= exitFeeAmount;
        for (uint256 i = 0; i < len; i++) {
            address token_ = _tokens.at(i);
            uint256 tokenAmountOut = amountIn * IERC20(token_).balanceOf(address(this)) / syntheticSupply;
            amountsOut[i] = tokenAmountOut;
            IERC20(token_).safeTransfer(msg.sender, tokenAmountOut);
        }
        emit MultiExited(msg.sender, amountIn, amountsOut);
    }

    function rebalance() public returns (bool) {
        uint256 len = _tokens.length();
        bool[] memory checked = new bool[](len);
        uint256 currentTotalBalanceInNative = _calculationNativeForAllTokens();
        for (uint256 i = 0; i < len; i++) {
            address token_ = _tokens.at(i);
            IERC20 token = IERC20(token_);
            if (token_ == native) continue;
            uint256 tokenWeight = weights[token_];
            uint256 virtualNativeToBuyToken = (currentTotalBalanceInNative * tokenWeight) / DIVIDER;
            uint256 targetBalanceTokenInPool = _getAmountOutNativeToToken(token_, virtualNativeToBuyToken);
            if (targetBalanceTokenInPool < token.balanceOf(address(this))) {
                checked[i] = true;
                uint256 amountTokenForSell = token.balanceOf(address(this)) - targetBalanceTokenInPool;
                uint256 numberOfSwaps = swapPathsTokenToNative[token_].length - 1;
                uint256 coeffCorrectionToSell = _calculationSwapFeeCorrectionToSell(numberOfSwaps);
                amountTokenForSell = amountTokenForSell * DIVIDER ** numberOfSwaps / coeffCorrectionToSell;
                token.approve(router, amountTokenForSell);
                _swapTokenToNative(token_, amountTokenForSell, address(this));
            }
        }
        for (uint256 i = 0; i < len; i++) {
            address token_ = _tokens.at(i);
            IERC20 token = IERC20(token_);
            IERC20 _native = IERC20(native);
            if (token_ == native) continue;
            if (checked[i]) continue;
            uint256 tokenWeight = weights[token_];
            uint256 virtualNativeToBuyToken = (currentTotalBalanceInNative * tokenWeight) / DIVIDER;
            uint256 targetBalanceTokenInPool = _getAmountOutNativeToToken(token_, virtualNativeToBuyToken);
            if (targetBalanceTokenInPool > token.balanceOf(address(this))) {
                uint256 amountTokenToBuy = targetBalanceTokenInPool - token.balanceOf(address(this));
                uint256 numberOfSwaps = swapPathsTokenToNative[token_].length - 1;
                uint256 coeffCorrectionToBuy = _calculationSwapFeeCorrectionToBuy(numberOfSwaps);
                amountTokenToBuy = amountTokenToBuy * DIVIDER ** numberOfSwaps / coeffCorrectionToBuy;
                uint256 amountNativeToSell = _getAmountInNative(token_, amountTokenToBuy);
                _native.approve(router, amountNativeToSell);
                _swapNativeToToken(token_, amountNativeToSell, address(this));
            }
        }
        return true;
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "ETF: Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "ETF: Insufficient liquidity");
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }

    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "ETF: Insufficient output amount");
        require(reserveIn > 0 && reserveOut > 0, "ETF: Insufficient liquidity");
        require(amountOut < reserveOut, "ETF: Too big output amount");
        uint256 numerator = amountOut * reserveIn;
        uint256 denominator = reserveOut - amountOut;
        amountIn = (numerator / denominator) + 1;
    }

    function _calculationSwapFeeCorrectionToSell(uint256 _numberOfSwaps) private view returns (uint256) {
        return DIVIDER ** _numberOfSwaps / 2  + (DIVIDER - swapFee) ** _numberOfSwaps / 2;
    }

    function _calculationSwapFeeCorrectionToBuy(uint256 _numberOfSwaps) private view returns (uint256) {                                                               
        return _calculationSwapFeeCorrectionToSell(_numberOfSwaps)
            * DIVIDER ** _numberOfSwaps / ((DIVIDER - swapFee) ** _numberOfSwaps);
    }

    function _getAmountOutTokenToNative(
        address _tokenIn,
        uint256 _amountIn
    ) private view returns (uint256 amountNativeOut) {
        if (_amountIn == 0) return 0;
        address[] memory path = swapPathsTokenToNative[_tokenIn];
        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = _amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = PancakeLibrary.getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = PancakeLibrary.getAmountOut(amounts[i], reserveIn, reserveOut);
        }
        amountNativeOut = amounts[amounts.length - 1];
    }

    function _getAmountOutNativeToToken(
        address _tokenOut,
        uint256 _amountIn
    ) private view returns (uint256 amountTokenOut) {
        if (_amountIn == 0) return 0;
        address[] memory path = swapPathsNativeToToken[_tokenOut];
        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = _amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = PancakeLibrary.getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
        }
        amountTokenOut = amounts[amounts.length - 1];
    }

    function _getAmountInNative(
        address _tokenOut,
        uint256 _amountOut
    ) private view returns (uint256 amountNativeIn) {
        if (_amountOut == 0) return 0;
        address[] memory path = swapPathsNativeToToken[_tokenOut];
        uint256[] memory amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = _amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = PancakeLibrary.getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = _getAmountIn(amounts[i], reserveIn, reserveOut);
        }
        amountNativeIn = amounts[0];
    }

    function _calculationNativeForToken(address _token) private view returns (uint256 amount) {
        IERC20 token = IERC20(_token);
        if (_token == native) amount = token.balanceOf(address(this));
        else {
            uint256 currentBalanceTokenInPool = token.balanceOf(address(this));
            amount = _getAmountOutTokenToNative(_token, currentBalanceTokenInPool);
        }
    }

    function _calculationNativeForAllTokens() private view returns (uint256 amount) {
        uint256 len = _tokens.length();
        for (uint256 i = 0; i < len; i++) amount += _calculationNativeForToken(_tokens.at(i));
    }

    function _needForRebalance() private view returns (bool checked) {
        uint256 len = _tokens.length();
        uint256 currentTotalBalanceInNative = _calculationNativeForAllTokens();
        uint256 targetBalanceTokenInPool = 0;
        uint256 difference = 0;
        for (uint256 i = 0; i < len; i++) {
            address token_ = _tokens.at(i);
            uint256 tokenWeight = weights[token_];
            uint256 virtualNativeToBuyToken = (currentTotalBalanceInNative * tokenWeight) / DIVIDER;
            uint256 _tokenBalance = IERC20(token_).balanceOf(address(this));
            if (_tokenBalance == 0) return true;
            if (token_ == native) {
                targetBalanceTokenInPool = virtualNativeToBuyToken;
                difference = targetBalanceTokenInPool < _tokenBalance
                    ? _tokenBalance - targetBalanceTokenInPool 
                    : targetBalanceTokenInPool - _tokenBalance;
                if (difference * DIVIDER / _tokenBalance > maxDeviationPercent) return true;
            } else {
                targetBalanceTokenInPool = _getAmountOutNativeToToken(token_, virtualNativeToBuyToken);
                difference = targetBalanceTokenInPool < _tokenBalance
                    ? _tokenBalance - targetBalanceTokenInPool 
                    : targetBalanceTokenInPool - _tokenBalance;
                if (difference * DIVIDER / _tokenBalance > maxDeviationPercent) return true;
            }
        }
    }

    function _preparePath(
        address _tokenIn,
        address _tokenOut,
        address[] memory _intermediaries
    ) private view returns (address[] memory path) {
        require(_tokenIn == native || _tokenOut == native, "ETF: Native is missing");
        bool reverse = _tokenIn == native;
        uint256 intermediariesLength = _intermediaries.length;
        path = new address[](2 + intermediariesLength);
        path[0] = _tokenIn;
        if (intermediariesLength != 0) {
            for (uint256 i = 0; i < intermediariesLength; i++) {
                path[reverse ? intermediariesLength - i : i + 1] = _intermediaries[i];
            }
        }
        path[path.length - 1] = _tokenOut;
    }

    function _swapNativeToToken(
        address _tokenTo,
        uint256 _nativeAmount,
        address _to
    ) private returns (uint256 tokenAmountOut) {
        if (native == _tokenTo || _nativeAmount == 0) return _nativeAmount;
        uint256[] memory amounts = IPancakeRouter02(router).swapExactTokensForTokens(
            _nativeAmount,
            1,
            swapPathsNativeToToken[_tokenTo],
            _to,
            block.timestamp
        );
        tokenAmountOut = amounts[amounts.length - 1];
    }

    function _swapTokenToNative(
        address _tokenFrom,
        uint256 _tokenAmount,
        address _to
    ) private returns (uint256 nativeAmountOut) {
        if (native == _tokenFrom || _tokenAmount == 0) return _tokenAmount;
        uint256[] memory amounts = IPancakeRouter02(router).swapExactTokensForTokens(
            _tokenAmount,
            1,
            swapPathsTokenToNative[_tokenFrom],
            _to,
            block.timestamp
        );
        nativeAmountOut = amounts[amounts.length - 1];
    }

    /* Modifiers */
    modifier onlyOwner() {
        require(msg.sender == Ownable(ownerSource).owner(), "ETF: Caller is not owner");
        _;
    }
}