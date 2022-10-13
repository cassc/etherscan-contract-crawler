// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./ISwitchView.sol";
import "./IWETH.sol";
import "../lib/DisableFlags.sol";
import "../lib/UniversalERC20.sol";
import "../interfaces/IUniswapFactory.sol";
import "../lib/UniswapExchangeLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract SwitchRoot is ISwitchView {
    using DisableFlags for uint256;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniswapExchangeLib for IUniswapExchange;

    address public ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public ZERO_ADDRESS = address(0);

    uint256 public dexCount;
    uint256 public pathCount;
    uint256 public pathSplit;
    IWETH public weth; // chain's native token
    IWETH public otherToken; //could be weth on a non-eth chain or other mid token(like busd)

    address[] public factories;

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    constructor(address _weth, address _otherToken, uint256 _pathCount, uint256 _pathSplit, address[] memory _factories) {
        weth = IWETH(_weth);
        otherToken = IWETH(_otherToken);
        pathCount = _pathCount;
        pathSplit = _pathSplit;
        dexCount = _factories.length;
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
        }
    }

    function _findBestDistribution(
        uint256 s,                // parts
        int256[][] memory amounts // exchangesReturns
    )
        internal
        view
        returns (
            int256 returnAmount,
            uint256[] memory distribution
        )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](dexCount*pathCount*pathSplit);

        uint256 partsLeft = s;
        unchecked {
            for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
                distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
                partsLeft = parent[curExchange][partsLeft];
            }
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? int256(0) : answer[n - 1][s];
    }

    function _linearInterpolation(
        uint256 value,
        uint256 parts
    )
        internal
        pure
        returns (uint256[] memory rets)
    {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value * (i + 1) / parts;
        }
    }

    function _tokensEqual(
        IERC20 tokenA,
        IERC20 tokenB
    )
        internal
        pure
        returns (bool)
    {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}