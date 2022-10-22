// SPDX-License-Identifier: MIT
// This is a James McLendon x Noble Dev exclusive game changing contract. If you clone, give us a shoutout! <3 - Telegram/Twitter/IG @eGodShow
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface Router {

    function getAmountsOut(
        uint amountIn, address[] memory path
    ) external view returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract BuyingUtility is AccessControl, ReentrancyGuard {

    bytes32 public constant BOT_ROLE = keccak256("BOT_ROLE");
    address public immutable WETH;

    uint256 public pendingPlatformFee;

    event Buy(address to, uint256 ethAmount, address token, uint256 amounts, uint256 approxTxFee, uint256 platformFee);
    event FeeWithdrawn(address caller, address to, uint256 amount);

    constructor(address _weth) {
        WETH = _weth;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(BOT_ROLE, _msgSender());
    }

    function withdrawFee(
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount <= pendingPlatformFee, "AMOUNT_TOO_HIGH");

        unchecked {
            pendingPlatformFee -= amount;
        }

        (bool sent,) = to.call{value: amount}("");
        require(sent, "FAILED_TO_SEND_FEE");
        emit FeeWithdrawn(_msgSender(), to, amount);
    }

    function buyToken(
        uint256 ethAmount,
        address token,
        uint256 tokenAmountPerETH,
        uint256 slippageBIPS,
        address to,
        address router,
        uint256 platformFeeBIPS,
        uint256 gasEstimate,
        uint256 deadline
    ) external onlyRole(BOT_ROLE) nonReentrant() {

        require(block.timestamp <= deadline, "EXPIRED");

        uint256 approxTxFee = gasEstimate * tx.gasprice;
        require(ethAmount > approxTxFee, "FEE_MORE_THAN_AMOUNT");
        ethAmount -= approxTxFee;

        uint256 platformFee = platformFeeBIPS * ethAmount / 10000;
        pendingPlatformFee += platformFee;

        ethAmount -= platformFee;
        require(ethAmount > 0, "INSUFFICIENT_ETH_TO_SWAP");

        uint256 tokenAmount = _checkAndSwap(ethAmount, router, token, tokenAmountPerETH, slippageBIPS, to);

        (bool sent,) = _msgSender().call{value: approxTxFee}("");
        require(sent, "FAILED_TO_SEND_FEE_TO_CALLER");

        emit Buy(to, ethAmount, token, tokenAmount, approxTxFee, platformFee);
    }

    function _checkAndSwap(
        uint256 ethAmount,
        address router,
        address token,
        uint256 tokenAmountPerETH,
        uint256 slippageBIPS,
        address to
    ) internal returns(uint256) {

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;

        uint256[] memory amounts = Router(router).getAmountsOut(ethAmount, path);
        uint256 amountOutMin = ethAmount * tokenAmountPerETH * (1E4 - slippageBIPS) / 1E22;
        require(amounts[1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        Router(router).swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethAmount }(
            amounts[1],
            path,
            to,
            block.timestamp
        );

        return amounts[1];
    }

    receive() external payable {}
}