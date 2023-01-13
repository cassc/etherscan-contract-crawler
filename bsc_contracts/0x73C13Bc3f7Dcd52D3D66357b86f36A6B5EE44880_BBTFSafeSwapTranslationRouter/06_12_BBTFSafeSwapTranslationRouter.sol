// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IBBTFTranslationRouter.sol";
import "./interfaces/ISafeSwapRouter02.sol";
import "./interfaces/ISafeSwapTradeRouter.sol";
import "./interfaces/ISafeswapFactory.sol";
import "./interfaces/ISafeswapPair.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";

contract BBTFSafeSwapTranslationRouter is IBBTFTranslationRouter, Initializable, OwnableUpgradeable {

    ISafeswapRouter02 public safeswapRouter;
    ISafeSwapTradeRouter public safeswapTradeRouter;

    mapping(address => bool) public allowedAddresses;

    bool public currencyRefundsEnabled;

    modifier confirmApproved(){
        _confirmApproved();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _tradeRouterAddress, address _swapRouterAddress) initializer public virtual {
        __BBTFSafeSwapTranslationRouter_init(_tradeRouterAddress, _swapRouterAddress);
    }

    function __BBTFSafeSwapTranslationRouter_init(address _tradeRouterAddress, address _swapRouterAddress) internal onlyInitializing {
        __Ownable_init();
        __BBTFSafeSwapTranslationRouter_init_unchained(_tradeRouterAddress, _swapRouterAddress);
    }

    function __BBTFSafeSwapTranslationRouter_init_unchained(address _tradeRouterAddress, address _swapRouterAddress) internal onlyInitializing {
        safeswapTradeRouter = ISafeSwapTradeRouter(_tradeRouterAddress);
        safeswapRouter = ISafeswapRouter02(_swapRouterAddress);
    }

    receive() external payable {}

    function _toStruct(uint256 _amountIn, uint256 _amountOut, address[] memory _path, address _to, uint256 _deadline) internal pure returns(ISafeSwapTradeRouter.Trade memory trade){
        trade = ISafeSwapTradeRouter.Trade({
            amountIn: _amountIn,
            amountOut: _amountOut,
            path: _path,
            to: payable(_to),
            deadline: _deadline
        });
    }

    function updateSwapApprovedAddress(address _traderAddress, bool _shouldApprove) external onlyOwner {
        allowedAddresses[_traderAddress] = _shouldApprove;
    }

    function updateTradeRouter(address _tradeRouterAddress) external onlyOwner {
        safeswapTradeRouter = ISafeSwapTradeRouter(_tradeRouterAddress);
    }

    function updateSwapRouter(address _swapRouterAddress) external onlyOwner {
        safeswapRouter = ISafeswapRouter02(_swapRouterAddress);
    }

    function updateCurrencyRefundStatus(bool _doCurrencyRefunds) external onlyOwner {
        currencyRefundsEnabled = _doCurrencyRefunds;
    }

    function _confirmApproved() private view {
        if(!allowedAddresses[msg.sender]){
            revert("Not approved for LP actions");
        }
    }

    function _doApprovalAndPrepare(address _tokenAddress, uint256 _amount) internal {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        IERC20(_tokenAddress).approve(address(safeswapRouter), _amount);
    }

    function _getQuote(uint256 _amountIn, address[] memory _path) internal view returns(uint256){
        return safeswapTradeRouter.getSwapFees(_amountIn, _path);
    }

    function _performRefund(address _token) internal {
        if(_token != address(0)){
            uint256 balance = IERC20(_token).balanceOf(address(this));
            if(balance > 0){
                IERC20(_token).transfer(msg.sender, balance);
            }
        }
        if(currencyRefundsEnabled){
            if(address(this).balance > 0){
                payable(msg.sender).transfer(address(this).balance);
            }
        }
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override confirmApproved returns (uint amountETH){
        address pair = pairFor(factory(), token, WETH());
        _doApprovalAndPrepare(pair, liquidity);
        amountETH = safeswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
        _performRefund(pair);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override confirmApproved returns (uint amountETH){
        address pair = pairFor(factory(), token, WETH());
        _doApprovalAndPrepare(pair, liquidity);
        amountETH = safeswapRouter.removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(token, liquidity, amountTokenMin, amountETHMin, to, deadline, approveMax, v, r, s);
        _performRefund(pair);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override confirmApproved payable{
        _doApprovalAndPrepare(path[0], amountIn);
        uint256 quotedFee = _getQuote(amountIn, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(amountIn, amountOutMin, path, to, deadline);
        safeswapTradeRouter.swapExactTokensForTokensWithFeeAmount{value: quotedFee}(trade);
        _performRefund(path[0]);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override confirmApproved payable{
        uint256 quotedFee = _getQuote(msg.value, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(msg.value - quotedFee, amountOutMin, path, to, deadline);
        safeswapTradeRouter.swapExactETHForTokensWithFeeAmount{value: msg.value}(trade, quotedFee);
        _performRefund(address(0));
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override confirmApproved payable{
        _doApprovalAndPrepare(path[0], amountIn);
        uint256 quotedFee = _getQuote(amountIn, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(amountIn, amountOutMin, path, to, deadline);
        safeswapTradeRouter.swapExactTokensForETHAndFeeAmount{value: quotedFee}(trade);
        _performRefund(path[0]);
    }

    function factory() public view returns (address){
        return safeswapRouter.factory();
    }

    function WETH() public view returns (address){
        return safeswapRouter.WETH();
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override confirmApproved returns (uint amountA, uint amountB, uint liquidity){
        _doApprovalAndPrepare(tokenA, amountADesired);
        _doApprovalAndPrepare(tokenB, amountBDesired);
        (amountA, amountB, liquidity) = safeswapRouter.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        _performRefund(tokenA);
        _performRefund(tokenB);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override confirmApproved payable returns (uint amountToken, uint amountETH, uint liquidity){
        _doApprovalAndPrepare(token, amountTokenDesired);
        (amountToken, amountETH, liquidity) = safeswapRouter.addLiquidityETH{value: msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
        _performRefund(token);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override confirmApproved returns (uint amountA, uint amountB){
        address pair = pairFor(factory(), tokenA, tokenB);
        _doApprovalAndPrepare(pair, liquidity);
        (amountA, amountB) = safeswapRouter.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
        _performRefund(pair);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override confirmApproved returns (uint amountToken, uint amountETH){
        address pair = pairFor(factory(), token, WETH());
        _doApprovalAndPrepare(pair, liquidity);
        (amountToken, amountETH) = safeswapRouter.removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
        _performRefund(pair);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override confirmApproved returns (uint amountA, uint amountB){
        address pair = pairFor(factory(), tokenA, tokenB);
        _doApprovalAndPrepare(pair, liquidity);
        (amountA, amountB) = safeswapRouter.removeLiquidityWithPermit(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline, approveMax, v, r, s);
        _performRefund(pair);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override confirmApproved returns (uint amountToken, uint amountETH){
        address pair = pairFor(factory(), token, WETH());
        _doApprovalAndPrepare(pair, liquidity);
        (amountToken, amountETH) = safeswapRouter.removeLiquidityETHWithPermit(token, liquidity, amountTokenMin, amountETHMin, to, deadline, approveMax, v, r, s);
        _performRefund(pair);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override confirmApproved payable returns (uint[] memory amounts){
        _doApprovalAndPrepare(path[0], amountIn);
        uint256 quotedFee = _getQuote(amountIn, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(amountIn, amountOutMin, path, to, deadline);
        safeswapTradeRouter.swapExactTokensForTokensWithFeeAmount{value: quotedFee}(trade);
        _performRefund(path[0]);
        amounts = new uint[](2);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override confirmApproved payable returns (uint[] memory amounts){
        _doApprovalAndPrepare(path[0], amountInMax);
        uint256 quotedFee = _getQuote(amountInMax, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(amountInMax, amountOut, path, to, deadline);
        safeswapTradeRouter.swapTokensForExactTokensWithFeeAmount{value: quotedFee}(trade);
        _performRefund(path[0]);
        amounts = new uint[](2);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external override
    payable confirmApproved
    returns (uint[] memory amounts){
        uint256 quotedFee = _getQuote(msg.value, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(msg.value - quotedFee, amountOutMin, path, to, deadline);
        safeswapTradeRouter.swapExactETHForTokensWithFeeAmount{value: msg.value}(trade, quotedFee);
        _performRefund(address(0));
        amounts = new uint[](2);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external override confirmApproved payable
    returns (uint[] memory amounts){
        _doApprovalAndPrepare(path[0], amountInMax);
        uint256 quotedFee = _getQuote(amountInMax, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(amountInMax, amountOut, path, to, deadline);
        safeswapTradeRouter.swapTokensForExactETHAndFeeAmount{value: quotedFee}(trade);
        _performRefund(path[0]);
        amounts = new uint[](2);
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external override confirmApproved payable
    returns (uint[] memory amounts){
        _doApprovalAndPrepare(path[0], amountIn);
        uint256 quotedFee = _getQuote(amountIn, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(amountIn, amountOutMin, path, to, deadline);
        safeswapTradeRouter.swapExactTokensForETHAndFeeAmount{value: quotedFee}(trade);
        _performRefund(path[0]);
        amounts = new uint[](2);
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external override
    payable confirmApproved
    returns (uint[] memory amounts){
        uint256 quotedFee = _getQuote(msg.value, path);
        ISafeSwapTradeRouter.Trade memory trade = _toStruct(msg.value - quotedFee, amountOut, path, to, deadline);
        safeswapTradeRouter.swapETHForExactTokensWithFeeAmount{value: msg.value}(trade, quotedFee);
        _performRefund(address(0));
        amounts = new uint[](2);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) public override pure returns (uint amountB){
        require(amountA > 0, "SafeswapLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SafeswapLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    function pairFor(address _factory, address _tokenA, address _tokenB) public view returns(address _pair){
        _pair = ISafeswapFactory(_factory).getPair(_tokenA, _tokenB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public override pure returns (uint amountOut){
        require(amountIn > 0, "SafeswapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SafeswapLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 998;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public override pure returns (uint amountIn){
        require(amountOut > 0, "SafeswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SafeswapLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 998;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountsOut(uint amountIn, address[] calldata path) public override view returns (uint[] memory amounts){
        require(path.length >= 2, "SafeswapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory(), path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(uint amountOut, address[] calldata path) public override view returns (uint[] memory amounts){
        require(path.length >= 2, "SafeswapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory(), path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        address pair = pairFor(safeswapRouter.factory(), tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = ISafeswapPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SafeswapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SafeswapLibrary: ZERO_ADDRESS");
    }

    function removeStuckToken(address _token, address _to) external onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    function removeStuckCurrency(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function removeStuckToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    function removeStuckCurrency(address _to, uint256 _amount) external onlyOwner {
        payable(_to).transfer(_amount);
    }
}