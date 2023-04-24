// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title UniswapZap
 * @dev This contract facilitates token swaps on Uniswap V2 by providing a simple interface
 * for swapping between any two tokens, including ETH, while handling the required fee.
 */
contract UniswapZapV2 is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    IUniswapV2Router02 public uniswapRouter;

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // The WETH (Wrapped Ether) token address
    address private WETH;

    /// @dev The fee amount in ETH
    uint256 public minFee;

    /// @dev The address of the recipient who receives the fee
    address public feeCollector;

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    virtual
    override
    onlyOwner
    {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize(
        address _owner,
        address _uniswapRouter,
        uint256 _minFee,
        address _feeCollector
    ) public initializer {
        require(_owner != address(0), "Owner address is not set");
        require(_feeCollector != address(0), "Bank address is not be zero");

        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        WETH = uniswapRouter.WETH();
        minFee = _minFee;
        feeCollector = _feeCollector;
    }

    /**
     * @notice Returns the amount of tokens that can be obtained by swapping the given input amount
     * @param amountIn The amount of input tokens
     * @param path An array of token addresses representing the exchange path
     * @return amounts An array of token amounts representing the output amounts
     */
    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        returns (uint[] memory amounts)
    {
        return uniswapRouter.getAmountsOut(amountIn, path);
    }

    /**
     * @notice Returns the amount of tokens required to obtain the given output amount
     * @param amountOut The amount of output tokens
     * @param path An array of token addresses representing the exchange path
     * @return amounts An array of token amounts representing the input amounts
     */
    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        returns (uint[] memory amounts)
    {
        return uniswapRouter.getAmountsIn(amountOut, path);
    }

    /**
     * @notice Swaps tokens using Uniswap
     * @param amountIn The amount of input tokens
     * @param amountOutMin The minimum amount of output tokens
     * @param path An array of token addresses representing the exchange path
     * @param to The address to receive the output tokens
     * @param deadline Unix timestamp after which the transaction will be reverted
     * @param slippage Slippage in basis points (1% = 10,000; 0.1% = 1,000; 0.01% = 100)
     */
    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 slippage,
        uint256 fee
    ) external payable nonReentrant {
        require(path.length >= 2, "Path should contain at least two addresses");
        require(fee >= minFee, "Fee is not included in msg.value");
        require(msg.value >= fee, "Fee is not included in msg.value");

        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        uint256 adjustedAmountOutMin = _getAmountWithSlippage(amountOutMin, slippage);

        payable(feeCollector).transfer(fee);

        if (tokenIn == WETH) {
            uint256 amountInAfterFee = amountIn - fee;

            uniswapRouter.swapExactETHForTokens{value: amountInAfterFee}(
                adjustedAmountOutMin,
                path,
                to,
                deadline
            );

        } else {
            require(IERC20Upgradeable(tokenIn).balanceOf(msg.sender) >= amountIn, "BALANCE");
            require(IERC20Upgradeable(tokenIn).allowance(msg.sender, address(this)) >= amountIn, "!ALLOWANCE");
            IERC20Upgradeable(tokenIn).transferFrom(msg.sender, address(this), amountIn);
            _approveTokenIfNeeded(tokenIn, address(uniswapRouter));

            if (tokenOut == WETH) {
                uniswapRouter.swapExactTokensForETH(
                    amountIn,
                    adjustedAmountOutMin,
                    path,
                    to,
                    deadline
                );
            } else {
                uniswapRouter.swapExactTokensForTokens(
                    amountIn,
                    adjustedAmountOutMin,
                    path,
                    to,
                    deadline
                );
            }
        }

    }


    function _getAmountWithSlippage(uint256 amount, uint256 slippage) internal pure returns (uint256) {
        return amount.mul(10**6 - slippage).div(10**6);
    }

    function _checkAllowance(address token, address sender, uint256 amount) internal view returns (bool) {
        return IERC20Upgradeable(token).allowance(sender, address(this)) >= amount;
    }

    function _approveTokenIfNeeded(address token, address spender) internal {
        if (IERC20Upgradeable(token).allowance(address(this), spender) == 0) {
            IERC20Upgradeable(token).safeApprove(spender, ~uint256(0));
        }
    }

    // setters
    function changeMinFee(uint256 _minFee) public onlyOwner {
        minFee = _minFee;
    }

    function changeBankAddress(address _feeCollector) public onlyOwner {
        require(_feeCollector != address(0), "Bank address is not be zero");
        feeCollector = _feeCollector;
    }

}