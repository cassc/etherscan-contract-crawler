//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ZkSyncBridgeSwapper.sol";
import "./interfaces/ILido.sol";
import "./interfaces/ICurvePool.sol";
import "./interfaces/IYearnVault.sol";

/**
* @notice Exchanges Eth for the "Yearn vault Curve pool staked Eth" token.
* Indexes:
* 0: Eth
* 1: yvCrvStEth
*/
contract BoostedEthBridgeSwapper is ZkSyncBridgeSwapper {

    address public immutable stEth;
    address public immutable crvStEth;
    address public immutable yvCrvStEth;

    ICurvePool public immutable stEthPool;
    address public immutable lidoReferral;

    constructor(
        address _zkSync,
        address _l2Account,
        address _yvCrvStEth,
        address _stEthPool,
        address _lidoReferral
    )
        ZkSyncBridgeSwapper(_zkSync, _l2Account)
    {
        require(_yvCrvStEth != address(0), "null _yvCrvStEth");
        yvCrvStEth = _yvCrvStEth;
        address _crvStEth = IYearnVault(_yvCrvStEth).token();
        require(_crvStEth != address(0), "null crvStEth");

        require(_stEthPool != address(0), "null _stEthPool");

        require(_crvStEth == ICurvePool(_stEthPool).lp_token(), "crvStEth mismatch");
        crvStEth = _crvStEth;
        stEth = ICurvePool(_stEthPool).coins(1);
        stEthPool = ICurvePool(_stEthPool);
        lidoReferral = _lidoReferral;
    }

    function exchange(
        uint256 _indexIn,
        uint256 _indexOut,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) 
        onlyOwner
        external 
        override 
        returns (uint256 amountOut) 
    {
        require(_indexIn + _indexOut == 1, "invalid indexes");

        if (_indexIn == 0) {
            transferFromZkSync(ETH_TOKEN);
            amountOut = swapEthForYvCrv(_amountIn);
            require(amountOut >= _minAmountOut, "slippage");
            transferToZkSync(yvCrvStEth, amountOut);
            emit Swapped(ETH_TOKEN, _amountIn, yvCrvStEth, amountOut);
        } else {
            transferFromZkSync(yvCrvStEth);
            amountOut = swapYvCrvForEth(_amountIn);
            require(amountOut >= _minAmountOut, "slippage");
            transferToZkSync(ETH_TOKEN, amountOut);
            emit Swapped(yvCrvStEth, _amountIn, ETH_TOKEN, amountOut);
        }
    }

    function swapEthForYvCrv(uint256 _amountIn) internal returns (uint256) {
        // ETH -> crvStETH
        uint256 crvStEthAmount = stEthPool.add_liquidity{value: _amountIn}([_amountIn, 0], 1);

        // crvStETH -> yvCrvStETH
        IERC20(crvStEth).approve(yvCrvStEth, crvStEthAmount);
        return IYearnVault(yvCrvStEth).deposit(crvStEthAmount);
    }

    function swapYvCrvForEth(uint256 _amountIn) internal returns (uint256) {
        // yvCrvStETH -> crvStETH
        uint256 crvStEthAmount = IYearnVault(yvCrvStEth).withdraw(_amountIn);

        // crvStETH -> ETH
        return stEthPool.remove_liquidity_one_coin(crvStEthAmount, 0, 1);
    }

    function ethPerYvCrvStEth(uint256 _yvCrvStEthAmount) public view returns (uint256) {
        uint256 crvStEthAmount = _yvCrvStEthAmount * IYearnVault(yvCrvStEth).pricePerShare() / 1 ether;
        return stEthPool.calc_withdraw_one_coin(crvStEthAmount, 0);
    }

    function yvCrvStEthPerEth(uint256 _ethAmount) public view returns (uint256) {
        uint256 crvStEthAmount = stEthPool.calc_token_amount([_ethAmount, 0], true);
        return 1 ether * crvStEthAmount / IYearnVault(yvCrvStEth).pricePerShare();
    }

    function tokens(uint256 _index) external view returns (address) {
        if (_index == 0) {
            return ETH_TOKEN;
        } else if (_index == 1) {
            return yvCrvStEth;
        }
        revert("invalid _index");
    }
}