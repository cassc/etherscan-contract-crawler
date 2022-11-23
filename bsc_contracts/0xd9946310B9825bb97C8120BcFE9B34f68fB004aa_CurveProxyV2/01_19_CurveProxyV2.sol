// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./IStableSwapPool.sol";
import "../interfaces/IERC20WithPermit.sol";
import "../interfaces/ISynthesis.sol";
import "../IUniswapV2Router01.sol";
import "../UniswapV2Library.sol";
import "../interfaces/IPortal.sol";
import "../interfaces/ICurveProxy.sol";
import "../bridge/core/CurveProxyCore.sol";
import "../interfaces/IWhitelist.sol";

contract CurveProxyV2 is Initializable, CurveProxyCore, ContextUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    string public versionRecipient;
    address public uniswapRouter;
    address public uniswapFactory;

    function initialize(
        address _forwarder,
        address _portal,
        address _synthesis,
        address _bridge,
        address _uniswapRouter,
        address _uniswapFactory,
        address _whitelist,
        address _curveBalancer,
        address _treasury
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        portal = _portal;
        synthesis = _synthesis;
        bridge = _bridge;
        versionRecipient = "2.2.3";
        uniswapRouter = _uniswapRouter;
        uniswapFactory = _uniswapFactory;
        whitelist = _whitelist;
        curveBalancer = _curveBalancer;
        treasury = _treasury;
    }

    struct SynthParams {
        address receiveSide;
        address oppositeBridge;
        uint256 chainId;
    }

    struct MetaMintEUSDWithSwap {
        //crosschain pool params
        address addAtCrosschainPool;
        uint256 expectedMinMintAmountC;
        //incoming coin index for adding liq to hub pool
        uint256 lpIndex;
        //hub pool params
        address addAtHubPool;
        uint256 expectedMinMintAmountH;
        //recipient address
        address to;
        uint256 amountOutMin;
        address path;
        uint256 deadline;
    }

    struct MetaExchangeParams {
        //pool address
        address add;
        address exchange;
        address remove;
        //add liquidity params
        uint256 expectedMinMintAmount;
        //exchange params
        int128 i; //index value for the coin to send
        int128 j; //index value of the coin to receive
        uint256 expectedMinDy;
        //withdraw one coin params
        int128 x; //index value of the coin to withdraw
        uint256 expectedMinAmount;
        //transfer to
        address to;
        //unsynth params
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        uint256 chainId;
    }

    modifier onlyBridge() {
        require(bridge == msg.sender);
        _;
    }
 
    /**
     * @dev Set the corresponding pool data to use proxy with
     * @param _pool pool address
     * @param _lpToken lp token address for the corresponding pool
     * @param _coins listed token addresses
     */
    function setPool(
        address _pool,
        address _lpToken,
        address[] calldata _coins
    ) public onlyOwner {
        for (uint256 i = 0; i < _coins.length; i++) {
            pool[_pool].add(_coins[i]);
        }
        lpToken[_pool] = _lpToken;
    }

    function inconsistencySwapCheck(
        uint256 _balance,
        address[] memory _path,
        uint256 _amountOutMin
    ) internal view returns (bool _result) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(uniswapFactory, _balance, _path);
        _result = amounts[1] < _amountOutMin;
    }

    function inconsistencyAddLiquidityCheck(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) internal view returns (bool _result) {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(uniswapFactory, _tokenA, _tokenB);
        if (reserveA == 0 && reserveB == 0) {
            _result = true;
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(_amountADesired, reserveA, reserveB);
            if (amountBOptimal <= _amountBDesired) {
                _result = amountBOptimal < _amountBMin;
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(_amountBDesired, reserveB, reserveA);
                if (amountAOptimal <= _amountADesired) {
                    _result = amountAOptimal < _amountAMin;
                } else {
                    _result = false;
                }
            }
        }
    }

    function transitSynthBatchMetaExchangeWithSwap(
        ICurveProxy.MetaExchangeParams calldata _params,
        TokenInput calldata tokenParams,
        bytes32 _txId,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthParamsMetaSwap calldata _synthParams
    ) external onlyBridge {
        uint256 thisBalance;

        if (_params.add != address(0)) {

            _addLiquidityCrosschainPool(
                _params.add,
                tokenParams,
                _txId,
                _params.expectedMinMintAmount,
                _params.to
            );

            if (
                _metaExchangeSwapStage(
                    _params.add,
                    _params.exchange,
                    _params.i,
                    _params.j,
                    _params.expectedMinDy,
                    _params.to
                )
            ) {
                return;
            }

            thisBalance = _metaExchangeRemoveStage(_params.remove, _params.x, _params.expectedMinAmount, _params.to);

            if (thisBalance == 0) {
                return;
            }
        } else {
            if (
                _metaExchangeOneType(
                    _params.i,
                    _params.j,
                    _params.exchange,
                    _params.expectedMinDy,
                    _params.to,
                    tokenParams.token,
                    tokenParams.amount,
                    _txId
                )
            ) {
                return;
            }
            thisBalance = IERC20Upgradeable(pool[_params.remove].at(uint256(int256(_params.x)))).balanceOf(
                address(this)
            );
        }
        //transfer asset to the recipient (unsynth if mentioned)
        if (_params.chainId != 0) {
            IERC20Upgradeable(pool[_params.remove].at(uint256(int256(_params.x)))).approve(synthesis, thisBalance);
            ISynthesis.SynthParams memory synthParams = ISynthesis.SynthParams(
                _params.receiveSide,
                _params.oppositeBridge,
                _params.chainId
            );
            ISynthesis(synthesis).burnSyntheticTokenWithSwap(
                pool[_params.remove].at(uint256(int256(_params.x))),
                thisBalance,
                address(this),
                _params.to,
                synthParams,
                _synthParams,
                _finalSynthParams
            );
        } else {
            tokenSwap(_synthParams, _finalSynthParams, thisBalance);
        }
    }

    function tokenSwap(
        IPortal.SynthParamsMetaSwap calldata _synthParams,
        IPortal.SynthParams calldata _finalSynthParams,
        uint256 _amount
    ) public {
        address[] memory path = new address[](2);
        path[0] = _synthParams.swappedToken;
        path[1] = _synthParams.path;

        //inconsistency
        if (inconsistencySwapCheck(_amount, path, _synthParams.amountOutMin)) {
            IERC20Upgradeable(_synthParams.swappedToken).safeTransfer(_synthParams.to, _amount);
            emit InconsistencyCallback(uniswapRouter, _synthParams.swappedToken, _synthParams.to, _amount);
            return;
        }

        IERC20Upgradeable(_synthParams.swappedToken).approve(uniswapRouter, _amount);

        if (_finalSynthParams.chainId != 0) {
            IUniswapV2Router01(uniswapRouter).swapExactTokensForTokens(
                _amount,
                _synthParams.amountOutMin,
                path,
                address(this),
                _synthParams.deadline
            );
            uint256 swappedBalance = IERC20Upgradeable(_synthParams.path).balanceOf(address(this));
            IERC20Upgradeable(_synthParams.path).safeTransfer(portal, swappedBalance);
            IPortal(portal).synthesize(
                _synthParams.path,
                swappedBalance,
                _synthParams.from,
                _synthParams.to,
                _finalSynthParams
            );
        } else {
            IUniswapV2Router01(uniswapRouter).swapExactTokensForTokens(
                _amount,
                _synthParams.amountOutMin,
                path,
                _synthParams.to,
                _synthParams.deadline
            );
        }
    }

    function tokenSwapLite(
        address tokenToSwap,
        address to,
        uint256 amountOutMin,
        address tokenToReceive,
        uint256 deadline,
        address from,
        uint256 amount,
        uint256 fee,
        address worker,
        IPortal.SynthParams calldata _finalSynthParams
    ) public {
        require(IWhitelist(whitelist).tokenList(tokenToSwap), "Token must be whitelisted");
        require(IWhitelist(whitelist).tokenList(tokenToReceive), "Token must be whitelisted");

        address[] memory path = new address[](2);
        path[0] = tokenToSwap;
        path[1] = tokenToReceive;

        //inconsistency
        if (inconsistencySwapCheck(amount, path, amountOutMin)) {
            IERC20Upgradeable(tokenToSwap).safeTransfer(to, amount);
            emit InconsistencyCallback(uniswapRouter, tokenToSwap, to, amount);
            return;
        }

        IERC20Upgradeable(tokenToSwap).approve(uniswapRouter, amount);

        IUniswapV2Router01(uniswapRouter).swapExactTokensForTokens(amount, amountOutMin, path, address(this), deadline);

        if (fee != 0) {
            IERC20Upgradeable(tokenToReceive).safeTransfer(worker, fee);
        }

        uint256 swappedBalance = IERC20Upgradeable(tokenToReceive).balanceOf(address(this));
        if (_finalSynthParams.chainId != 0) {
            IERC20Upgradeable(tokenToReceive).safeTransfer(portal, swappedBalance);
            IPortal(portal).synthesize(tokenToReceive, swappedBalance, from, to, _finalSynthParams);
        } else {
            IERC20Upgradeable(tokenToReceive).safeTransfer(to, swappedBalance);
        }
    }

    function changeRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = _uniswapRouter;
    }

    function changeFactory(address _uniswapFactory) external onlyOwner {
        uniswapFactory = _uniswapFactory;
    }

    function tokenSwapWithMetaExchange(
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _synthParams,
        ICurveProxy.FeeParams memory _feeParams
    ) external {
        require(IWhitelist(whitelist).tokenList(_exchangeParams.token), "Token must be whitelisted");
        require(IWhitelist(whitelist).tokenList(_exchangeParams.tokenToSwap), "Token must be whitelisted");

        address[] memory path = new address[](2);

        path[1] = _exchangeParams.token;
        path[0] = _exchangeParams.tokenToSwap;

        //inconsistency
        if (inconsistencySwapCheck(_exchangeParams.amountToSwap, path, _exchangeParams.amountOutMin)) {
            IERC20Upgradeable(_exchangeParams.tokenToSwap).safeTransfer(_params.to, _exchangeParams.amountToSwap);
            emit InconsistencyCallback(
                uniswapRouter,
                _exchangeParams.tokenToSwap,
                _params.to,
                _exchangeParams.amountToSwap
            );
            return;
        }

        IERC20Upgradeable(_exchangeParams.tokenToSwap).approve(uniswapRouter, _exchangeParams.amountToSwap);
        IUniswapV2Router01(uniswapRouter).swapExactTokensForTokens(
            _exchangeParams.amountToSwap,
            _exchangeParams.amountOutMin,
            path, // Received Token -> Desired Token
            address(this),
            _exchangeParams.deadline
        );
        if (_feeParams.fee != 0) {
            IERC20Upgradeable(_exchangeParams.token).safeTransfer(_feeParams.worker, _feeParams.fee);
        }
        uint256 swappedBalance = IERC20Upgradeable(_exchangeParams.token).balanceOf(address(this));
        ICurveProxy.TokenInput memory tokenParams = ICurveProxy.TokenInput(
            _exchangeParams.token,
            swappedBalance,
            _feeParams.coinIndex
        );
        if (_synthParams.chainId != 0) {
            IERC20Upgradeable(_exchangeParams.token).safeTransfer(portal, swappedBalance);
            IPortal(portal).synthBatchMetaExchange(_exchangeParams.from, _synthParams, _params, tokenParams);
        } else {

            _addLiquidityCrosschainPoolLocal(_params.add, tokenParams, _params.expectedMinMintAmount, _params.to);
        
            //meta-exchange stage
            if (
                _metaExchangeSwapStage(
                    _params.add,
                    _params.exchange,
                    _params.i,
                    _params.j,
                    _params.expectedMinDy,
                    _params.to
                )
            ) {
                return;
            }
            //transfer asset to the recipient (unsynth if mentioned)
            uint256 thisBalance = _metaExchangeRemoveStage(
                _params.remove,
                _params.x,
                _params.expectedMinAmount,
                _params.to
            );

            if (thisBalance == 0) {
                return;
            }

            if (_params.chainId != 0) {
                IERC20Upgradeable(pool[_params.remove].at(uint256(int256(_params.x)))).approve(synthesis, thisBalance);
                ISynthesis.SynthParams memory synthParams = ISynthesis.SynthParams(
                    _params.receiveSide,
                    _params.oppositeBridge,
                    _params.chainId
                );
                ISynthesis(synthesis).burnSyntheticToken(
                    pool[_params.remove].at(uint256(int256(_params.x))),
                    thisBalance,
                    address(this),
                    _params.to,
                    synthParams
                );
            } else {
                IERC20Upgradeable(pool[_params.remove].at(uint256(int256(_params.x)))).safeTransfer(
                    _params.to,
                    thisBalance
                );
            }
        }
    }

    function setWhitelist(address _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }

    function setCurveBalancer(address _curveBalancer) external onlyOwner {
        curveBalancer = _curveBalancer;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

}