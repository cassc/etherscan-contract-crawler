/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";
import "@positionex/matching-engine/contracts/libraries/amm/LiquidityMath.sol";

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IPositionNondisperseLiquidity.sol";
import "../interfaces/ISpotFactory.sol";
import "../interfaces/IWBNB.sol";
import "../libraries/helper/LiquidityHelper.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/ISpotFactory.sol";
import {TransferHelper} from "../libraries/helper/TransferHelper.sol";
import "../interfaces/IPositionStakingDexManager.sol";

contract KillerPosition is ReentrancyGuard, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapV2Factory;
    IPositionNondisperseLiquidity public positionLiquidity;
    ISpotFactory public spotFactory;
    IWBNB public WBNB;

    IPositionStakingDexManager public stakingDexManager;

    receive() external payable {
        //        assert(msg.sender == address(uniswapRouter));
        // only accept BNB via fallback from the WBNB contract
    }

    event PositionLiquidityMigrated(
        address user,
        uint256 nftId,
        uint256 liquidityMigrated,
        address lpAddress,
        address pairManager
    );

    constructor(
        IUniswapV2Router02 _uniswapRouter,
        IPositionNondisperseLiquidity _positionLiquidity,
        ISpotFactory _spotFactory,
        IWBNB _WBNB
    ) {
        uniswapRouter = _uniswapRouter;
        positionLiquidity = _positionLiquidity;
        spotFactory = _spotFactory;
        WBNB = _WBNB;
    }

    struct State {
        uint128 currentPip;
        uint32 currentIndexedPipRange;
        address baseToken;
        address quoteToken;
        address pairManager;
        uint256 amount0;
        uint256 amount1;
        uint256 balance0;
        uint256 balance1;
    }

    function approveStaking() public {
        positionLiquidity.setApprovalForAll(address(stakingDexManager), true);
    }

    // TODO remove when testing done
    function updateUniswapRouter(IUniswapV2Router02 _new) external onlyOwner {
        uniswapRouter = _new;
    }

    function updateStakingDexManager(IPositionStakingDexManager _stakingDexManager) external onlyOwner {
        stakingDexManager = _stakingDexManager;
    }


    function updatePositionLiquidity(
        IPositionNondisperseLiquidity _positionLiquidity
    ) external onlyOwner {
        positionLiquidity = _positionLiquidity;
    }

    function updateSpotFactory(ISpotFactory _spotFactory) external onlyOwner {
        spotFactory = _spotFactory;
    }

    function updateWBNB(IWBNB _WBNB) external onlyOwner {
        WBNB = _WBNB;
    }

    function updateUniswapV2Factory(IUniswapV2Factory _uniswapV2Factory)
        external
        onlyOwner
    {
        uniswapV2Factory = _uniswapV2Factory;
    }

    function isToken0Base(IUniswapV2Pair pair) public view returns (bool) {
        (address baseToken, , ) = spotFactory.getPairManagerSupported(
            pair.token0(),
            pair.token1()
        );

        return baseToken == pair.token0();
    }

    function getLpAddress(address matching) public view returns (address) {
        ISpotFactory.Pair memory pair = spotFactory.getQuoteAndBase(matching);
        return uniswapV2Factory.getPair(pair.QuoteAsset, pair.BaseAsset);
    }

    function stake(uint256 ndtId, address user) internal {
        stakingDexManager.stakeAfterMigrate(ndtId, user);
    }

    function migratePosition(IUniswapV2Pair pair, uint256 liquidity)
        public
        nonReentrant
    {
        State memory state;
        address user = _msgSender();

        address token0 = pair.token0();
        address token1 = pair.token1();

        pair.transferFrom(user, address(this), liquidity);
        (state.baseToken, state.quoteToken, state.pairManager) = spotFactory
            .getPairManagerSupported(token0, token1);

        _approve(address(pair), address(uniswapRouter));
        _approve(token0, address(positionLiquidity));
        _approve(token1, address(positionLiquidity));

        state.balance0 = _balanceOf(token0, address(this));
        state.balance1 = _balanceOf(token1, address(this));

        require(state.pairManager != address(0x00), "!0x0");
        if (token0 == address(WBNB) || token1 == address(WBNB)) {
            uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
                token0 == address(WBNB) ? token1 : token0,
                liquidity,
                0,
                0,
                address(this),
                9999999999
            );
        } else {
            uniswapRouter.removeLiquidity(
                token0,
                token1,
                liquidity,
                0,
                0,
                address(this),
                9999999999
            );
        }

        state.amount0 = _balanceOf(token0, address(this)) - state.balance0;
        state.amount1 = _balanceOf(token1, address(this)) - state.balance1;

        state.balance0 = _balanceOf(token0, address(this));
        state.balance1 = _balanceOf(token1, address(this));

        bool _isToken0Base = state.baseToken == pair.token0();

        state.currentIndexedPipRange = uint32(
            IMatchingEngineAMM(state.pairManager).currentIndexedPipRange()
        );
        state.currentPip = IMatchingEngineAMM(state.pairManager)
            .getCurrentPip();

        (uint128 minPip, uint128 maxPip) = LiquidityMath.calculatePipRange(
            state.currentIndexedPipRange,
            IMatchingEngineAMM(state.pairManager).pipRange()
        );

        if (minPip == state.currentPip) {
            uint256 _value;

            if (
                (_isToken0Base && token0 == address(WBNB)) ||
                (!_isToken0Base && token0 == address(WBNB))
            ) {
                _value = state.amount0;
            }

            if (
                (!_isToken0Base && token1 == address(WBNB)) ||
                (_isToken0Base && token1 == address(WBNB))
            ) {
                _value = state.amount1;
            }
            /// add only base
            positionLiquidity.addLiquidityWithRecipient{value: _value}(
                ILiquidityManager.AddLiquidityParams({
                    pool: IMatchingEngineAMM(state.pairManager),
                    amountVirtual: _isToken0Base
                        ? uint128(state.amount0)
                        : uint128(state.amount1),
                    indexedPipRange: state.currentIndexedPipRange,
                    isBase: true
                }),
                address(this)
            );
        } else if (maxPip == state.currentPip) {
            uint256 _value;
            if (
                (_isToken0Base && token0 == address(WBNB)) ||
                (!_isToken0Base && token0 == address(WBNB))
            ) {
                _value = state.amount0;
            }

            if (
                (!_isToken0Base && token1 == address(WBNB)) ||
                (_isToken0Base && token1 == address(WBNB))
            ) {
                _value = state.amount1;
            }

            /// add only quote
            positionLiquidity.addLiquidityWithRecipient{value: _value}(
                ILiquidityManager.AddLiquidityParams({
                    pool: IMatchingEngineAMM(state.pairManager),
                    amountVirtual: _isToken0Base
                        ? uint128(state.amount1)
                        : uint128(state.amount0),
                    indexedPipRange: state.currentIndexedPipRange,
                    isBase: false
                }),
                address(this)
            );
        } else {
            uint128 amountBase;
            uint128 amountQuote;
            state.currentPip = sqrt(uint256(state.currentPip) * 10**18);
            maxPip = sqrt(uint256(maxPip) * 10**18);
            minPip = sqrt(uint256(minPip) * 10**18);
            if (_isToken0Base) {
                (amountBase, amountQuote) = _estimate(
                    uint128(state.amount0),
                    true,
                    state.currentPip,
                    maxPip,
                    minPip,
                    state.pairManager
                );

                if (amountQuote <= state.amount1) {
                    try
                        positionLiquidity.addLiquidityWithRecipient{
                            value: _calculateValue(
                                token0,
                                token1,
                                amountBase,
                                amountQuote,
                                _isToken0Base
                            )
                        }(
                            ILiquidityManager.AddLiquidityParams({
                                pool: IMatchingEngineAMM(state.pairManager),
                                amountVirtual: uint128(state.amount0),
                                indexedPipRange: state.currentIndexedPipRange,
                                isBase: true
                            }),
                            address(this)
                        )
                    {} catch Error(string memory reason) {
                        if (_isCatch(reason)) {
                            amountQuote = (amountQuote * 9990) / 10_000;
                            positionLiquidity.addLiquidityWithRecipient{
                                value: _calculateValue(
                                    token0,
                                    token1,
                                    amountBase,
                                    amountQuote,
                                    _isToken0Base
                                )
                            }(
                                ILiquidityManager.AddLiquidityParams({
                                    pool: IMatchingEngineAMM(state.pairManager),
                                    amountVirtual: uint128(amountQuote),
                                    indexedPipRange: state
                                        .currentIndexedPipRange,
                                    isBase: false
                                }),
                                address(this)
                            );
                        } else revert(reason);
                    }
                } else {
                    (amountBase, amountQuote) = _estimate(
                        uint128(state.amount1),
                        false,
                        state.currentPip,
                        maxPip,
                        minPip,
                        state.pairManager
                    );

                    amountBase = (amountBase * 9990) / 10_000;
                    try
                        positionLiquidity.addLiquidityWithRecipient{
                            value: _calculateValue(
                                token0,
                                token1,
                                amountBase,
                                amountQuote,
                                _isToken0Base
                            )
                        }(
                            ILiquidityManager.AddLiquidityParams({
                                pool: IMatchingEngineAMM(state.pairManager),
                                amountVirtual: amountBase,
                                indexedPipRange: state.currentIndexedPipRange,
                                isBase: true
                            }),
                            address(this)
                        )
                    {} catch Error(string memory reason) {
                        if (_isCatch(reason)) {
                            amountQuote = (amountQuote * 9990) / 10_000;
                            positionLiquidity.addLiquidityWithRecipient{
                                value: _calculateValue(
                                    token0,
                                    token1,
                                    amountBase,
                                    amountQuote,
                                    _isToken0Base
                                )
                            }(
                                ILiquidityManager.AddLiquidityParams({
                                    pool: IMatchingEngineAMM(state.pairManager),
                                    amountVirtual: uint128(amountQuote),
                                    indexedPipRange: state
                                        .currentIndexedPipRange,
                                    isBase: false
                                }),
                                address(this)
                            );
                        } else revert(reason);
                    }
                }
            } else {
                (amountBase, amountQuote) = _estimate(
                    uint128(state.amount1),
                    true,
                    state.currentPip,
                    maxPip,
                    minPip,
                    state.pairManager
                );

                if (amountQuote <= state.amount0) {
                    try
                        positionLiquidity.addLiquidityWithRecipient{
                            value: _calculateValue(
                                token0,
                                token1,
                                amountBase,
                                amountQuote,
                                _isToken0Base
                            )
                        }(
                            ILiquidityManager.AddLiquidityParams({
                                pool: IMatchingEngineAMM(state.pairManager),
                                amountVirtual: uint128(state.amount1),
                                indexedPipRange: state.currentIndexedPipRange,
                                isBase: true
                            }),
                            address(this)
                        )
                    {} catch Error(string memory reason) {
                        if (_isCatch(reason)) {
                            amountQuote = (amountQuote * 9990) / 10_000;
                            positionLiquidity.addLiquidityWithRecipient{
                                value: _calculateValue(
                                    token0,
                                    token1,
                                    amountBase,
                                    amountQuote,
                                    _isToken0Base
                                )
                            }(
                                ILiquidityManager.AddLiquidityParams({
                                    pool: IMatchingEngineAMM(state.pairManager),
                                    amountVirtual: uint128(amountQuote),
                                    indexedPipRange: state
                                        .currentIndexedPipRange,
                                    isBase: false
                                }),
                                address(this)
                            );
                        } else revert(reason);
                    }
                } else {
                    (amountBase, amountQuote) = _estimate(
                        uint128(state.amount0),
                        false,
                        state.currentPip,
                        maxPip,
                        minPip,
                        state.pairManager
                    );

                    amountBase = (amountBase * 9990) / 10_000;

                    try
                        positionLiquidity.addLiquidityWithRecipient{
                            value: _calculateValue(
                                token0,
                                token1,
                                amountBase,
                                amountQuote,
                                _isToken0Base
                            )
                        }(
                            ILiquidityManager.AddLiquidityParams({
                                pool: IMatchingEngineAMM(state.pairManager),
                                amountVirtual: amountBase,
                                indexedPipRange: state.currentIndexedPipRange,
                                isBase: true
                            }),
                            address(this)
                        )
                    {} catch Error(string memory reason) {
                        if (_isCatch(reason)) {
                            amountQuote = (amountQuote * 9990) / 10_000;
                            positionLiquidity.addLiquidityWithRecipient{
                                value: _calculateValue(
                                    token0,
                                    token1,
                                    amountBase,
                                    amountQuote,
                                    _isToken0Base
                                )
                            }(
                                ILiquidityManager.AddLiquidityParams({
                                    pool: IMatchingEngineAMM(state.pairManager),
                                    amountVirtual: uint128(amountQuote),
                                    indexedPipRange: state
                                        .currentIndexedPipRange,
                                    isBase: false
                                }),
                                address(this)
                            );
                        } else revert(reason);
                    }
                }
            }
        }

        _getBack(
            token0,
            uint128(
                state.amount0 -
                    (state.balance0 - _balanceOf(token0, address(this)))
            ),
            user
        );
        _getBack(
            token1,
            uint128(
                state.amount1 -
                    (state.balance1 - _balanceOf(token1, address(this)))
            ),
            user
        );

        stake(positionLiquidity.tokenID(), user);


        emit PositionLiquidityMigrated(
            user,
            positionLiquidity.tokenID(),
            liquidity,
            address(pair),
            state.pairManager
        );
    }

    function _isCatch(string memory reason) internal pure returns (bool) {
        return
            (keccak256(abi.encodePacked((reason))) ==
                keccak256(
                    abi.encodePacked(("ERC20: transfer amount exceeds balance"))
                )) ||
            (keccak256(abi.encodePacked((reason))) ==
                keccak256(abi.encodePacked(("LQ_07"))));
    }

    function sqrt(uint256 number) internal pure returns (uint128) {
        return uint128(Math.sqrt(number));
    }

    function _approve(address token, address spender) internal {
        if (!TransferHelper.isApprove(token, spender)) {
            TransferHelper.approve(token, spender);
        }
    }

    function _calculateValue(
        address _token0,
        address _token1,
        uint128 _amountBase,
        uint128 _amountQuote,
        bool _isToken0Base
    ) internal view returns (uint256 value) {
        if (
            (_token0 == address(WBNB) && _isToken0Base) ||
            (_token1 == address(WBNB) && !_isToken0Base)
        ) {
            value = _amountBase;
        }

        if (
            (_token0 == address(WBNB) && !_isToken0Base) ||
            (_token1 == address(WBNB) && _isToken0Base)
        ) {
            value = _amountQuote;
        }
    }

    function _estimate(
        uint128 amountVirtual,
        bool isBase,
        uint128 currentPip,
        uint128 maxPip,
        uint128 minPip,
        address pair
    ) internal view returns (uint128 amountBase, uint128 amountQuote) {
        if (isBase) {
            amountBase = amountVirtual;
            amountQuote = LiquidityHelper.calculateQuoteVirtualFromBaseReal(
                LiquidityMath.calculateBaseReal(
                    maxPip,
                    amountVirtual,
                    currentPip
                ),
                currentPip,
                minPip,
                uint128(Math.sqrt(IMatchingEngineAMM(pair).basisPoint()))
            );
        } else {
            amountQuote = amountVirtual;
            amountBase =
                LiquidityHelper.calculateBaseVirtualFromQuoteReal(
                    LiquidityMath.calculateQuoteReal(
                        minPip,
                        amountVirtual,
                        currentPip
                    ),
                    currentPip,
                    maxPip
                ) *
                uint128(IMatchingEngineAMM(pair).basisPoint());
        }
    }

    function _msgSender() internal view override(Context) returns (address) {
        return msg.sender;
    }

    function _getBack(
        address token,
        uint128 amount,
        address user
    ) internal {
        if (amount == 0) return;
        if (token == address(WBNB)) {
            payable(user).sendValue(amount);
        } else {
            IERC20(token).transfer(user, amount);
        }
    }

    function _balanceOf(address token, address instance)
        internal
        view
        returns (uint256)
    {
        if (token == address(WBNB)) {
            return instance.balance;
        }
        return IERC20(token).balanceOf(instance);
    }
}