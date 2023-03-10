// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.16;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './ArkenDexTrader.sol';
import '../interfaces/IArkenDexAmbassador.sol';

contract ArkenDexV4 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    address payable public _FEE_WALLET_ADDR_;
    address public _DODO_APPROVE_ADDR_;
    address public _WETH_;
    address public _WETH_DFYN_;
    address public _UNISWAP_V3_FACTORY_;
    address public _WOOFI_QUOTE_TOKEN_;
    address public _ARKEN_DEX_AMBASSADOR_;
    // for proxy reasons, add new variables only after this line

    /*
    ==============================================================================

    █▀▀ █░█ █▀▀ █▄░█ ▀█▀ █▀
    ██▄ ▀▄▀ ██▄ █░▀█ ░█░ ▄█

    ==============================================================================
    */
    event Swapped(
        address indexed srcToken,
        address indexed dstToken,
        uint256 amountIn,
        uint256 returnAmount
    );
    event CollectFee(
        address indexed to,
        address indexed feeToken,
        uint256 feeAmount
    );
    event SwappedStopLimit(
        address indexed srcToken,
        address indexed dstToken,
        uint256 amountIn,
        uint256 returnAmount
    );
    event CollectFeeStopLimit(
        address indexed to,
        address indexed feeToken,
        uint256 feeAmount
    );
    event FeeWalletUpdated(address newFeeWallet);
    event WETHUpdated(address newWETH);
    event WETHDfynUpdated(address newWETHDfyn);
    event DODOApproveUpdated(address newDODOApproveAddress);
    event ArkenApproveUpdated(address newArkenApproveAddress);
    event UniswapV3FactoryUpdated(address newUv3Factory);
    event WooFiQuoteTokenUpdated(address newWooFiQuoteTokenAddress);

    /*
    ==============================================================================

    █▀▀ █▀█ █▄░█ █▀▀ █ █▀▀ █░█ █▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█ █▀
    █▄▄ █▄█ █░▀█ █▀░ █ █▄█ █▄█ █▀▄ █▀█ ░█░ █ █▄█ █░▀█ ▄█

    ==============================================================================
    */
    constructor() initializer {}

    function initialize(
        address _ownerAddress,
        address payable _feeWalletAddress,
        address _weth,
        address _wethDfyn,
        address _dodoApproveAddress,
        address _uniswapV3Factory,
        address _woofiQuoteToken,
        address _dexAmbassador
    ) public initializer {
        __Ownable_init();
        transferOwnership(_ownerAddress);
        __UUPSUpgradeable_init();
        _FEE_WALLET_ADDR_ = _feeWalletAddress;
        _WETH_ = _weth;
        _WETH_DFYN_ = _wethDfyn;
        _DODO_APPROVE_ADDR_ = _dodoApproveAddress;
        _UNISWAP_V3_FACTORY_ = _uniswapV3Factory;
        _WOOFI_QUOTE_TOKEN_ = _woofiQuoteToken;
        _ARKEN_DEX_AMBASSADOR_ = _dexAmbassador;
    }

    fallback() external payable {}

    receive() external payable {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function updateConfig(
        address payable _feeWalletAddress,
        address _weth,
        address _wethDfyn,
        address _dodoApproveAddress,
        address _uniswapV3Factory,
        address _woofiQuoteToken,
        address _dexAmbassador
    ) public onlyOwner {
        _FEE_WALLET_ADDR_ = _feeWalletAddress;
        _WETH_ = _weth;
        _WETH_DFYN_ = _wethDfyn;
        _DODO_APPROVE_ADDR_ = _dodoApproveAddress;
        _UNISWAP_V3_FACTORY_ = _uniswapV3Factory;
        _WOOFI_QUOTE_TOKEN_ = _woofiQuoteToken;
        _ARKEN_DEX_AMBASSADOR_ = _dexAmbassador;
    }

    /*
    ==================================================================================

    ▀█▀ █▀█ ▄▀█ █▀▄ █▀▀ ░   ▀█▀ █▀█ ▄▀█ █▀▄ █▀▀ ░   ▀█▀ █▀█ ▄▀█ █▀▄ █▀▀ ░
    ░█░ █▀▄ █▀█ █▄▀ ██▄ ▄   ░█░ █▀▄ █▀█ █▄▀ ██▄ ▄   ░█░ █▀▄ █▀█ █▄▀ ██▄ ▄

    ==================================================================================
    */

    function trade(ArkenDexTrader.TradeDescription calldata desc)
        external
        payable
    {
        require(desc.amountIn > 0, 'Amount-in needs to be more than zero');
        require(
            desc.amountOutMin > 0,
            'Amount-out minimum needs to be more than zero'
        );
        if (ArkenDexTrader._ETH_ == desc.srcToken) {
            require(
                desc.amountIn == msg.value,
                'Ether value not match amount-in'
            );
            require(
                desc.isRouterSource,
                'Source token Ether requires isRouterSource=true'
            );
        }

        uint256 beforeDstAmt = ArkenDexTrader._getBalance(
            desc.dstToken,
            desc.to
        );

        ArkenDexTrader.TradeData memory data = ArkenDexTrader.TradeData({
            amountIn: desc.amountIn,
            weth: _WETH_
        });
        if (desc.isSourceFee) {
            if (ArkenDexTrader._ETH_ == desc.srcToken) {
                data.amountIn = _collectFee(desc.amountIn, desc.srcToken);
            } else {
                uint256 fee = _calculateFee(desc.amountIn);
                require(fee < desc.amountIn, 'Fee exceeds amount');
                data.amountIn = ArkenDexTrader._transferFromSender(
                    desc.srcToken,
                    _FEE_WALLET_ADDR_,
                    fee,
                    desc.srcToken,
                    data
                );
            }
        }

        uint256 returnAmount = _trade(desc, data);

        if (!desc.isSourceFee) {
            require(
                returnAmount >= desc.amountOutMin && returnAmount > 0,
                'Return amount is not enough'
            );
            returnAmount = _collectFee(returnAmount, desc.dstToken);
        }

        if (returnAmount > 0) {
            if (ArkenDexTrader._ETH_ == desc.dstToken) {
                (bool sent, ) = desc.to.call{value: returnAmount}('');
                require(sent, 'Failed to send Ether');
            } else {
                IERC20(desc.dstToken).safeTransfer(desc.to, returnAmount);
            }
        }

        uint256 receivedAmt = ArkenDexTrader._getBalance(
            desc.dstToken,
            desc.to
        ) - beforeDstAmt;
        require(
            receivedAmt >= desc.amountOutMin,
            'Received token is not enough'
        );

        emit Swapped(desc.srcToken, desc.dstToken, desc.amountIn, receivedAmt);
    }

    function tradeOutside(
        ArkenDexTrader.TradeDescriptionOutside calldata desc,
        bytes calldata interactionDataOutside,
        uint256 valueOutside,
        address targetOutside
    ) external payable {
        require(desc.amountIn > 0, 'Amount-in needs to be more than zero');
        require(
            desc.amountOutMin > 0,
            'Amount-out minimum needs to be more than zero'
        );
        if (ArkenDexTrader._ETH_ == desc.srcToken) {
            require(
                desc.amountIn == msg.value,
                'Ether value not match amount-in'
            );
        }
        ArkenDexTrader.TradeData memory data = ArkenDexTrader.TradeData({
            amountIn: desc.amountIn,
            weth: _WETH_
        });
        if (desc.isSourceFee) {
            if (ArkenDexTrader._ETH_ == desc.srcToken) {
                data.amountIn = _collectFee(desc.amountIn, desc.srcToken);
            } else {
                uint256 fee = _calculateFee(desc.amountIn);
                require(fee < desc.amountIn, 'Fee exceeds amount');
                data.amountIn = ArkenDexTrader._transferFromSender(
                    desc.srcToken,
                    _FEE_WALLET_ADDR_,
                    fee,
                    desc.srcToken,
                    data
                );
            }
        }

        uint256 beforeDstAmtTo = ArkenDexTrader._getBalance(
            desc.dstToken,
            desc.to
        );

        if (ArkenDexTrader._ETH_ != desc.srcToken) {
            SafeERC20.safeTransferFrom(
                IERC20(desc.srcToken),
                msg.sender,
                _ARKEN_DEX_AMBASSADOR_,
                data.amountIn
            );
        }
        IArkenDexAmbassador(_ARKEN_DEX_AMBASSADOR_).tradeWithTarget{
            value: valueOutside
        }(
            desc.srcToken,
            desc.dstToken,
            data.amountIn,
            interactionDataOutside,
            targetOutside
        );
        uint256 returnAmount = ArkenDexTrader._getBalance(
            desc.dstToken,
            address(this)
        );
        require(
            returnAmount > 0,
            'returnAmount from target needs to be more than zero'
        );

        if (!desc.isSourceFee) {
            require(
                returnAmount >= desc.amountOutMin,
                'Return amount is not enough'
            );
            returnAmount = _collectFee(returnAmount, desc.dstToken);
        }

        if (ArkenDexTrader._ETH_ == desc.dstToken) {
            (bool sent, ) = desc.to.call{value: returnAmount}('');
            require(sent, 'Failed to send Ether');
        } else {
            IERC20(desc.dstToken).safeTransfer(desc.to, returnAmount);
        }

        uint256 receivedAmt = ArkenDexTrader._getBalance(
            desc.dstToken,
            desc.to
        ) - beforeDstAmtTo;
        require(
            receivedAmt >= desc.amountOutMin,
            'Received token is not enough'
        );

        emit Swapped(desc.srcToken, desc.dstToken, desc.amountIn, receivedAmt);
    }

    function tradeStopLimit(
        ArkenDexTrader.TradeDescription calldata desc,
        uint256 stopLimitFee,
        uint256 minimumStopLimitFee
    ) external payable {
        require(msg.sender.isContract(), 'Only callable by contracts');
        require(desc.amountIn > 0, 'Amount-in needs to be more than zero');
        require(
            desc.amountOutMin > 0,
            'Amount-out minimum needs to be more than zero'
        );

        ArkenDexTrader.TradeData memory data = ArkenDexTrader.TradeData({
            amountIn: desc.amountIn,
            weth: _WETH_
        });
        if (ArkenDexTrader._ETH_ == desc.srcToken) {
            require(
                desc.amountIn == msg.value,
                'Ether value not match amount-in'
            );
            require(
                desc.isRouterSource,
                'Source token Ether requires isRouterSource=true'
            );
        } else {
            uint256 balanceSrcAmt = ArkenDexTrader._getBalance(
                desc.srcToken,
                msg.sender
            );
            if (balanceSrcAmt < data.amountIn) {
                data.amountIn = balanceSrcAmt;
            }
        }
        // require(stopLimitFee >= 10, 'Fee is too low');
        uint256 beforeDstAmt = ArkenDexTrader._getBalance(
            desc.dstToken,
            desc.to
        );

        if (desc.isSourceFee && stopLimitFee > 0 && minimumStopLimitFee > 0) {
            if (ArkenDexTrader._ETH_ == desc.srcToken) {
                data.amountIn = _collectStopLimitFee(
                    desc.amountIn,
                    desc.srcToken,
                    stopLimitFee,
                    minimumStopLimitFee
                );
            } else {
                uint256 feeAmount = _calculateStopLimitFee(
                    desc.amountIn,
                    stopLimitFee
                );
                if (feeAmount < minimumStopLimitFee) {
                    feeAmount = minimumStopLimitFee;
                }
                require(feeAmount < desc.amountIn, 'Fee exceeds amount');
                data.amountIn = ArkenDexTrader._transferFromSender(
                    desc.srcToken,
                    _FEE_WALLET_ADDR_,
                    feeAmount,
                    desc.srcToken,
                    data
                );
            }
        }
        uint256 returnAmount = _trade(desc, data);

        if (!desc.isSourceFee && stopLimitFee > 0 && minimumStopLimitFee > 0) {
            require(
                returnAmount >= desc.amountOutMin && returnAmount > 0,
                'Return amount is not enough'
            );
            returnAmount = _collectStopLimitFee(
                returnAmount,
                desc.dstToken,
                stopLimitFee,
                minimumStopLimitFee
            );
        }

        if (returnAmount > 0) {
            if (ArkenDexTrader._ETH_ == desc.dstToken) {
                (bool sent, ) = desc.to.call{value: returnAmount}('');
                require(sent, 'Failed to send Ether');
            } else {
                IERC20(desc.dstToken).safeTransfer(desc.to, returnAmount);
            }
        }

        uint256 receivedAmt = ArkenDexTrader._getBalance(
            desc.dstToken,
            desc.to
        ) - beforeDstAmt;
        require(
            receivedAmt >= desc.amountOutMin,
            'Received token is not enough'
        );

        emit SwappedStopLimit(
            desc.srcToken,
            desc.dstToken,
            desc.amountIn,
            receivedAmt
        );
    }

    function _trade(
        ArkenDexTrader.TradeDescription calldata desc,
        ArkenDexTrader.TradeData memory data
    ) internal returns (uint256 returnAmount) {
        if (desc.isRouterSource && ArkenDexTrader._ETH_ != desc.srcToken) {
            data.amountIn = ArkenDexTrader._transferFromSender(
                desc.srcToken,
                address(this),
                data.amountIn,
                desc.srcToken,
                data
            );
        }
        if (ArkenDexTrader._ETH_ == desc.srcToken) {
            ArkenDexTrader._wrapEther(_WETH_, address(this).balance);
        }

        for (uint256 i = 0; i < desc.routes.length; i++) {
            ArkenDexTrader._tradeRoute(
                desc.routes[i],
                desc,
                data,
                _WETH_DFYN_,
                _DODO_APPROVE_ADDR_,
                _WOOFI_QUOTE_TOKEN_
            );
        }

        if (ArkenDexTrader._ETH_ == desc.dstToken) {
            returnAmount = IERC20(_WETH_).balanceOf(address(this));
            ArkenDexTrader._unwrapEther(_WETH_, returnAmount);
        } else {
            returnAmount = IERC20(desc.dstToken).balanceOf(address(this));
        }
    }

    /*

    █▀▄ █▀▀ ▀▄▀
    █▄▀ ██▄ █░█

    */

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        ArkenDexTrader.UniswapV3CallbackData memory data = abi.decode(
            _data,
            (ArkenDexTrader.UniswapV3CallbackData)
        );
        IUniswapV3Pool pool = UniswapV3CallbackValidation.verifyCallback(
            _UNISWAP_V3_FACTORY_,
            data.token0,
            data.token1,
            data.fee
        );
        require(
            address(pool) == msg.sender,
            'UV3Callback: msg.sender is not UniswapV3 Pool'
        );
        if (amount0Delta > 0) {
            IERC20(data.token0).safeTransfer(msg.sender, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            IERC20(data.token1).safeTransfer(msg.sender, uint256(amount1Delta));
        }
    }

    /*

    █▀▀ █▀█ █░░ █░░ █▀▀ █▀▀ ▀█▀   █▀▀ █▀▀ █▀▀
    █▄▄ █▄█ █▄▄ █▄▄ ██▄ █▄▄ ░█░   █▀░ ██▄ ██▄

    */

    function _collectFee(uint256 amount, address token)
        internal
        returns (uint256 remainingAmount)
    {
        uint256 fee = _calculateFee(amount);
        require(fee < amount, 'Fee exceeds amount');
        remainingAmount = amount - fee;
        if (ArkenDexTrader._ETH_ == token) {
            (bool sent, ) = _FEE_WALLET_ADDR_.call{value: fee}('');
            require(sent, 'Failed to send Ether too fee');
        } else {
            IERC20(token).safeTransfer(_FEE_WALLET_ADDR_, fee);
        }
        emit CollectFee(_FEE_WALLET_ADDR_, token, fee);
    }

    function _calculateFee(uint256 amount) internal pure returns (uint256 fee) {
        return amount / 1000;
    }

    function _collectStopLimitFee(
        uint256 amount,
        address token,
        uint256 stopLimitFee,
        uint256 minimumStopLimitFee
    ) internal returns (uint256 remainingAmount) {
        uint256 feeAmount = _calculateStopLimitFee(amount, stopLimitFee);
        if (feeAmount < minimumStopLimitFee) {
            feeAmount = minimumStopLimitFee;
        }
        require(feeAmount < amount, 'Fee exceeds amount');
        remainingAmount = amount - feeAmount;
        if (ArkenDexTrader._ETH_ == token) {
            (bool sent, ) = _FEE_WALLET_ADDR_.call{value: feeAmount}('');
            require(sent, 'Failed to send Ether too fee');
        } else {
            IERC20(token).safeTransfer(_FEE_WALLET_ADDR_, feeAmount);
        }
        emit CollectFeeStopLimit(_FEE_WALLET_ADDR_, token, feeAmount);
    }

    function _calculateStopLimitFee(uint256 amount, uint256 stopLimitFee)
        internal
        pure
        returns (uint256)
    {
        return (amount * stopLimitFee) / 10000;
    }

    /*

    █▀▄ █▀▀ █░█
    █▄▀ ██▄ ▀▄▀

    */
    function testTransfer(ArkenDexTrader.TradeDescription calldata desc)
        external
        payable
        returns (uint256 returnAmount)
    {
        IERC20 dstToken = IERC20(desc.dstToken);
        ArkenDexTrader.TradeData memory data = ArkenDexTrader.TradeData({
            amountIn: desc.amountIn,
            weth: _WETH_
        });
        returnAmount = _trade(desc, data);
        uint256 beforeAmount = dstToken.balanceOf(desc.to);
        dstToken.safeTransfer(desc.to, returnAmount);
        uint256 afterAmount = dstToken.balanceOf(desc.to);
        uint256 got = afterAmount - beforeAmount;
        require(got == returnAmount, 'ArkenTester: Has Tax');
    }
}