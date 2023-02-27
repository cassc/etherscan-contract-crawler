// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

contract Vault is Configurable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 internal constant _rewardToken_ = "rewardToken";
    bytes32 internal constant _rebaseTime_ = "rebaseTime";
    bytes32 internal constant _rebasePeriod_ = "rebasePeriod";
    bytes32 internal constant _factorPrice20_ = "factorPrice20";
    bytes32 internal constant _lpTknMaxRatio_ = "lpTknMaxRatio";
    bytes32 internal constant _lpCurMaxRatio_ = "lpCurMaxRatio";
    bytes32 internal constant _pairTokenA_ = "pairTokenA";
    bytes32 internal constant _swapFactory_ = "swapFactory";
    bytes32 internal constant _swapRouter_ = "swapRouter";
    bytes32 internal constant _mine_ = "mine";

    IDotc public dotc;

    function __Vault_init(address governor, address dotc_) public initializer {
        __Governable_init_unchained(governor);
        __Vault_init_unchained(dotc_);
    }

    function __Vault_init_unchained(address dotc_) internal initializer {
        vaultSetPara(dotc_);
    }

    function vaultSetPara(address dotc_) public governance {
        dotc = IDotc(dotc_);
        config[_rebaseTime_] = now.add(0 days).add(8 hours).sub(now % 8 hours);
        config[_rebasePeriod_] = 8 hours;
        config[_factorPrice20_] = 1.1e18; // price20 = price1 * 1.1
        config[_lpTknMaxRatio_] = 0.10e18; // 10%
        config[_lpCurMaxRatio_] = 0.50e18; // 50%
    }

    function setDotc(address dotc_) public governance {
        dotc = IDotc(dotc_);
    }

    function rebase() public {
        uint256 time = config[_rebaseTime_];
        if (now < time) return;
        uint256 period = config[_rebasePeriod_];
        config[_rebaseTime_] = time.add(period);
        _adjustLiquidity();
    }

    function _adjustLiquidity() internal {
        uint256 curBal = 0;
        uint256 tknBal = 0;
        address tokenA = address(dotc.getConfig(_pairTokenA_));
        address rewardToken = address(dotc.getConfig(_rewardToken_));
        address pair = IUniswapV2Factory(dotc.getConfig(_swapFactory_)).getPair(
            tokenA,
            rewardToken
        );
        if (pair != address(0)) {
            curBal = IERC20(tokenA).balanceOf(pair);
            tknBal = IERC20(rewardToken).balanceOf(pair);
        }
        uint256 curTgt = IERC20(tokenA)
            .balanceOf(address(this))
            .add(curBal)
            .mul(config[_lpCurMaxRatio_])
            .div(1e18);
        uint256 tknR = config[_lpTknMaxRatio_];
        uint256 tknTgt = IERC20(rewardToken)
            .totalSupply()
            .sub(tknBal)
            .mul(tknR)
            .div(uint256(1e18).sub(tknR));
        if (curBal == 0)
            curTgt = tknTgt
                .mul(dotc.price1())
                .div(1e18)
                .mul(config[_factorPrice20_])
                .div(1e18);
        if (curTgt > curBal && tknTgt > tknBal) {
            uint256 needTkn = tknBal.mul(curTgt).div(curBal).sub(tknBal);
            if (needTkn > (tknTgt - tknBal)) needTkn = (tknTgt - tknBal);
            _addLiquidity(curTgt - curBal, needTkn);
        }
    }

    function _addLiquidity(uint256 value, uint256 amount) internal {
        address rewardToken = address(dotc.getConfig(_rewardToken_));
        IERC20(rewardToken).safeTransferFrom(
            address(dotc.getConfig(_mine_)),
            address(this),
            amount
        );
        address tokenA = address(dotc.getConfig(_pairTokenA_));
        IUniswapV2Router01 router = IUniswapV2Router01(
            dotc.getConfig(_swapRouter_)
        );
        IERC20(tokenA).safeApprove_(address(router), value);
        IERC20(rewardToken).approve(address(router), amount);
        router.addLiquidity(
            tokenA,
            rewardToken,
            value,
            amount,
            0,
            0,
            address(this),
            now
        );
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

interface IDotc {
    function getConfig(bytes32 key) external view returns (uint256);

    function price1() external view returns (uint256);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router01 {
    //function factory() external pure returns (address);
    function WETH() external pure returns (address);

    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}