//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface PancakeRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Rebalancer {
    PancakeRouter public pancakeRouter = PancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    event Executed (
        address indexed sender,
        uint256 indexed _nonce
    );

    mapping(address => uint256) public nonces;

    function call(
        IERC20 _baseToken,
        address[][] memory _sellPaths,
        uint256[] memory _sellMinAmounts,
        address[][] memory _buyPaths,
        uint256[] memory _buyMaxPrices,
        uint256 _buyMaxPriceDenom,
        uint256[] memory _buyShares,
        uint256 _nonce
    ) public {
        for (uint8 i = 0; i < _sellPaths.length; i++) {
            IERC20 token = IERC20(_sellPaths[i][0]);
            token.transferFrom(msg.sender, address(this), token.balanceOf(msg.sender));
            if (address(token) == address(_baseToken)) {
               continue;
            }
            token.approve(address(pancakeRouter), token.balanceOf(address(this)));
            pancakeRouter.swapExactTokensForTokens(
                token.balanceOf(address(this)),
                _sellMinAmounts[i],
                _sellPaths[i],
                address(this),
                block.timestamp
            );
        }

        uint256 baseTokenBalance = _baseToken.balanceOf(address(this));
        _baseToken.approve(address(pancakeRouter), baseTokenBalance);

        for (uint8 i = 0; i < _buyPaths.length; i++) {
            IERC20 token = IERC20(_sellPaths[i][0]);
            uint256 toSell = baseTokenBalance * _buyShares[i] / 10000;

            if (address(token) == address(_baseToken)) {
                token.transfer(msg.sender, toSell);
                continue;
            }

            uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(
                toSell,
                0,
                _buyPaths[i],
                msg.sender,
                block.timestamp
            );

            require(toSell * _buyMaxPriceDenom / amounts[amounts.length - 1] >= _buyMaxPrices[i], "Price too high");
        }

        nonces[msg.sender] = _nonce;
        emit Executed(msg.sender, _nonce);
    }
}