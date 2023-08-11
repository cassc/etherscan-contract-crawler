// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IMultiMerkleStash.sol";
import "./interfaces/IMerkleDistributorV2.sol";
import "./interfaces/IUniV2Router.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IFocusVault.sol";
import "./interfaces/IUniV3Router.sol";
import "./interfaces/ICurveV2Pool.sol";
import "./interfaces/IUncleBondCvx.sol";
import "./interfaces/ILPUncleCvx.sol";
import "./interfaces/IUncleFocusStrategy.sol";
import "./dependencies/ZapBase.sol";

contract UncleClaims is Ownable, ZapBase {
    using SafeERC20 for IERC20;

    address private constant SUSHI_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address private constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNIV3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant CVXCRV_DEPOSIT =
        0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;

    address public UNCLEBOND_CVX;
    address public UNCLE_TOKEN;

    address public LPUNCLE_CVX;

    address public uncleFocusStrategy;
    address public fCvx;

    mapping(uint256 => address) private routers;
    mapping(uint256 => uint24) private fees;

    struct curveSwapParams {
        address pool;
        uint16 ethIndex;
    }

    mapping(address => curveSwapParams) public curveRegistry;

    event FundsRetrieved(address token, address to, uint256 amount);
    event CurvePoolUpdated(address token, address pool);
    event StrategyUpdated(address strategy);
    event UncleFocusCvxUpdated(address pool);

    constructor(
        address _uncleBondCvx,
        address _uncleCvxToken,
        address _lpUncleCvx,
        address _uncleFocusStrategy,
        address _fCvx
    ) {
        routers[0] = SUSHI_ROUTER;
        routers[1] = UNISWAP_ROUTER;
        fees[0] = 3000;
        fees[1] = 10000;

        require(_uncleBondCvx != address(0));
        UNCLEBOND_CVX = _uncleBondCvx;
        require(_uncleCvxToken != address(0));
        UNCLE_TOKEN = _uncleCvxToken;
        require(_lpUncleCvx != address(0));
        LPUNCLE_CVX = _lpUncleCvx;
        require(_uncleFocusStrategy != address(0));
        uncleFocusStrategy = _uncleFocusStrategy;
        require(_fCvx != address(0));
        fCvx = _fCvx;
    }

    /// @notice Add a pool and its swap params to the registry
    /// @param token - Address of the token to swap on Curve
    /// @param params - Address of the pool and WETH index there
    function addCurvePool(
        address token,
        curveSwapParams calldata params
    ) external onlyOwner {
        curveRegistry[token] = params;
        IERC20(token).safeApprove(params.pool, 0);
        IERC20(token).safeApprove(params.pool, type(uint256).max);
        emit CurvePoolUpdated(token, params.pool);
    }

    /// @notice Remove a pool from the registry
    /// @param token - Address of token associated with the pool
    function removeCurvePool(address token) external onlyOwner {
        IERC20(token).safeApprove(curveRegistry[token].pool, 0);
        delete curveRegistry[token];
        emit CurvePoolUpdated(token, address(0));
    }

    /// @notice Change the staking strategy address
    /// @param strategy - Address of the new strategy
    function updateStrategy(address strategy) external onlyOwner {
        require(strategy != address(0));
        uncleFocusStrategy = strategy;
        emit StrategyUpdated(strategy);
    }

    /// @notice Change the Union CVX address in case of a migration
    /// @param fcvx - Address of the new fcvx contract
    function updateFocusAddress(address fcvx) external onlyOwner {
        require(fcvx != address(0));
        fCvx = fcvx;
        emit UncleFocusCvxUpdated(fcvx);
    }

    /// @notice Withdraws specified ERC20 tokens to the multisig
    /// @param tokens - the tokens to retrieve
    /// @param to - address to send the tokens to
    /// @dev This is needed to handle tokens that don't have ETH pairs on sushi
    /// or need to be swapped on other chains (NBST, WormholeLUNA...)
    function retrieveTokens(
        address[] calldata tokens,
        address to
    ) external onlyOwner {
        require(to != address(0));
        for (uint256 i; i < tokens.length; ++i) {
            address token = tokens[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(to, tokenBalance);
            emit FundsRetrieved(token, to, tokenBalance);
        }
    }

    /// @notice Execute calls on behalf of contract in case of emergency
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        return (success, result);
    }

    /// @notice Set approvals for the tokens used when swapping
    function setApprovals() external onlyOwner {
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, type(uint256).max);

        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, type(uint256).max);

        IERC20(CVXCRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(
            CURVE_CVXCRV_CRV_POOL,
            type(uint256).max
        );

        IERC20(CVX_TOKEN).safeApprove(UNCLEBOND_CVX, 0);
        IERC20(CVX_TOKEN).safeApprove(UNCLEBOND_CVX, type(uint256).max);

        IERC20(CVX_TOKEN).safeApprove(LPUNCLE_CVX, 0);
        IERC20(CVX_TOKEN).safeApprove(LPUNCLE_CVX, type(uint256).max);
    }

    /// @notice Swap a token for ETH on Curve
    /// @dev Needs the token to have been added to the registry with params
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    function _swapToETHCurve(address token, uint256 amount) internal {
        curveSwapParams memory params = curveRegistry[token];
        require(params.pool != address(0));
        IERC20(token).safeApprove(params.pool, 0);
        IERC20(token).safeApprove(params.pool, amount);
        ICurveV2Pool(params.pool).exchange_underlying(
            params.ethIndex ^ 1,
            params.ethIndex,
            amount,
            0
        );
    }

    /// @notice Swap a token for ETH
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    /// @dev Swaps are executed via Sushi or UniV2 router, will revert if pair
    /// does not exist. Tokens must have a WETH pair.
    function _swapToETH(
        address token,
        uint256 amount,
        address router
    ) internal {
        require(router != address(0));
        address[] memory _path = new address[](2);
        _path[0] = token;
        _path[1] = WETH;

        IERC20(token).safeApprove(router, 0);
        IERC20(token).safeApprove(router, amount);

        IUniV2Router(router).swapExactTokensForETH(
            amount,
            1,
            _path,
            address(this),
            block.timestamp + 1
        );
    }

    /// @notice Swap a token for ETH on UniSwap V3
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    /// @param fee - the pool's fee
    function _swapToETHUniV3(
        address token,
        uint256 amount,
        uint24 fee
    ) internal {
        IERC20(token).safeApprove(UNIV3_ROUTER, 0);
        IERC20(token).safeApprove(UNIV3_ROUTER, amount);
        IUniV3Router.ExactInputSingleParams memory _params = IUniV3Router
            .ExactInputSingleParams(
                token,
                WETH,
                fee,
                address(this),
                block.timestamp + 1,
                amount,
                1,
                0
            );
        uint256 _wethReceived = IUniV3Router(UNIV3_ROUTER).exactInputSingle(
            _params
        );
        IWETH(WETH).withdraw(_wethReceived);
    }

    /// @notice Claims all specified rewards from the strategy contract
    /// @param epoch - epoch to claim for
    /// @param rewardIndexes - an array containing the info necessary to claim for
    /// each available token
    /// @dev Used to retrieve tokens that need to be transferred
    function claim(
        uint256 epoch,
        uint256[] calldata rewardIndexes
    ) public onlyOwner {
        // claim all from strat
        IUncleFocusStrategy(uncleFocusStrategy).redeemRewards(
            epoch,
            rewardIndexes
        );
    }

    function swap(
        address[] calldata tokens,
        uint256 routerChoices,
        uint256 gasRefund
    ) public onlyOwner {
        // swap all claims to ETH
        for (uint256 i; i < tokens.length; ++i) {
            address _token = tokens[i];
            uint256 _balance = IERC20(_token).balanceOf(address(this));
            // avoid wasting gas / reverting if no balance
            if (_balance <= 1) {
                continue;
            } else {
                // leave one gwei to lower future claim gas costs
                // https://twitter.com/libevm/status/1474870670429360129?s=21
                _balance -= 1;
            }
            // unwrap WETH
            if (_token == WETH) {
                IWETH(WETH).withdraw(_balance);
            } else if (_token == CRV_TOKEN) {
                _crvToEth(_balance, 0);
            } else if (_token == CVXCRV_TOKEN) {
                _swapCrvToEth(_swapCvxCrvToCrv(_balance, address(this)));
            }
            // no need to swap bribes paid out in CVX
            else if (_token == CVX_TOKEN) {
                continue;
            } else {
                uint256 _choice = routerChoices & 7;
                if (_choice >= 4) {
                    _swapToETHCurve(_token, _balance);
                } else if (_choice >= 2) {
                    _swapToETHUniV3(_token, _balance, fees[_choice - 2]);
                } else {
                    _swapToETH(_token, _balance, routers[_choice]);
                }
            }
            routerChoices = routerChoices >> 3;
        }

        (bool success, ) = (tx.origin).call{value: gasRefund}("");
        require(success, "ETH transfer failed");
    }

    function deposit(bool lock, uint256 minAmountOut) public onlyOwner {
        uint256 _ethBalance = address(this).balance;

        // swap from ETH to CVX
        _swapEthToCvx(_ethBalance, 0);

        uint256 _cvxBalance = IERC20(CVX_TOKEN).balanceOf(address(this));

        // swap on Curve if there is a premium for doing so
        if (!lock) {
            ILPUncleCvx(LPUNCLE_CVX).swap(
                ILPUncleCvx.Token.CVX,
                _cvxBalance,
                minAmountOut,
                0,
                1
            );
            IERC20(UNCLE_TOKEN).safeTransfer(
                uncleFocusStrategy,
                IERC20(UNCLE_TOKEN).balanceOf(address(this))
            );
        } else {
            require(_cvxBalance >= minAmountOut, "slippage");
            IUncleBondCvx(UNCLEBOND_CVX).deposit(
                _cvxBalance,
                uncleFocusStrategy,
                false,
                address(0)
            );
        }
        // queue in new rewards
        IUncleFocusStrategy(uncleFocusStrategy).notifyRewardAmount();
    }

    /// @notice Claims all specified rewards and swaps them to ETH
    /// @param epoch - epoch to claim for
    /// @param rewardIndexes - an array containing the info necessary to claim from strat
    /// @param tokens - addresses of all reward tokens
    /// @param routerChoices - the router to use for the swap
    /// @param claimBeforeSwap - whether to claim on Votium or not
    /// @param lock - whether to deposit or swap cvx to pxcvx
    /// @param stake - whether to stake cvxcrv (if distributor is vault)
    /// @param harvest - whether to trigger a harvest
    /// @param minAmountOut - min output amount of cvxCRV or CRV (if locking)
    /// @dev routerChoices is a 3-bit bitmap such that
    /// 0b000 (0) - Sushi
    /// 0b001 (1) - UniV2
    /// 0b010 (2) - UniV3 0.3%
    /// 0b011 (3) - UniV3 1%
    /// 0b100 (4) - Curve
    /// Ex: 136 = 010 001 000 will swap token 1 on UniV3, 2 on UniV3, last on Sushi
    /// Passing 0 will execute all swaps on sushi
    /// @dev claimBeforeSwap is used in case 3rd party already claimed on Votium
    function distribute(
        uint256 epoch,
        uint256[] calldata rewardIndexes,
        address[] calldata tokens,
        uint256 routerChoices,
        bool claimBeforeSwap,
        bool lock,
        bool stake,
        bool harvest,
        uint256 minAmountOut,
        uint256 gasRefund
    ) external onlyOwner {
        // claim
        if (claimBeforeSwap) {
            claim(epoch, rewardIndexes);
        }

        // swap
        swap(tokens, routerChoices, gasRefund);

        // deposit to strategy
        if (stake) {
            deposit(lock, minAmountOut);
        }

        if (harvest) {
            IFocusVault(fCvx).harvest();
        }
    }

    receive() external payable {}
}