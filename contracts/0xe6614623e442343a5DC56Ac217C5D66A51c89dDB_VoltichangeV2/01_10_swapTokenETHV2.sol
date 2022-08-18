// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract VoltichangeV2 is OwnableUpgradeable {
    IUniswapV2Factory factory;
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public fee/* = 500*/;
    // address public pairAddress;
    address public WETH;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _fee) public initializer {
        fee = _fee;
        WETH =  IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
    }

    // TODO to calculate the price of exchange we have to use a secure method: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/trading-from-a-smart-contract

    function swapTokenForToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        require(IERC20Upgradeable(_tokenIn).transferFrom(msg.sender, address(this), _amountIn), "transferFrom failed.");
        require(IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn), "approve failed.");

        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        address[] memory path;
        if (IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut) != address(0)) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
            path[2] = _tokenOut;
        }
        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokens(
                _amountInSub,
                _amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );

        // uint256 feeAmountHalf = feeAmount / 2;

        // if (!(_tokenIn == WETH)) {
        //     IERC20Upgradeable(_tokenIn).transferFrom(
        //         address(this),
        //         deadAddress,
        //         feeAmountHalf
        //     );

        //     IERC20Upgradeable(VOLT).approve(address(this), feeAmountHalf);
        //     IERC20Upgradeable(VOLT).transferFrom(
        //         address(this),
        //         deadAddress,
        //         feeAmountHalf
        //     );
        // }
    }

    function swapETHforToken(
        address _tokenOut,
        uint256 _amountOutMin
    ) external payable {
        require(msg.value > 0, "Please send ETH.");
        uint256 feeAmount = (msg.value * fee) / 10000;
        uint256 _amountInSub = msg.value - feeAmount;

        address[] memory path;
        path = new address[](2);
        path[0] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
        path[1] = _tokenOut;

        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactETHForTokens{value: _amountInSub}(
                _amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );

        // uint256 feeAmountHalf = feeAmount / 2;

        // if (!(_tokenIn == WETH)) {
        //     IERC20Upgradeable(_tokenIn).transferFrom(
        //         address(this),
        //         deadAddress,
        //         feeAmountHalf
        //     );

        //     IERC20Upgradeable(VOLT).approve(address(this), feeAmountHalf);
        //     IERC20Upgradeable(VOLT).transferFrom(
        //         address(this),
        //         deadAddress,
        //         feeAmountHalf
        //     );
        // }
    }

    function swapTokenForETH(address _tokenIn, uint256 _amountIn, uint256 _amountOutMin) external {
        require(IERC20Upgradeable(_tokenIn).transferFrom(msg.sender, address(this), _amountIn), "transferFrom failed.");
        require(IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn), "approve failed."); 

        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();

        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactTokensForETH(
                _amountInSub,
                _amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );
    }

    function getPair(address _tokenIn, address _tokenOut)
        external
        view 
        returns (address)
    {
        return IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut);
    }

    function getAmountOutMin(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256) {

        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        address[] memory path;
        if (IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut) != address(0)) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountInSub, path);
        return amountOutMins[path.length - 1];
    }

    receive() payable external {}

    /* this function can be used to:
     * - withdraw
     * - send refund to users in case something goes 
     */
    function sendEthToAddr(uint256 _amount, address payable _to) external payable onlyOwner
    {
        require(
            _amount <= address(this).balance,
            "amount must be <= than balance."
        );
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function sendTokenToAddr(uint256 _amount, address _tokenAddress, address _to) external onlyOwner {
        require(IERC20Upgradeable(_tokenAddress).transferFrom(address(this), _to, _amount), "transferFrom failed.");
    }
}