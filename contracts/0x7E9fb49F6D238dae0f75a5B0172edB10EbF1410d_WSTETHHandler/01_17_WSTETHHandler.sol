// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ICollateralHandler.sol";
import "../dependencies/IWSTETH.sol";
import "../dependencies/IWETH9.sol";
import "../dependencies/ICurveStableSwap.sol";

contract WSTETHHandler is ICollateralHandler {
    using SafeERC20 for ISTETH;

    // @notice "i" and "j" are the first two parameters (token to sell and token to receive respectively)
    //         in the CurveStableSwap.exchange function.  They represent that contract's internally stored
    //         index of the token being swapped
    // @dev    The STETH/ETH pool only supports two tokens: ETH index: 0, STETH index: 1
    //         https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#readContract
    //         This can be confirmed by calling the "coins" function on the CurveStableSwap contract
    //         0 -> 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE == ETH (the address Curve uses to represent ETH -- see github link below)
    //         1 -> 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 == STETH (deployed contract address of STETH)
    // https://github.com/curvefi/curve-contract/blob/b0bbf77f8f93c9c5f4e415bce9cd71f0cdee960e/contracts/pools/steth/StableSwapSTETH.vy#L143
    int128 public constant TOKEN_IN = 1; // token to sell (STETH, index 1 on Curve contract)
    int128 public constant TOKEN_OUT = 0; // token to receive (ETH, index 0 on Curve contract)

    IWETH9 public constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ISTETH public constant STETH = ISTETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    ICurveStableSwap public constant CURVE = ICurveStableSwap(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    function handle(uint256 amount, address asset, bytes6, ILadle)
        external
        override
        returns (address newAsset, uint256 newAmount)
    {
        uint256 stEth = IWSTETH(asset).unwrap(amount);

        STETH.safeApprove(address(CURVE), stEth);
        // TODO add slippage guard
        newAmount = CURVE.exchange(TOKEN_IN, TOKEN_OUT, stEth, 0);

        WETH.deposit{value: newAmount}();
        newAsset = address(WETH);
    }

    function quote(uint256 amount, address, bytes6, ILadle)
        external
        view
        override
        returns (address newAsset, uint256 newAmount)
    {
        uint256 stEth = STETH.getPooledEthByShares(amount);
        newAmount = CURVE.get_dy(TOKEN_IN, TOKEN_OUT, stEth);
        newAsset = address(WETH);
    }
}