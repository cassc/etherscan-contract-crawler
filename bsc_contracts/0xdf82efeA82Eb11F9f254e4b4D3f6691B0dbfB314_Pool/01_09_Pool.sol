// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ILogic.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IDToken.sol";
import "./tokens/ERC20.sol";

contract Pool is IPool, ERC20, IERC20Metadata {
    string public constant override name = "Derivable Collateral Provider";
    string public constant override symbol = "DDL-CP";
    uint8 public constant override decimals = 18;

    address public immutable COLLATERAL_TOKEN;
    address public immutable LOGIC;
    address immutable FEE_RECIPIENT;
    uint immutable FEE_NUM;
    uint immutable FEE_DENOM;

    event Swap(
        address indexed recipient,
        address indexed tokenIn,
        address indexed tokenOut,
        uint            amountOut,
        uint            fee
    );

    constructor(address logic) {
        LOGIC = logic;
        COLLATERAL_TOKEN = ILogic(LOGIC).COLLATERAL_TOKEN();
        (FEE_RECIPIENT, FEE_NUM, FEE_DENOM) = IPoolFactory(msg.sender).getFeeInfo();
    }

    /// @dev require amountIn is transfered here first
    function swap(
        address tokenIn,
        address tokenOut,
        address recipient
    ) external override returns (uint amountOut, uint fee) {
        bool needVerifying;
        (amountOut, needVerifying) = ILogic(LOGIC).swap(tokenIn, tokenOut);

        if (tokenOut == COLLATERAL_TOKEN) {
            // TODO: fee can be get-arounded if LOGIC don't use the POOL token
            if (tokenIn == address(this)) {
                fee = amountOut * FEE_NUM / FEE_DENOM;
                if (fee > 0) {
                    IERC20(COLLATERAL_TOKEN).transfer(FEE_RECIPIENT, fee);
                    amountOut -= fee;
                }
            }
            IERC20(COLLATERAL_TOKEN).transfer(recipient, amountOut);
        } else if (tokenOut == address(this)) {
            _mint(recipient, amountOut);
        } else {
            IDToken(tokenOut).mint(amountOut, recipient);
        }

        if (tokenIn == COLLATERAL_TOKEN) {
            // nothing to do
        } else if (tokenIn == address(this)) {
            _burn(address(this), balanceOf(address(this)));
        } else {
            IDToken(tokenIn).burn(address(this));
        }

        if (needVerifying) {
            ILogic(LOGIC).verify();
        }

        emit Swap(recipient, tokenIn, tokenOut, amountOut, fee);
    }
}