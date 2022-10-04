// SPDX-License-Identifier: MIT

/** 
      /$$$$$$   /$$$$$$  /$$      /$$  /$$$$$$ 
     /$$__  $$ /$$__  $$| $$$    /$$$ /$$__  $$
    | $$  \__/| $$  \ $$| $$$$  /$$$$| $$  \ $$
    | $$ /$$$$| $$  | $$| $$ $$/$$ $$| $$$$$$$$
    | $$|_  $$| $$  | $$| $$  $$$| $$| $$__  $$
    | $$  \ $$| $$  | $$| $$\  $ | $$| $$  | $$
    |  $$$$$$/|  $$$$$$/| $$ \/  | $$| $$  | $$
     \______/  \______/ |__/     |__/|__/  |__/
    
*/

/**
 * @title GomaSale contract
 * @notice GomaSale contract for Sale and liquidity addition.
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IPancakeswapRouterV2.sol";

contract GSwapLiquid is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public fee;
    /* Fee denomiator that can be used to calculate %. 100% = 10000 */
    uint16 public constant FEE_DENOMINATOR = 10000;

    IPancakeswapRouterV2 public pancakeswapRouterV2;

    address public tokenIn;
    address public tokenOut;

    event Buy(address user, uint256 amountIn, uint256 commission, uint256 amountOut);
    event LiquidityAdded(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 liquity);

    function initialize(
        address _router,
        address _tokenIn,
        address _tokenOut
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        pancakeswapRouterV2 = IPancakeswapRouterV2(_router);
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        fee = 800;
    }

    function updateParam(
        address _router,
        address _tokenIn,
        address _tokenOut
    ) external whenNotPaused onlyOwner {
        pancakeswapRouterV2 = IPancakeswapRouterV2(_router);
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function withdrawToken(
        address admin,
        address _paymentToken,
        uint256 _amount
    ) external whenNotPaused onlyOwner {
        IERC20Upgradeable token = IERC20Upgradeable(_paymentToken);
        uint256 amount = token.balanceOf(address(this));
        require(_amount >= amount, "insufficent balance");
        token.transfer(admin, _amount);
    }

    function buyGoma(uint256 amount) private whenNotPaused nonReentrant {
        require(amount > 0, "incorrect amount");
        IERC20Upgradeable(tokenIn).transferFrom(_msgSender(), address(this), amount);
        uint256 commission = getCommission(amount);
        uint256 gomaTokenBalance = IERC20Upgradeable(tokenOut).balanceOf(address(this));
        uint256 gomaTokenOut = getExchangeAmount(amount);
        require((gomaTokenOut * 2) <= gomaTokenBalance, "insufficent liquidity");
        addLiquidityToPool(amount, gomaTokenOut);
        IERC20Upgradeable(tokenOut).transfer(_msgSender(), gomaTokenOut);
        emit Buy(_msgSender(), amount, commission, gomaTokenOut);
    }

    function buy(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "incorrect amount");
        IERC20Upgradeable(tokenIn).transferFrom(_msgSender(), address(this), amount);
        uint256 commission = getCommission(amount);
        amount = amount - commission;
        uint256 gomaTokenOut = ((getCurrentGomaPrice() * 10**9) * amount) / 10**18;
        uint256 gomaTokenSwap = getExchangeAmount(amount);
        addLiquidityToPool(amount, ((gomaTokenSwap * 2000000000) / 10**9));
        IERC20Upgradeable(tokenOut).transfer(_msgSender(), gomaTokenOut);
        emit Buy(_msgSender(), amount, commission, gomaTokenOut);
    }

    function getCommission(uint256 amount) public view returns (uint256) {
        return (fee * amount) / FEE_DENOMINATOR;
    }

    function addLiquidityToPool(uint256 _amountUSD, uint256 _amountGoma) internal {
        address router = address(pancakeswapRouterV2);
        IERC20Upgradeable(tokenIn).approve(router, _amountUSD);
        IERC20Upgradeable(tokenOut).approve(router, _amountGoma);

        (uint256 amountUSD, uint256 amountGoma, uint256 liquidity) = pancakeswapRouterV2.addLiquidity(
            tokenIn,
            tokenOut,
            _amountUSD,
            _amountGoma,
            1,
            1,
            address(this),
            block.timestamp
        );
        emit LiquidityAdded(tokenIn, tokenOut, amountGoma, amountUSD, liquidity);
    }

    function getExchangeAmount(uint256 amount) public view returns (uint256) {
        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amountOut = pancakeswapRouterV2.getAmountsOut(amount, path);
        return amountOut[path.length - 1];
    }

    function getCurrentGomaPrice() public view returns (uint256) {
        uint256 amount = 1000000000000000000;
        return getExchangeAmount(amount);
    }

    /**
     * @dev Pause sale
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause sale
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}