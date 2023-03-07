// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./components/UniswapV2Components.sol";

contract DeSwapAggregator is Ownable {
    using SafeERC20 for IERC20;

    bool private locked;
    address payable public feeWallet;
    uint256 public fee; //1000 = 1%
    address public weth;

    event WalletSet(address indexed wallet);
    event FeeSet(uint256 fee);
    event FeeTaken(uint256 amount);
    event FeeTokenTaken(address indexed token, uint256 amount);
    event Swap(address indexed, address[] indexed path, uint256 amountOut);

    constructor(
        uint256 _fee,
        address payable _feeWallet,
        address weth_
    ) {
        setFeeWallet(_feeWallet);
        setFee(_fee);
        weth = weth_;
    }

    modifier locker() {
        require(!locked, "The contract is locked currently");
        locked = true;
        _;
        locked = false;
    }

    function setFeeWallet(address payable _feeWallet) public onlyOwner {
        require(_feeWallet != address(0), "ZERO_ADDRESS");
        feeWallet = _feeWallet;
        emit WalletSet(_feeWallet);
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
        emit FeeSet(_fee);
    }

    function takeFee(uint256 amount) external onlyOwner locker {
        uint256 bal = address(this).balance;
        require(bal >= amount, "Insufficient amount");
        (bool isSuccess, ) = feeWallet.call{value: amount}("");
        require(isSuccess, "Transfer failed");
        emit FeeTaken(amount);
    }

    function takeFeeToken(address token, uint256 amount)
        external
        onlyOwner
        locker
    {
        IERC20 outToken = IERC20(token);
        uint256 bal = outToken.balanceOf(address(this));
        require(bal >= amount, "Insufficient amount");
        outToken.safeTransfer(feeWallet, amount);
        emit FeeTokenTaken(token, amount);
    }

    function swapETHForTokens(address router, address token)
        external
        payable
        locker
    {
        require(msg.value > 0 && router != address(0), "WRONG_INPUT");
        IUniswapV2Router r = IUniswapV2Router(router);

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        uint256 rate = fee;
        uint256 amt = rate > 0 ? afterFee(msg.value) : msg.value;

        uint256[] memory amounts = r.swapExactETHForTokens{value: amt}(
            1,
            path,
            msg.sender,
            block.timestamp + 1200
        );

        emit Swap(msg.sender, path, amounts[1]);
    }

    function swapTokensForTokens(
        address router,
        address[] calldata path,
        uint256 amountIn
    ) external locker {
        IERC20 inToken = IERC20(path[0]);

        uint256 rate = fee;
        uint256 amt = rate > 0 ? afterFee(amountIn) : amountIn;

        inToken.safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 allowance = inToken.allowance(address(this), router);

        if (allowance < amt) {
            inToken.approve(router, type(uint256).max);
        }

        IUniswapV2Router r = IUniswapV2Router(router);
        uint256[] memory amounts = r.swapExactTokensForTokens(
            amt,
            1,
            path,
            msg.sender,
            block.timestamp + 1200
        );

        emit Swap(msg.sender, path, amounts[1]);
    }

    function swapTokensForETH(
        address router,
        address token,
        uint256 amountIn
    ) external locker {
        IERC20 inToken = IERC20(token);

        uint256 rate = fee;
        uint256 amt = rate > 0 ? afterFee(amountIn) : amountIn;

        inToken.safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 allowance = inToken.allowance(address(this), router);

        if (allowance < amt) {
            inToken.approve(router, type(uint256).max);
        }

        IUniswapV2Router r = IUniswapV2Router(router);
        address[] memory path = new address[](2);

        path[0] = token;
        path[1] = weth;

        uint256[] memory amounts = r.swapExactTokensForETH(
            amt,
            1,
            path,
            msg.sender,
            block.timestamp + 1200
        );

        emit Swap(msg.sender, path, amounts[1]);
    }

    function getReturn(
        address[] calldata routers,
        address[] calldata path,
        uint256 amountIn
    )
        external
        view
        returns (uint256[] memory amount0, uint256[] memory amount1)
    {
        uint256 amt = afterFee(amountIn);

        uint256 len = routers.length;
        amount0 = new uint256[](len);
        amount1 = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            IUniswapV2Router r = IUniswapV2Router(routers[i]);
            uint256[] memory val = r.getAmountsOut(amt, path);
            amount0[i] = val[0];
            amount1[i] = val[1];
        }
    }

    function getInput(
        address[] calldata routers,
        address[] calldata path,
        uint256 amountOut
    )
        external
        view
        returns (uint256[] memory amount0, uint256[] memory amount1)
    {
        uint256 amt = afterFee(amountOut);

        uint256 len = routers.length;
        amount0 = new uint256[](len);
        amount1 = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            IUniswapV2Router r = IUniswapV2Router(routers[i]);
            uint256[] memory val = r.getAmountsIn(amt, path);
            amount0[i] = val[0];
            amount1[i] = val[1];
        }
    }

    function afterFee(uint256 value) public view returns (uint256) {
        require(value > 0, "INVALID_INPUT");
        uint256 rate = fee;
        return (value - (((value * rate) / (100 * 1000))));
    }
}