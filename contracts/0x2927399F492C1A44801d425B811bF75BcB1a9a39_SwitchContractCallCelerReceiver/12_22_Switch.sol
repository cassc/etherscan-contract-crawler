// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../core/ISwitchView.sol";
import "../core/SwitchRoot.sol";
import "../interfaces/ISwitchEvent.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Switch is SwitchRoot, ReentrancyGuard {
    using UniswapExchangeLib for IUniswapExchange;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    ISwitchView public switchView;
    ISwitchEvent public switchEvent;
    address public reward;
    address public paraswapProxy;
    address public augustusSwapper;
    address public tradeFeeReceiver;
    uint256 public tradeFeeRate;
    mapping (address => uint256) public partnerFeeRates;

    uint256 public constant FEE_BASE = 10000;

    event RewardSet(address reward);
    event SwitchEventSet(address switchEvent);
    event SwitchViewSet(address switchView);
    event PartnerFeeSet(address partner, uint256 feeRate);
    event TradeFeeSet(uint256 tradeFee);
    event TradeFeeReceiverSet(address tradeFeeReceiver);
    event ParaswapProxySet(address paraswapProxy);
    event AugustusSwapperSet(address augustusSwapper);

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper
    ) SwitchRoot(_weth, _otherToken, _pathCount, _pathSplit, _factories)
        public
    {
        switchView = ISwitchView(_switchViewAddress);
        switchEvent = ISwitchEvent(_switchEventAddress);
        paraswapProxy = _paraswapProxy;
        augustusSwapper = _augustusSwapper;
        reward = msg.sender;
    }

    fallback() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function setReward(address _reward) external onlyOwner {
        reward = _reward;
        emit RewardSet(_reward);
    }

    function setSwitchEvent(address _switchEvent) external onlyOwner {
        switchEvent = ISwitchEvent(_switchEvent);
        emit SwitchEventSet(_switchEvent);
    }

    function setSwitchView(address _switchView) external onlyOwner {
        switchView = ISwitchView(_switchView);
        emit SwitchViewSet(_switchView);
    }

    function setParaswapProxy(address _paraswapProxy) external onlyOwner {
        paraswapProxy = _paraswapProxy;
        emit ParaswapProxySet(_paraswapProxy);
    }

    function setAugustusSwapper(address _augustusSwapper) external onlyOwner {
        augustusSwapper = _augustusSwapper;
        emit AugustusSwapperSet(_augustusSwapper);
    }

    function setPartnerFeeRate(address _partner, uint256 _feeRate) external onlyOwner {
        partnerFeeRates[_partner] = _feeRate;
        emit PartnerFeeSet(_partner, _feeRate);
    }

    function setTradeFeeRate(uint256 _tradeFeeRate) external onlyOwner {
        tradeFeeRate = _tradeFeeRate;
        emit TradeFeeSet(_tradeFeeRate);
    }

    function setTradeFeeReceiver(address _tradeFeeReceiver) external onlyOwner {
        tradeFeeReceiver = _tradeFeeReceiver;
        emit TradeFeeReceiverSet(_tradeFeeReceiver);
    }

    function getTokenBalance(address token) external view onlyOwner returns(uint256 amount) {
        amount = IERC20(token).universalBalanceOf(address(this));
    }

    function transferToken(address token, uint256 amount, address recipient) external onlyOwner {
        IERC20(token).universalTransfer(recipient, amount);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        override
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, distribution) = switchView.getExpectedReturn(fromToken, destToken, amount, parts);
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 expectedReturn,
        uint256 minReturn,
        address recipient,
        uint256[] memory distribution
    )
        public
        payable
        nonReentrant
        returns (uint256 returnAmount)
    {
        require(expectedReturn >= minReturn, "expectedReturn must be equal or larger than minReturn");
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts += distribution[i];
                lastNonZeroIndex = i;
            }
        }

        if (parts == 0) {
            if (fromToken.isETH()) {
                payable(msg.sender).transfer(msg.value);
                return msg.value;
            }
            return amount;
        }

        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        returnAmount = _swapInternalForSingleSwap(distribution, amount, parts, lastNonZeroIndex, fromToken, destToken);
        if (returnAmount > 0) {
            require(returnAmount >= minReturn, "Switch: Return amount was not enough");

            if (returnAmount > expectedReturn) {
                destToken.universalTransfer(recipient, expectedReturn);
                destToken.universalTransfer(reward, returnAmount - expectedReturn);
                switchEvent.emitSwapped(msg.sender, recipient, fromToken, destToken, amount, expectedReturn, returnAmount - expectedReturn);
            } else {
                destToken.universalTransfer(recipient, returnAmount);
                switchEvent.emitSwapped(msg.sender, recipient, fromToken, destToken, amount, returnAmount, 0);
            }
        } else {
            if (fromToken.universalBalanceOf(address(this)) > amount) {
                fromToken.universalTransfer(msg.sender, amount);
            } else {
                fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
            }
        }
    }

    function swapWithParaswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 destAmount,
        address recipient,
        bytes memory callData
    )
        public
        payable
        nonReentrant
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }
        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        _callParaswap(fromToken, amount, callData);
        switchEvent.emitSwapped(msg.sender, recipient, fromToken, destToken, amount, destAmount, 0);
    }

    function getFeeInfo(
        uint256 amount,
        address partner
    )
        public
        view
        returns (
            uint256 tradeRate,
            uint256 partnerFeeRate,
            uint256 tradeFee,
            uint256 partnerFee,
            uint256 remainAmount
        )
    {
        tradeRate = tradeFeeRate;
        tradeFee = 0;
        partnerFeeRate = partnerFeeRates[partner];
        partnerFee = 0;
        if (tradeFeeRate > 0) {
            tradeFee = tradeFeeRate * amount / FEE_BASE;
        }
        if (partnerFeeRates[partner] > 0) {
            partnerFee = partnerFeeRates[partner] * amount / FEE_BASE;
        }
        remainAmount = amount - tradeFee - partnerFee;
    }

    function getTradeFee(
        uint256 amount
    )
        public
        view
        returns (
            uint256 feeRate,
            uint256 tradeFee,
            uint256 remainAmount
        )
    {
        feeRate = tradeFeeRate;
        tradeFee = 0;
        if (tradeFeeRate > 0) {
            tradeFee = tradeFeeRate * amount / FEE_BASE;
        }
        remainAmount = amount - tradeFee;
    }

    function getPartnerFee(
        uint256 amount,
        address partner
    )
        public
        view
        returns (
            uint256 feeRate,
            uint256 partnerFee,
            uint256 remainAmount
        )
    {
        feeRate = partnerFeeRates[partner];
        partnerFee = 0;
        if (partnerFeeRates[partner] > 0) {
            partnerFee = partnerFeeRates[partner] * amount / FEE_BASE;
        }
        remainAmount = amount - partnerFee;
    }

    function _swapInternalWithParaSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        bytes memory callData
    )
        internal
        returns (
            uint256 totalAmount
        )
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }

        _callParaswap(fromToken, amount, callData);
        totalAmount = destToken.universalBalanceOf(address(this));
        switchEvent.emitSwapped(msg.sender, address(this), fromToken, destToken, amount, totalAmount, 0);
    }

    function _callParaswap(
        IERC20 token,
        uint256 amount,
        bytes memory callData
    )
        internal
    {
        uint256 ethAmountToTransfert = 0;
        if (token.isETH()) {
            require(address(this).balance >= amount, "ETH balance is insufficient");
            ethAmountToTransfert = amount;
        } else {
            token.universalApprove(paraswapProxy, amount);
        }

        (bool success,) = augustusSwapper.call{ value: ethAmountToTransfert }(callData);
        require(success, "Paraswap execution failed");
    }

    function _swapInternalForSingleSwap(
        uint256[] memory distribution,
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        IERC20 fromToken,
        IERC20 destToken
    )
        internal
        returns (
            uint256 totalAmount
        )
    {
        require(distribution.length <= dexCount*pathCount, "Switch: Distribution array should not exceed factories array size");

        uint256 remainingAmount = amount;
        uint256 swappedAmount = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }
            uint256 swapAmount = amount * distribution[i] / parts;
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            if (i % pathCount == 0) {
                swappedAmount = _swap(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            } else if (i % pathCount == 1) {
                swappedAmount = _swapETH(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            } else {
                swappedAmount = _swapOtherToken(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            }
            totalAmount += swappedAmount;
        }
    }

    function _getAmountAfterFee(
        IERC20 token,
        uint256 amount,
        address partner
    )
        internal
        returns (
            uint256 amountAfterFee
        )
    {
        amountAfterFee = amount;
        if (tradeFeeRate > 0) {
            token.universalTransfer(tradeFeeReceiver, tradeFeeRate * amount / FEE_BASE);
            amountAfterFee = amount - tradeFeeRate * amount / FEE_BASE;
        }
        if (partnerFeeRates[partner] > 0) {
            token.universalTransfer(partner, partnerFeeRates[partner] * amount / FEE_BASE);
            amountAfterFee = amount - partnerFeeRates[partner] * amount / FEE_BASE;
        }
    }

    // Swap helpers
    function _swapInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        if (fromToken.isETH()) {
            weth.deposit{value: amount}();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(0x46Fd07da395799F113a7584563b8cB886F33c2bc);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint160(address(fromTokenReal)) < uint160(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternal(
            midToken,
            destToken,
            _swapInternal(
                fromToken,
                midToken,
                amount,
                factory
            ),
            factory
        );
    }

    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternal(
            fromToken,
            destToken,
            amount,
            factory
        );
    }

    function _swapETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapOverMid(
            fromToken,
            weth,
            destToken,
            amount,
            factory
        );
    }

    function _swapOtherToken(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapOverMid(
            fromToken,
            otherToken,
            destToken,
            amount,
            factory
        );
    }
}