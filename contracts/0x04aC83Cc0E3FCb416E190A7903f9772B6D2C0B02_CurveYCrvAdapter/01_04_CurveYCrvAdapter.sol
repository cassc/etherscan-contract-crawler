// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./../interfaces/IExchangeAdapter.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurveCrv {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);
}

contract CurveYCrvAdapter is IExchangeAdapter {
    address public constant YCRV_POOL =
        0x453D92C7d4263201C69aACfaf589Ed14202d83a4;
    address public constant CRV_ETH_POOL_ADDRESS =
        0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;

    function executeSwap(
        address,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        if (toToken == YCRV_POOL) {
            uint256 crvAmountToDeposit = ICurveCrv(CRV_ETH_POOL_ADDRESS)
                .exchange(0, 1, amount, 0, false);

            return
                ICurveCrv(YCRV_POOL).add_liquidity([crvAmountToDeposit, 0], 0);
        } else if (fromToken == YCRV_POOL) {
            uint256 crvAmountToWithdraw = ICurveCrv(YCRV_POOL)
                .remove_liquidity_one_coin(amount, 0, 0);

            return
                ICurveCrv(CRV_ETH_POOL_ADDRESS).exchange(
                    1,
                    0,
                    crvAmountToWithdraw,
                    0,
                    false
                );
        } else {
            revert("CurveYCrvAdapter: Can't Swap");
        }
    }

    // 0xe83bbb76  =>  enterPool(address,address,address,uint256)
    function enterPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("CurveYCrvAdapter: Can't Swap");
    }

    // 0x9d756192  =>  exitPool(address,address,address,uint256)
    function exitPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("CurveYCrvAdapter: Can't Swap");
    }
}