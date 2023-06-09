// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./SwapState.sol";

/**
 * @title SwapSetters
 */
contract SwapSetters is SwapState, AccessControl {
    using SafeERC20 for IERC20;

    using SafeMath for uint256;

    function withdrawIfAnyEthBalance(address payable receiver) external returns (uint256) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        uint256 balance = address(this).balance;
        receiver.transfer(balance);
        return balance;
    }

    function withdrawIfAnyTokenBalance(address contractAddress, address receiver) external returns (uint256) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        IERC20 token = IERC20(contractAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(receiver, balance);
        return balance;
    }

    function setFeeCollector(address _feeCollector) internal {
        require(_feeCollector != address(0), "Key Pair: Fee Collector Invalid");
        FEE_COLLECTOR = _feeCollector;
    }

    function set1InchRouter(address _1inchRouter) internal {
        require(_1inchRouter != address(0), "Key Pair: _1inchRouter Invalid");
        oneInchAggregatorRouter = _1inchRouter;
    }

    function set0xRouter(address _0xRouter) internal {
        require(_0xRouter != address(0), "Key Pair: _0xRouter Invalid");
        OxAggregatorRouter = _0xRouter;
    }
} // end of class