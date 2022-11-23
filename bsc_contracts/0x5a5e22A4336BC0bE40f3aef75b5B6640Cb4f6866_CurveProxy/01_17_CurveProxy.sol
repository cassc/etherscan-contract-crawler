// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interfaces/IERC20WithPermit.sol";
import "../bridge/core/CurveProxyCore.sol";
import "../interfaces/IWhitelist.sol";

contract CurveProxy is Initializable, CurveProxyCore, ContextUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    string public versionRecipient;

    function initialize(
        address _forwarder,
        address _portal,
        address _synthesis,
        address _bridge,
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
        whitelist = _whitelist;
        curveBalancer = _curveBalancer;
        treasury = _treasury;
    }

    struct SynthParams {
        address receiveSide;
        address oppositeBridge;
        uint256 chainId;
    }

    struct MetaMintEUSD {
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
    }

    struct MetaRedeemEUSD {
        //crosschain pool params
        address removeAtCrosschainPool;
        //outcome index
        int128 x;
        uint256 expectedMinAmountC;
        //hub pool params
        address removeAtHubPool;
        uint256 tokenAmountH;
        //lp index
        int128 y;
        uint256 expectedMinAmountH;
        //recipient address
        address to;
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

    /**
     * @dev Mint EUSD local case (hub chain only)
     * @param _params MetaMintEUSD params
     * @param tokenParams token address, amount, token index
     */
    function addLiquidity3PoolMintEUSD(MetaMintEUSD calldata _params, ICurveProxy.TokenInput calldata tokenParams)
        external
    {
        require(IWhitelist(whitelist).tokenList(tokenParams.token), "Token must be whitelisted");

        _addLiquidityCrosschainPoolLocal(
            _params.addAtCrosschainPool,
            tokenParams,
            _params.expectedMinMintAmountC,
            _params.to
        );

        uint256 thisBalance = _addLiquidityHubPoolLocal(
            _params.addAtCrosschainPool,
            _params.lpIndex,
            _params.addAtHubPool,
            _params.expectedMinMintAmountH,
            _params.to
        );

        if (thisBalance != 0) {
            IERC20Upgradeable(lpToken[_params.addAtHubPool]).safeTransfer(_params.to, thisBalance);
        }
    }

    /**
     * @dev Mint EUSD from external chains
     * @param _params meta mint EUSD params
     * @param tokenParams token address, amount, token index
     * @param _txId transaction IDs
     */
    function transitSynthBatchAddLiquidity3PoolMintEUSD(
        MetaMintEUSD calldata _params,
        TokenInput calldata tokenParams,
        bytes32 _txId
    ) external onlyBridge {

        _addLiquidityCrosschainPool(
            _params.addAtCrosschainPool,
            tokenParams,
            _txId,
            _params.expectedMinMintAmountC,
            _params.to
        );

        uint256 thisBalance = _addLiquidityHubPool(
            _params.addAtCrosschainPool,
            _params.addAtHubPool,
            _params.expectedMinMintAmountH,
            _params.to,
            _params.lpIndex
        );

        if (thisBalance != 0) {
            IERC20Upgradeable(lpToken[_params.addAtHubPool]).safeTransfer(_params.to, thisBalance);
        }
    }

    /**
     * @dev Meta exchange local case (hub chain execution only)
     * @param _params meta exchange params
     * @param tokenParams token address, amount, token index
     */
    function metaExchange(MetaExchangeParams calldata _params, ICurveProxy.TokenInput calldata tokenParams) external {
        require(IWhitelist(whitelist).tokenList(tokenParams.token), "Token must be whitelisted");

        uint256 thisBalance;
        if (_params.add != address(0)) {
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
            thisBalance = _metaExchangeRemoveStage(_params.remove, _params.x, _params.expectedMinAmount, _params.to);

            if (thisBalance == 0) {
                return;
            }

        } else {
            if (
                _metaExchangeOneTypeLocal(
                    _params.i,
                    _params.j,
                    _params.exchange,
                    _params.expectedMinDy,
                    _params.to,
                    tokenParams.token,
                    tokenParams.amount
                )
            ) {
                return;
            }
            thisBalance = IERC20Upgradeable(pool[_params.remove].at(uint256(int256(_params.x)))).balanceOf(
                address(this)
            );
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

    function removeLiquidity(
        address remove,
        int128 x,
        uint256 expectedMinAmount,
        address to,
        ISynthesis.SynthParams calldata synthParams
    ) external {

        uint256 thisBalance = _metaExchangeRemoveStage(remove, x, expectedMinAmount, to);

        if (thisBalance == 0) {
            return;
        }

        if (synthParams.chainId != 0) {
            IERC20Upgradeable(pool[remove].at(uint256(int256(x)))).approve(synthesis, thisBalance);
            ISynthesis(synthesis).burnSyntheticToken(
                pool[remove].at(uint256(int256(x))),
                thisBalance,
                address(this),
                to,
                synthParams
            );
        } else {
            IERC20Upgradeable(pool[remove].at(uint256(int256(x)))).safeTransfer(to, thisBalance);
        }
    }

    /**
     * @dev Performs a meta exchange on request from external chains
     * @param _params meta exchange params
     * @param tokenParams token address, amount, token index
     * @param _txId synth transaction IDs
     */
    function transitSynthBatchMetaExchange(
        MetaExchangeParams calldata _params,
        TokenInput calldata tokenParams,
        bytes32 _txId
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

    /**
     * @dev Redeem EUSD with unsynth operation (hub chain execution only)
     * @param _params meta redeem EUSD params
     * @param _receiveSide calldata recipient address for unsynth operation
     * @param _oppositeBridge opposite bridge contract address
     * @param _chainId opposite chain ID
     */
    function redeemEUSD(
        MetaRedeemEUSD calldata _params,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainId
    ) external {
        {
            address hubLpToken = lpToken[_params.removeAtHubPool];

            //hub pool remove_liquidity_one_coin stage
            // IERC20Upgradeable(hubLpToken).safeTransferFrom(_msgSender(), address(this), _params.tokenAmountH);
            registerNewBalance(hubLpToken, _params.tokenAmountH);
            // IERC20Upgradeable(hubLpToken).approve(_params.removeAtHubPool, 0); //CurveV2 token support
            IERC20Upgradeable(hubLpToken).approve(_params.removeAtHubPool, _params.tokenAmountH);

            //inconsistency check
            uint256 hubLpTokenBalance = IERC20Upgradeable(hubLpToken).balanceOf(address(this));
            uint256 minAmountsH = IStableSwapPool(_params.removeAtHubPool).calc_withdraw_one_coin(
                _params.tokenAmountH,
                _params.y
            );

            if (_params.expectedMinAmountH > minAmountsH) {
                IERC20Upgradeable(hubLpToken).safeTransfer(_params.to, hubLpTokenBalance);
                emit InconsistencyCallback(_params.removeAtHubPool, hubLpToken, _params.to, hubLpTokenBalance);

                return;
            }
            IStableSwapPool(_params.removeAtHubPool).remove_liquidity_one_coin(_params.tokenAmountH, _params.y, 0);
        }
        {
            //crosschain pool remove_liquidity_one_coin stage
            uint256 hubCoinBalance = IERC20Upgradeable(pool[_params.removeAtHubPool].at(uint256(int256(_params.y))))
                .balanceOf(address(this));
            uint256 min_amounts_c = IStableSwapPool(_params.removeAtCrosschainPool).calc_withdraw_one_coin(
                hubCoinBalance,
                _params.x
            );

            //inconsistency check
            if (_params.expectedMinAmountC > min_amounts_c) {
                IERC20Upgradeable(pool[_params.removeAtCrosschainPool].at(uint256(int256(_params.x)))).safeTransfer(
                    _params.to,
                    hubCoinBalance
                );
                emit InconsistencyCallback(
                    _params.removeAtCrosschainPool,
                    pool[_params.removeAtCrosschainPool].at(uint256(int256(_params.x))),
                    _params.to,
                    hubCoinBalance
                );
                return;
            }

            // IERC20Upgradeable(pool[_params.removeAtCrosschainPool].at(uint256(int256(_params.x)))).approve(_params.removeAtCrosschainPool, 0); //CurveV2 token support
            IERC20Upgradeable(pool[_params.removeAtCrosschainPool].at(uint256(int256(_params.x)))).approve(
                _params.removeAtCrosschainPool,
                hubCoinBalance
            );
            IStableSwapPool(_params.removeAtCrosschainPool).remove_liquidity_one_coin(hubCoinBalance, _params.x, 0);

            //transfer outcome to the recipient (unsynth if mentioned)
            uint256 thisBalance = IERC20Upgradeable(pool[_params.removeAtCrosschainPool].at(uint256(int256(_params.x))))
                .balanceOf(address(this));
            if (_chainId != 0) {
                IERC20Upgradeable(pool[_params.removeAtCrosschainPool].at(uint256(int256(_params.x)))).approve(
                    synthesis,
                    thisBalance
                );
                ISynthesis.SynthParams memory synthParams = ISynthesis.SynthParams(
                    _receiveSide,
                    _oppositeBridge,
                    _chainId
                );
                ISynthesis(synthesis).burnSyntheticToken(
                    pool[_params.removeAtCrosschainPool].at(uint256(int256(_params.x))),
                    thisBalance,
                    address(this),
                    _params.to,
                    synthParams
                );
            } else {
                IERC20Upgradeable(pool[_params.removeAtCrosschainPool].at(uint256(int256(_params.x)))).safeTransfer(
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