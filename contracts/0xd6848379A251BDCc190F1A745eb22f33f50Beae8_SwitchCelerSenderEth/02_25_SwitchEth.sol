// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../ISwitchView.sol";
import "../interfaces/ISwitchEvent.sol";
import "./SwitchRootEth.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwitchEth is SwitchRootEth {
    using UniswapExchangeLib for IUniswapExchange;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    ISwitchView public switchView;
    ISwitchEvent public switchEvent;
    address public reward;
    address public owner;
    address private paraswapProxy;
    address private augustusSwapper;
    address public tradeFeeReceiver;
    uint256 public tradeFeeRate;
    mapping (address => uint256) public partnerFeeRates;

    uint256 public constant FEE_BASE = 10000;

    event RewardSet(address reward);
    event SwitchEventSet(ISwitchEvent switchEvent);
    event OwnerSet(address owner);
    event PartnerFeeSet(address partner, uint256 feeRate);
    event TradeFeeSet(uint256 tradeFee);
    event TradeFeeReceiverSet(address tradeFeeReceiver);
    event ParaswapProxySet(address paraswapProxy);
    event AugustusSwapperSet(address augustusSwapper);
    
    constructor(
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper
    )
        public
    {
        switchView = ISwitchView(_switchViewAddress);
        switchEvent = ISwitchEvent(_switchEventAddress);
        paraswapProxy = _paraswapProxy;
        augustusSwapper = _augustusSwapper;
        reward = msg.sender;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    fallback() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function setReward(address _reward) external onlyOwner {
        reward = _reward;
        emit RewardSet(_reward);
    }

    function setSwitchEvent(ISwitchEvent _switchEvent) external onlyOwner {
        switchEvent = _switchEvent;
        emit SwitchEventSet(_switchEvent);
    }

    function setParaswapProxy(address _paraswapProxy) external onlyOwner {
        paraswapProxy = _paraswapProxy;
	emit ParaswapProxySet(_paraswapProxy);
    }

    function setAugustusSwapper(address _augustusSwapper) external onlyOwner {
        augustusSwapper = _augustusSwapper;
	emit AugustusSwapperSet(_augustusSwapper);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerSet(_owner);
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

    function transferToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).universalTransfer(owner, amount);
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
        // break function to avoid stack too deep error
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
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }
        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        //Check if this contract have enough token or allowance
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
        IERC20 fromToken,
        uint256 amount,
        bytes memory callData
    )
        internal
    {
        uint256 ethAmountToTransfert = 0;
        if (fromToken.isETH()) {
            require(address(this).balance >= amount, "ETH balance is insufficient");
            ethAmountToTransfert = amount;
        } else {
            uint256 approvedAmount = fromToken.allowance(address(this), paraswapProxy);
            if (approvedAmount < amount) {
                fromToken.safeIncreaseAllowance(paraswapProxy, amount - approvedAmount);
            }
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
        require(distribution.length <= DEXES_COUNT*PATHS_COUNT, "Switch: Distribution array should not exceed factories array size");

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
            if (i % PATHS_COUNT == 0) {
                swappedAmount = _swap(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/PATHS_COUNT]));
            } else {
                swappedAmount = _swapETH(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/PATHS_COUNT]));
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
            exchange.skim(0xBdB82D89731De719CAe1171C1Fa999E8c13ce77A);
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
}