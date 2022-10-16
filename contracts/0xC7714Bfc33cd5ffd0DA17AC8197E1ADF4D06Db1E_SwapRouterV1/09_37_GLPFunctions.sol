// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../ServiceLocator.sol";
import "./CryptoToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library GLPFunctions {
    using SafeERC20 for IERC20;

    function _getToken(ServiceLocator svcLoc, CryptoToken token)
        public
        view
        returns (IERC20)
    {
        IERC20 ierc20;
        if (token == CryptoToken.USDC) {
            ierc20 = IERC20(svcLoc.usdc());
        } else if (token == CryptoToken.GPO) {
            ierc20 = IERC20(svcLoc.gpo());
        } else if (token == CryptoToken.LP) {
            ierc20 = IERC20(svcLoc.staking());
        } else {
            return IERC20(address(0x0));
        }
        return ierc20;
    }

    function balance(
        ServiceLocator svcLoc,
        CryptoToken token,
        address owner
    ) public view returns (uint256) {
        if (token == CryptoToken.NATIVE) return owner.balance;
        return _getToken(svcLoc, token).balanceOf(owner);
    }

    function transferFrom(
        ServiceLocator svcLoc,
        CryptoToken token,
        address from,
        address to,
        uint256 amount
    ) public {
        require(token != CryptoToken.NATIVE, "GF: cannot transfer from native");
        _getToken(svcLoc, token).safeTransferFrom(from, to, amount);
    }

    function transfer(
        ServiceLocator svcLoc,
        CryptoToken token,
        address to,
        uint256 amount
    ) public {
        if (token == CryptoToken.NATIVE) {
            payable(to).transfer(amount);
        } else {
            _getToken(svcLoc, token).safeTransfer(to, amount);
        }
    }

    function increaseAllowance(
        ServiceLocator svcLoc,
        CryptoToken token,
        address spender,
        uint256 amount
    ) public {
        require(token != CryptoToken.NATIVE, "GF: cannot approve native");
        _getToken(svcLoc, token).safeIncreaseAllowance(spender, amount);
    }

}