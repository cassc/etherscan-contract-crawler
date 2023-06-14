// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IDODO {
    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external view returns (address);

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);

    function getExpectedTarget() external view returns (uint256 baseTarget, uint256 quoteTarget);

    function getTotalBaseCapital() external view returns (uint256);

    function getTotalQuoteCapital() external view returns (uint256);

    function getBaseCapitalBalanceOf(address lp) external view returns (uint256);

    function getQuoteCapitalBalanceOf(address lp) external view returns (uint256);
}

interface IDODOLpToken {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract DODOV1Proxy is Ownable {
    using SafeERC20 for IERC20;

    // 1. calculate the required amount of dlp token
    // 2. user transfer dlp to this proxy
    // 3. this proxy call withdraw
    // 4. this proxy receive token
    // 5. check return amount
    // 6. send token to user
    function withdrawBase(address pool, uint256 amount, uint256 minReceive) external returns (uint256 returnAmount) {
        (uint256 baseTarget, ) = IDODO(pool).getExpectedTarget();
        uint256 totalBaseCapital = IDODO(pool).getTotalBaseCapital();
        require(totalBaseCapital > 0, "NO_BASE_LP");
        uint256 requireBaseCapital = divCeil(amount * totalBaseCapital, baseTarget);

        address baseLPToken = IDODO(pool)._BASE_CAPITAL_TOKEN_();
        IDODOLpToken(baseLPToken).transferFrom(msg.sender, address(this), requireBaseCapital);
        
        returnAmount = IDODO(pool).withdrawBase(amount);
        require(returnAmount >= minReceive, "return amount not enough");

        address baseToken = IDODO(pool)._BASE_TOKEN_();
        IERC20(baseToken).safeTransfer(msg.sender, returnAmount);
    }

    function withdrawQuote(address pool, uint256 amount, uint256 minReceive) external returns (uint256 returnAmount) {
        (, uint256 quoteTarget) = IDODO(pool).getExpectedTarget();
        uint256 totalQuoteCapital = IDODO(pool).getTotalQuoteCapital();
        require(totalQuoteCapital > 0, "NO_QUOTE_LP");
        uint256 requireQuoteCapital = divCeil(amount * totalQuoteCapital, quoteTarget);

        address quoteLPToken = IDODO(pool)._QUOTE_CAPITAL_TOKEN_();
        IDODOLpToken(quoteLPToken).transferFrom(msg.sender, address(this), requireQuoteCapital);

        returnAmount = IDODO(pool).withdrawQuote(amount);
        require(returnAmount >= minReceive, "return amount not enough");

        address quoteToken = IDODO(pool)._QUOTE_TOKEN_();
        IERC20(quoteToken).safeTransfer(msg.sender, returnAmount);
    }


    function withdrawAllBase(address pool, uint256 minReceive) external returns (uint256 returnAmount) {
        address baseLPToken = IDODO(pool)._BASE_CAPITAL_TOKEN_();
        uint256 dlpBalance = IDODOLpToken(baseLPToken).balanceOf(msg.sender);
        IDODOLpToken(baseLPToken).transferFrom(msg.sender, address(this), dlpBalance);
        
        returnAmount = IDODO(pool).withdrawAllBase();
        require(returnAmount >= minReceive, "return amount not enough");

        address baseToken = IDODO(pool)._BASE_TOKEN_();
        IERC20(baseToken).safeTransfer(msg.sender, returnAmount);
    }

    function withdrawAllQuote(address pool, uint256 minReceive) external returns (uint256 returnAmount) {
        address quoteLPToken = IDODO(pool)._QUOTE_CAPITAL_TOKEN_();
        uint256 dlpBalance = IDODOLpToken(quoteLPToken).balanceOf(msg.sender);
        IDODOLpToken(quoteLPToken).transferFrom(msg.sender, address(this), dlpBalance);
        
        returnAmount = IDODO(pool).withdrawAllQuote();
        require(returnAmount >= minReceive, "return amount not enough");

        address quoteToken = IDODO(pool)._QUOTE_TOKEN_();
        IERC20(quoteToken).safeTransfer(msg.sender, returnAmount);
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function withdrawLeftToken(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);
    }
}