// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IComet} from "src/interfaces/compound/IComet.sol";
import {IRewards} from "src/interfaces/compound/IRewards.sol";
import {IComptroller} from "src/interfaces/compound/IComptroller.sol";

import {AffineVault} from "src/vaults/AffineVault.sol";
import {AccessStrategy} from "src/strategies/AccessStrategy.sol";

contract CompoundV3Strategy is AccessStrategy {
    using SafeTransferLib for ERC20;


    /// @notice Corresponding Compound token for `asset`(e.g. cUSDCV3 for USDC)
    IComet public immutable cToken;
    /// @notice Comet rewards contract. Used for claiming comp.
    IRewards public immutable rewards;

    /// @notice The compound governance token
    ERC20 public immutable comp;

    /// @notice Weth address. Our swap path is always comp > weth > asset
    address public immutable weth;

    /// @notice Uni router for swapping comp to `asset`
    IUniswapV2Router02 public immutable router;

    constructor(AffineVault _vault, IComet _cToken, IRewards _rewards,  ERC20 _comp, address _weth, IUniswapV2Router02 _router,  address[] memory strategists)AccessStrategy(_vault, strategists) {
        cToken = _cToken;
        rewards = _rewards;
        comp = _comp;
        weth = _weth;
        router = _router;

        // We can supply asset to Comet contract (V3 market) and also sell comp
        asset.safeApprove(address(cToken), type(uint256).max);
        comp.safeApprove(address(router), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                               INVESTMENT
    //////////////////////////////////////////////////////////////*/
    function _afterInvest(uint256 amount) internal override {
        if (amount == 0) return;
        cToken.supply(address(asset), amount);
    }

    /*//////////////////////////////////////////////////////////////
                               DIVESTMENT
    //////////////////////////////////////////////////////////////*/
    function _divest(uint256 assets) internal override returns (uint256) {
        uint256 currAssets = balanceOfAsset();
        uint256 assetsReq = currAssets >= assets ? 0 : assets - currAssets;

        // Withdraw the needed amount
        if (assetsReq != 0) {
            uint256 assetsToWithdraw = Math.min(assetsReq, cToken.balanceOf(address(this)));
            cToken.withdraw(address(asset), assetsToWithdraw);
        }

        uint256 amountToSend = Math.min(assets, balanceOfAsset());
        asset.safeTransfer(address(vault), amountToSend);
        return amountToSend;
    }


    /*//////////////////////////////////////////////////////////////
                                REWARDS
    //////////////////////////////////////////////////////////////*/
    function _claim() internal {
        rewards.claim({comet: address(cToken), src: address(this), shouldAccrue: true});
    }
    function _sell(uint minAssetsFromRewards) internal {
         uint256 compBalance = comp.balanceOf(address(this));

        address[] memory path = new address[](3);
        path[0] = address(comp);
        path[1] = weth;
        path[2] = address(asset);

        if (compBalance > 0.01e18) {
            router.swapExactTokensForTokens({
                amountIn: compBalance,
                amountOutMin: minAssetsFromRewards,
                path: path,
                to: address(this),
                deadline: block.timestamp
            });
        }
    }

    /// @notice Claim comp rewards and sell them for `asset`
    function claimAndSellRewards(uint256 minAssetsFromReward) external onlyRole(STRATEGIST_ROLE) {
        _claim();
       _sell(minAssetsFromReward);
    }

    function claimRewards() external onlyRole(STRATEGIST_ROLE) {
        _claim();
    }

    /*//////////////////////////////////////////////////////////////
                             TVL ESTIMATION
    //////////////////////////////////////////////////////////////*/
    function totalLockedValue() public override returns (uint256) {
        return balanceOfAsset() + cToken.balanceOf(address(this));
    }
}