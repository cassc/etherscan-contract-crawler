// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import './IHelioswap.sol';

interface IHelioswapFactory {
    function pools(IERC20 token1, IERC20 token2)
        external
        view
        returns (
            IHelioswap,
            uint256,
            uint256,
            uint256,
            uint256[2] memory,
            uint256[2] memory
        );
}

library HelioswapLibrary {
    function getReturns(
        IHelioswapFactory helioswapFactory,
        uint256 amountIn,
        IERC20[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'TOKordinator: invalid path');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (IHelioswap pool, , , , , ) = helioswapFactory.pools(path[i], path[i + 1]);
            amounts[i + 1] = pool.getReturn(path[i], path[i + 1], amounts[i]);
        }
    }
}