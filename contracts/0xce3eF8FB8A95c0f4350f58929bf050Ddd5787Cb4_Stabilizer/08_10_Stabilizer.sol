// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IApeToken.sol";
import "./interfaces/ICurveStableSwap.sol";

contract Stabilizer is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ICurveStableSwap public constant apeUSDCurvePool =
        ICurveStableSwap(0x04b727C7e246CA70d496ecF52E6b6280f3c8077D);
    IERC20 public constant FRAX =
        IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e); // j = 1
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // j = 2

    IApeToken public immutable apeApeUSD;
    IERC20 public immutable apeUSD;

    constructor(address _apeApeUSD) {
        apeApeUSD = IApeToken(_apeApeUSD);
        apeUSD = IERC20(apeApeUSD.underlying());
    }

    function getAmountStable(uint256 amount, int128 outputCoinIndex)
        external
        view
        returns (uint256)
    {
        return apeUSDCurvePool.get_dy_underlying(0, outputCoinIndex, amount);
    }

    function getAmountApuUSD(uint256 amount, int128 inputCoinIndex)
        external
        view
        returns (uint256)
    {
        return apeUSDCurvePool.get_dy_underlying(inputCoinIndex, 0, amount);
    }

    function swapApeUSDForStable(
        uint256 amount,
        int128 outputCoinIndex,
        uint256 minOutput
    ) external onlyOwner {
        require(
            outputCoinIndex == 1 || outputCoinIndex == 2,
            "unsupported coin"
        );

        if (amount != 0) {
            // Borrow.
            require(
                apeApeUSD.borrow(payable(address(this)), amount) == 0,
                "borrow failed"
            );
        }

        // Approve and swap.
        uint256 bal = apeUSD.balanceOf(address(this));
        apeUSD.safeIncreaseAllowance(address(apeUSDCurvePool), bal);
        apeUSDCurvePool.exchange_underlying(0, outputCoinIndex, bal, minOutput);
    }

    function swapStableForApeUSD(
        uint256 amount,
        int128 inputCoinIndex,
        uint256 minOutput
    ) external onlyOwner {
        require(inputCoinIndex == 1 || inputCoinIndex == 2, "unsupported coin");

        if (amount != 0) {
            // Approve and swap.
            if (inputCoinIndex == 1) {
                FRAX.safeIncreaseAllowance(address(apeUSDCurvePool), amount);
            } else if (inputCoinIndex == 2) {
                USDC.safeIncreaseAllowance(address(apeUSDCurvePool), amount);
            }

            apeUSDCurvePool.exchange_underlying(
                inputCoinIndex,
                0,
                amount,
                minOutput
            );
        }

        // Approve and repay.
        uint256 repayAmount = apeUSD.balanceOf(address(this));
        uint256 borrowBalance = apeApeUSD.borrowBalanceCurrent(address(this));
        if (repayAmount > borrowBalance) {
            repayAmount = borrowBalance;
        }
        apeUSD.safeIncreaseAllowance(address(apeApeUSD), repayAmount);
        require(
            apeApeUSD.repayBorrow(payable(address(this)), repayAmount) == 0,
            "repay failed"
        );
    }

    function seize(address token, uint256 amount) external onlyOwner {
        if (
            token == address(apeUSD) ||
            token == address(FRAX) ||
            token == address(USDC)
        ) {
            uint256 borrowBalance = apeApeUSD.borrowBalanceCurrent(
                address(this)
            );
            require(borrowBalance == 0, "borrow balance not zero");
        }
        IERC20(token).safeTransfer(owner(), amount);
    }
}