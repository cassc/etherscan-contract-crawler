// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/Uniswap.sol";

contract EfiSwap is IUniswapV2Callee {
    IUniswapV2Factory private uniswapFactory;
    address private owner;
    address private feeAddress;
    uint256 private feePercentage;

    event FeeAddressUpdated(
        address indexed previousFeeAddress,
        address indexed newFeeAddress
    );
    event FeePercentageUpdated(
        uint256 previousFeePercentage,
        uint256 newFeePercentage
    );

    constructor() {
        // Uniswap Factory address
        uniswapFactory = IUniswapV2Factory(
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        );
        owner = msg.sender;
        feeAddress = msg.sender;
        feePercentage = 3;
    }

    function flashSwap(
        address tokenIn,
        address tokenOut,
        uint256 _amount
    ) external {
        address pair = uniswapFactory.getPair(tokenIn, tokenOut);
        require(pair != address(0), "!pair");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = tokenOut == token0 ? _amount : 0;
        uint256 amount1Out = tokenOut == token1 ? _amount : 0;

        // need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(tokenOut, _amount);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function getFeeAddress() external onlyOwner view returns (address) {
        return feeAddress;
    }

    function getFeePercentage() external onlyOwner view returns (uint256) {
        return feePercentage;
    }

    function getSwapQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256) {
        address pairAddress = uniswapFactory.getPair(tokenIn, tokenOut);
        require(pairAddress != address(0), "EfiSwap: Invalid pair");

        (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(pairAddress)
            .getReserves();
        return (reserveOut * amountIn) / reserveIn;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "EfiSwap: Invalid fee address");
        emit FeeAddressUpdated(feeAddress, _feeAddress);
        feeAddress = _feeAddress;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "EfiSwap: Invalid fee percentage");
        emit FeePercentageUpdated(feePercentage, _feePercentage);
        feePercentage = _feePercentage;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "EfiSwap: Only owner can call this function"
        );
        _;
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = uniswapFactory.getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint256 amount) = abi.decode(
            _data,
            (address, uint256)
        );

        // about 0.3%
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;
        uint256 feeAmount = (amount * feePercentage) / 100;

        // emit Log("amount", amount);
        // emit Log("Amount0", _amount0);
        // emit Log("Amount", _amount1);
        // emit Log("Fee", fee);
        // emit Log("Smart Contract Fee", feeAmount);
        // emit Log("Amount to repay", amountToRepay);

        IERC20(tokenBorrow).transfer(pair, amountToRepay);

        IERC20(tokenBorrow).transfer(feeAddress, feeAmount);
    }
}