//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./CompoundUtils.sol";
import "./OracleChainLink.sol";

import "../lib/UniversalERC20.sol";
import "../interface/compound/ICERC20.sol";

import "hardhat/console.sol";

contract ProtocolCompound is CompoundUtils, OracleChainLink {
    using UniversalERC20 for IERC20;

    function collateralAmount(IERC20 token) public returns (uint256) {
        return _getCToken(token).balanceOfUnderlying(address(this));
    }

    function borrowAmount(IERC20 token) public returns (uint256) {
        return _getCToken(token).borrowBalanceCurrent(address(this));
    }

    function _pnl(IERC20 collateral, IERC20 debt) internal returns (uint256) {
        return ((_getPrice(collateral) * collateralAmount(collateral) * 1e18) / _getPrice(debt)) * borrowAmount(debt);
    }

    function _deposit(IERC20 token, uint256 amount) internal {
        ICERC20 cToken = _getCToken(token);
        if (!cToken.comptroller().checkMembership(address(this), address(cToken))) {
            _enterMarket(cToken);
        }

        if (token.isETH()) {
            cToken.mint{value: amount}();
        } else {
            token.universalApprove(address(cToken), amount);
            cToken.mint(amount);
        }
    }

    function _redeem(IERC20 token, uint256 amount) internal {
        ICERC20 cToken = _getCToken(token);
        uint code = cToken.redeem(amount);
        require(code == 0, "redeem is failed");
    }

    function _redeemAll(IERC20 token) internal {
        ICERC20 cToken = _getCToken(token);
        _redeem(token, IERC20(cToken).universalBalanceOf(address(this)));
    }

    function _borrow(IERC20 token, uint256 amount) internal {
        ICERC20 cToken = _getCToken(token);
        if (!cToken.comptroller().checkMembership(address(this), address(cToken))) {
            _enterMarket(cToken);
        }
        uint code = cToken.borrow(amount);
        require(code == 0, "borrow is failed");
    }

    function _repay(IERC20 token, uint256 amount) internal {
        ICERC20 cToken = _getCToken(token);
        uint code;
        if (token.isETH()) {
            code = cToken.repayBorrow{value: amount}();
        } else {
            token.universalApprove(address(cToken), amount);
            code = cToken.repayBorrow(amount);
        }
        require(code == 0, "repay is failed");
    }

    // Private

    function _enterMarket(ICERC20 cToken) private {
        address[] memory tokens = new address[](1);

        tokens[0] = address(cToken);
        cToken.comptroller().enterMarkets(tokens);
    }
}