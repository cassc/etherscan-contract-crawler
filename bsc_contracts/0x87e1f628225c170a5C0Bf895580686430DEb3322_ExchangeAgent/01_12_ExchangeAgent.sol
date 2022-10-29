// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapRouter02.sol";
import "./interfaces/IOraclePriceFeed.sol";
import "./interfaces/IExchangeAgent.sol";
import "./libraries/TransferHelper.sol";

contract ExchangeAgent is IExchangeAgent, ReentrancyGuard, Ownable {
    address public immutable override USDC_TOKEN;
    address public UNISWAP_ROUTER;
    address public WETH;
    address public oraclePriceFeed;
    uint256 public slippage;
    uint256 private constant SLIPPAGE_PRECISION = 100;

    mapping(address => bool) public whiteList;

    event ConvertedTokenToToken(
        address indexed _dexAddress,
        address indexed _convertToken,
        address indexed _convertedToken,
        uint256 _convertAmount,
        uint256 _desiredAmount,
        uint256 _convertedAmount
    );

    event ConvertedTokenToETH(
        address indexed _dexAddress,
        address indexed _convertToken,
        uint256 _convertAmount,
        uint256 _desiredAmount,
        uint256 _convertedAmount
    );

    event LogAddWhiteList(address indexed _exchangeAgent, address indexed _whiteListAddress);
    event LogRemoveWhiteList(address indexed _exchangeAgent, address indexed _whiteListAddress);
    event LogSetSlippage(address indexed _exchangeAgent, uint256 _slippage);
    event LogSetOraclePriceFeed(address indexed _exchangeAgent, address indexed _oraclePriceFeed);
    event LogSetDexRouter(address indexed _router, address _weth);

    constructor(
        address _usdcToken,
        address _WETH,
        address _oraclePriceFeed,
        address _uniswapRouter,
        address _multiSigWallet
    ) {
        require(_usdcToken != address(0), "UnoRe: zero USDC address");
        require(_multiSigWallet != address(0), "UnoRe: zero multisigwallet address");
        USDC_TOKEN = _usdcToken;
        UNISWAP_ROUTER = _uniswapRouter;
        WETH = _WETH;
        oraclePriceFeed = _oraclePriceFeed;
        whiteList[msg.sender] = true;
        slippage = 5 * SLIPPAGE_PRECISION;
        transferOwnership(_multiSigWallet);
    }

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "UnoRe: ExchangeAgent Forbidden");
        _;
    }

    receive() external payable {}

    function addWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(!whiteList[_whiteListAddress], "UnoRe: white list already");
        whiteList[_whiteListAddress] = true;
        emit LogAddWhiteList(address(this), _whiteListAddress);
    }

    function removeWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(whiteList[_whiteListAddress], "UnoRe: white list removed or unadded already");
        whiteList[_whiteListAddress] = false;
        emit LogRemoveWhiteList(address(this), _whiteListAddress);
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage > 0, "UnoRe: zero slippage");
        require(_slippage < 100, "UnoRe: 100% slippage overflow");
        slippage = _slippage * SLIPPAGE_PRECISION;
        emit LogSetSlippage(address(this), _slippage);
    }

    function setDexRouter(address _router, address _weth) external onlyOwner {
        UNISWAP_ROUTER = _router;
        WETH = _weth;
        emit LogSetDexRouter(_router, _weth);
    }

    function setOraclePriceFeed(address _oraclePriceFeed) external onlyOwner {
        require(_oraclePriceFeed != address(0), "UnoRe: zero address");
        oraclePriceFeed = _oraclePriceFeed;
        emit LogSetOraclePriceFeed(address(this), oraclePriceFeed);
    }

    // estimate token amount for amount in USDC
    function getTokenAmountForUSDC(address _token, uint256 _usdtAmount) external view override returns (uint256) {
        return _getNeededTokenAmount(USDC_TOKEN, _token, _usdtAmount);
    }

    // estimate ETH amount for amount in USDC
    function getETHAmountForUSDC(uint256 _usdtAmount) external view override returns (uint256) {
        uint256 ethPrice = IOraclePriceFeed(oraclePriceFeed).getAssetEthPrice(USDC_TOKEN);
        uint256 tokenDecimal = IERC20Metadata(USDC_TOKEN).decimals();
        return (_usdtAmount * ethPrice) / (10**tokenDecimal);
    }

    function getETHAmountForToken(address _token, uint256 _tokenAmount) public view override returns (uint256) {
        uint256 ethPrice = IOraclePriceFeed(oraclePriceFeed).getAssetEthPrice(_token);
        uint256 tokenDecimal = IERC20Metadata(_token).decimals();
        return (_tokenAmount * ethPrice) / (10**tokenDecimal);
    }

    function getTokenAmountForETH(address _token, uint256 _ethAmount) public view override returns (uint256) {
        uint256 ethPrice = IOraclePriceFeed(oraclePriceFeed).getAssetEthPrice(_token);
        uint256 tokenDecimal = IERC20Metadata(_token).decimals();
        return (_ethAmount * (10**tokenDecimal)) / ethPrice;
    }

    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external view override returns (uint256) {
        return _getNeededTokenAmount(_token0, _token1, _token0Amount);
    }

    function convertForToken(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external override onlyWhiteList nonReentrant returns (uint256) {
        uint256 twapPrice = 0;
        if (_token0 != address(0)) {
            require(IERC20(_token0).balanceOf(msg.sender) > 0, "UnoRe: zero balance");
            TransferHelper.safeTransferFrom(_token0, msg.sender, address(this), _token0Amount);
            twapPrice = _getNeededTokenAmount(_token0, _token1, _token0Amount);
        } else {
            twapPrice = getTokenAmountForETH(_token1, _token0Amount);
        }
        require(twapPrice > 0, "UnoRe: no pairs");
        uint256 desiredAmount = (twapPrice * (100 * SLIPPAGE_PRECISION - slippage)) / 100 / SLIPPAGE_PRECISION;

        uint256 convertedAmount = _convertTokenForToken(UNISWAP_ROUTER, _token0, _token1, _token0Amount, desiredAmount);
        return convertedAmount;
    }

    function convertForETH(address _token, uint256 _convertAmount)
        external
        override
        onlyWhiteList
        nonReentrant
        returns (uint256)
    {
        require(IERC20(_token).balanceOf(msg.sender) > 0, "UnoRe: zero balance");
        if (_token != address(0)) {
            TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _convertAmount);
        }
        uint256 twapPriceInUSDC = getETHAmountForToken(_token, _convertAmount);
        require(twapPriceInUSDC > 0, "UnoRe: no pairs");
        uint256 desiredAmount = (twapPriceInUSDC * (100 * SLIPPAGE_PRECISION - slippage)) / 100 / SLIPPAGE_PRECISION;

        uint256 convertedAmount = _convertTokenForETH(UNISWAP_ROUTER, _token, _convertAmount, desiredAmount);
        return convertedAmount;
    }

    function _convertTokenForToken(
        address _dexAddress,
        address _token0,
        address _token1,
        uint256 _convertAmount,
        uint256 _desiredAmount
    ) private returns (uint256) {
        IUniswapRouter02 _dexRouter = IUniswapRouter02(_dexAddress);
        address _factory = _dexRouter.factory();
        uint256 usdtBalanceBeforeSwap = IERC20(_token1).balanceOf(msg.sender);
        address inpToken = _dexRouter.WETH();
        if (_token0 != address(0)) {
            inpToken = _token0;
            TransferHelper.safeApprove(_token0, address(_dexRouter), _convertAmount);
        }
        if (IUniswapFactory(_factory).getPair(inpToken, _token1) != address(0)) {
            address[] memory path = new address[](2);
            path[0] = inpToken;
            path[1] = _token1;
            if (_token0 == address(0)) {
                _dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _convertAmount}(
                    _desiredAmount,
                    path,
                    msg.sender,
                    block.timestamp
                );
            } else {
                _dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _convertAmount,
                    _desiredAmount,
                    path,
                    msg.sender,
                    block.timestamp
                );
            }
        }
        uint256 usdtBalanceAfterSwap = IERC20(_token1).balanceOf(msg.sender);
        emit ConvertedTokenToToken(
            _dexAddress,
            _token0,
            _token1,
            _convertAmount,
            _desiredAmount,
            usdtBalanceAfterSwap - usdtBalanceBeforeSwap
        );
        return usdtBalanceAfterSwap - usdtBalanceBeforeSwap;
    }

    function _convertTokenForETH(
        address _dexAddress,
        address _token,
        uint256 _convertAmount,
        uint256 _desiredAmount
    ) private returns (uint256) {
        IUniswapRouter02 _dexRouter = IUniswapRouter02(_dexAddress);
        address _factory = _dexRouter.factory();
        uint256 ethBalanceBeforeSwap = address(msg.sender).balance;
        TransferHelper.safeApprove(_token, address(_dexRouter), _convertAmount);
        if (IUniswapFactory(_factory).getPair(_token, WETH) != address(0)) {
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = WETH;
            _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _convertAmount,
                _desiredAmount,
                path,
                msg.sender,
                block.timestamp
            );
        }
        uint256 ethBalanceAfterSwap = address(msg.sender).balance;
        emit ConvertedTokenToETH(_dexAddress, _token, _convertAmount, _desiredAmount, ethBalanceAfterSwap - ethBalanceBeforeSwap);
        return ethBalanceAfterSwap - ethBalanceBeforeSwap;
    }

    /**
     * @dev Get expected _token1 amount for _inputAmount of _token0
     * _desiredAmount should consider decimals based on _token1
     */
    function _getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) private view returns (uint256) {
        uint256 expectedToken1Amount = IOraclePriceFeed(oraclePriceFeed).consult(_token0, _token1, _token0Amount);

        return expectedToken1Amount;
    }
}