// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../swap/IBonfirePair.sol";
import "../swap/IBonfireTokenManagement.sol";
import "../swap/BonfireRouterPaths.sol";
import "../swap/BonfireSwapHelper.sol";

library BonfireQuoteCheck {
    address public constant tokenManagement =
        address(0xBF5051b1794aEEB327852Df118f77C452bFEd00d);

    error ImplausibleFactors(uint256 p, uint256 q);
    error ImplausibleAmount(uint256 index);

    /**
     * This function is designed such that it computes the maximal amountIn to
     * ensure that with the given path any single pool in the path has a max
     * price increase of
     *           X = (Q/(Q-P))^2
     *
     * In addition the parameter permilleIncrease returns the estimated overall
     * price increase of the input given. In comparison, the suggestedAmountIn
     * should have a maximal price increase of
     *           P = X ^ poolPath.length
     *
     * In other words if the user opts for the paths as given but the
     * suggestedAmountIn instead of the amountIn input for any pool along the
     * path we have a maximum output of
     *        bOut = reserveB * P / Q
     * and a maximum input of
     *         aIn = reserveA * P / (Q - P)
     *
     */
    function querySwapAmount(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amountIn,
        uint256 maxChangeFactorP,
        uint256 maxChangeFactorQ
    )
        external
        view
        returns (uint256 suggestedAmountIn, uint256 permilleIncrease)
    {
        if (maxChangeFactorP >= maxChangeFactorQ || maxChangeFactorP == 0) {
            revert ImplausibleFactors(maxChangeFactorP, maxChangeFactorQ);
        }
        suggestedAmountIn = computeSuggestedAmountInMax(
            poolPath,
            tokenPath,
            maxChangeFactorP,
            maxChangeFactorQ
        );
        suggestedAmountIn = suggestedAmountIn <= amountIn
            ? suggestedAmountIn
            : amountIn;
        permilleIncrease = computePermilleIncrease(
            poolPath,
            tokenPath,
            amountIn
        );
    }

    function computeSuggestedAmountInMax(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 maxChangeFactorP,
        uint256 maxChangeFactorQ
    ) public view returns (uint256 amount) {
        amount =
            (IBonfireTokenManagement(tokenManagement).maxTx(
                tokenPath[tokenPath.length - 1]
            ) * 95) /
            100;
        if (amount == 0) {
            amount = IERC20(tokenPath[tokenPath.length - 1]).totalSupply();
        }
        for (uint256 i = poolPath.length; i > 0; ) {
            //gas optimization
            unchecked {
                i--;
            }
            if (amount == 0) revert ImplausibleAmount(i);
            if (BonfireSwapHelper.isWrapper(poolPath[i])) {
                address target = i > 0 ? poolPath[i - 1] : msg.sender;
                amount = BonfireRouterPaths.wrapperQuote(
                    tokenPath[i + 1],
                    tokenPath[i],
                    amount,
                    target
                );
            } else {
                (uint256 rA, uint256 rB, ) = IBonfirePair(poolPath[i])
                    .getReserves();
                (rA, rB) = IBonfirePair(poolPath[i]).token0() == tokenPath[i]
                    ? (rA, rB)
                    : (rB, rA);
                if (amount > 0) {
                    uint256 adjustment = BonfireSwapHelper.reflectionAdjustment(
                        tokenPath[i + 1],
                        poolPath[i],
                        amount,
                        rB
                    );
                    if (adjustment > amount) {
                        amount = (amount * amount) / adjustment;
                    }
                }
                amount = amount > (rB * maxChangeFactorP) / maxChangeFactorQ
                    ? ((rA * maxChangeFactorP) /
                        (maxChangeFactorQ - maxChangeFactorP))
                    : (rA * amount) / (rB - amount);
            }
            {
                uint256 maxTx = (IBonfireTokenManagement(tokenManagement).maxTx(
                    tokenPath[i]
                ) * 95) / 100;
                if (maxTx != 0 && maxTx < amount) {
                    amount = maxTx;
                }
            }
        }
    }

    function computePermilleIncrease(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amount
    ) public view returns (uint256 permilleIncrease) {
        permilleIncrease = 1000;
        for (uint256 i = 0; i < poolPath.length; i++) {
            if (!BonfireSwapHelper.isWrapper(poolPath[i])) {
                (uint256 rA, uint256 rB, ) = IBonfirePair(poolPath[i])
                    .getReserves();
                (rA, rB) = IBonfirePair(poolPath[i]).token0() == tokenPath[i]
                    ? (rA, rB)
                    : (rB, rA);
                uint256 amountB = (rB * amount) / (rA + amount);
                uint256 increase = (1000 * ((rA * rB) + (amount * rB))) /
                    ((rA * rB) - (rA * amountB));
                permilleIncrease = (permilleIncrease * increase) / 1000;
                amount = amountB;
            } else {
                address target = i < poolPath.length - 1
                    ? poolPath[i + 1]
                    : msg.sender;
                amount = BonfireRouterPaths.quote(
                    poolPath[i:i],
                    tokenPath[i:i + 1],
                    amount,
                    target
                );
            }
        }
    }
}