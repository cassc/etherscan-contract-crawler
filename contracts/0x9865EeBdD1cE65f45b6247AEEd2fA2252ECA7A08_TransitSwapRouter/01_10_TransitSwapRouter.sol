// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/ReentrancyGuard.sol";
import "./libraries/RevertReasonParser.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/TransitStructs.sol";
import "./libraries/Ownable.sol";
import "./libraries/Pausable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITransitSwapFees.sol";

contract TransitSwapRouter is Ownable, ReentrancyGuard, Pausable {

    using SafeMath for uint256;

    address private _transit_swap;
    address private _transit_cross;
    address private _transit_fees;
    //default: Pre-trade fee model
    mapping(uint8 => bool) private _swap_type_mode;

    event Receipt(address from, uint256 amount);
    event Withdraw(address indexed token, address indexed executor, address indexed recipient, uint amount);
    event ChangeTransitSwap(address indexed previousTransit, address indexed newTransit);
    event ChangeTransitCross(address indexed previousTransit, address indexed newTransit);
    event ChangeTransitFees(address indexed previousTransitFees, address indexed newTransitFees);
    event ChangeSwapTypeMode(uint8[] types, bool[] newModes);
    event TransitSwapped(address indexed srcToken, address indexed dstToken, address indexed dstReceiver, address trader, bool feeMode, uint256 amount, uint256 returnAmount, uint256 minReturnAmount, uint256 fee, uint256 toChainID, string channel, uint256 time);


    constructor(address transitSwap_, address transitCross_, address transitFees_, address executor) Ownable (executor) {
        _transit_swap = transitSwap_;
        _transit_cross = transitCross_;
        _transit_fees = transitFees_;
    }

    receive() external payable {
        emit Receipt(msg.sender, msg.value);
    }

    function transitSwap() external view returns (address) {
        return _transit_swap;
    }

    function transitCross() external view returns (address) {
        return _transit_cross;
    }

    function transitFees() external view returns (address) {
        return _transit_fees;
    }

    function swapTypeMode(uint8 swapType) external view returns (bool) {
        return _swap_type_mode[swapType];
    }

    function changeTransitSwap(address newTransit) external onlyExecutor {
        address oldTransit = _transit_swap;
        _transit_swap = newTransit;
        emit ChangeTransitSwap(oldTransit, newTransit);
    }

    function changeTransitCross(address newTransit) external onlyExecutor {
        address oldTransit = _transit_cross;
        _transit_cross = newTransit;
        emit ChangeTransitCross(oldTransit, newTransit);
    }

    function changeTransitFees(address newTransitFees) external onlyExecutor {
        address oldTransitFees = _transit_fees;
        _transit_fees = newTransitFees;
        emit ChangeTransitFees(oldTransitFees, newTransitFees);
    }

    function changeSwapTypeMode(uint8[] memory swapTypes) external onlyExecutor {
        bool[] memory newModes = new bool[](swapTypes.length);
        for (uint index; index < swapTypes.length; index++) {
            _swap_type_mode[swapTypes[index]] = !_swap_type_mode[swapTypes[index]];
            newModes[index] = _swap_type_mode[swapTypes[index]];
        }
        emit ChangeSwapTypeMode(swapTypes, newModes);
    }

    function changePause(bool paused) external onlyExecutor {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function _beforeSwap(bool preTradeModel, TransitStructs.TransitSwapDescription calldata desc) private returns (uint256 swapAmount, uint256 fee, uint256 beforeBalance) {
        if (preTradeModel) {
            fee = ITransitSwapFees(_transit_fees).getFeeRate(msg.sender, desc.amount, desc.swapType, desc.channel);
        }
        if (TransferHelper.isETH(desc.srcToken)) {
            require(msg.value == desc.amount, "TransitSwap: invalid msg.value");
            swapAmount = desc.amount.sub(fee);
        } else {
            if (preTradeModel) {
                TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, address(this), desc.amount);
                TransferHelper.safeTransfer(desc.srcToken, desc.srcReceiver, desc.amount.sub(fee));
            } else {
                TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, desc.srcReceiver, desc.amount);
            }
        }
        if (TransferHelper.isETH(desc.dstToken)) {
            if (preTradeModel) {
                beforeBalance = desc.dstReceiver.balance;
            } else {
                if (desc.swapType == uint8(TransitStructs.SwapTypes.swap)) {
                    beforeBalance = IERC20(desc.wrappedNative).balanceOf(address(this));
                } else {
                    beforeBalance = address(this).balance;
                }
            }
        } else {
            if (preTradeModel) {
                beforeBalance = IERC20(desc.dstToken).balanceOf(desc.dstReceiver);
            } else {
                beforeBalance = IERC20(desc.dstToken).balanceOf(address(this));
            }
        }
    }

    function _afterSwap(bool preTradeModel, TransitStructs.TransitSwapDescription calldata desc, uint256 beforeBalance) private returns (uint256 returnAmount, uint256 fee) {
        if (TransferHelper.isETH(desc.dstToken)) {
            if (preTradeModel) {
                returnAmount = desc.dstReceiver.balance.sub(beforeBalance);
                require(returnAmount >= desc.minReturnAmount, "TransitSwap: insufficient return amount");
            } else {
                if (desc.swapType == uint8(TransitStructs.SwapTypes.swap)) {
                    returnAmount = IERC20(desc.wrappedNative).balanceOf(address(this)).sub(beforeBalance);
                    TransferHelper.safeWithdraw(desc.wrappedNative, returnAmount);
                } else {
                    returnAmount = address(this).balance.sub(beforeBalance);
                }
                fee = ITransitSwapFees(_transit_fees).getFeeRate(msg.sender, returnAmount, desc.swapType, desc.channel);
                returnAmount = returnAmount.sub(fee);
                require(returnAmount >= desc.minReturnAmount, "TransitSwap: insufficient return amount");
                TransferHelper.safeTransferETH(desc.dstReceiver, returnAmount);
            }
        } else {
            if (preTradeModel) {
                returnAmount = IERC20(desc.dstToken).balanceOf(desc.dstReceiver).sub(beforeBalance);
                require(returnAmount >= desc.minReturnAmount, "TransitSwap: insufficient return amount");
            } else {
                returnAmount = IERC20(desc.dstToken).balanceOf(address(this)).sub(beforeBalance);
                fee = ITransitSwapFees(_transit_fees).getFeeRate(msg.sender, returnAmount, desc.swapType, desc.channel);
                returnAmount = returnAmount.sub(fee);
                uint256 receiverBeforeBalance = IERC20(desc.dstToken).balanceOf(desc.dstReceiver);
                TransferHelper.safeTransfer(desc.dstToken, desc.dstReceiver, returnAmount);
                returnAmount = IERC20(desc.dstToken).balanceOf(desc.dstReceiver).sub(receiverBeforeBalance);
                require(returnAmount >= desc.minReturnAmount, "TransitSwap: insufficient return amount");
            }
        }        
    }

    function swap(TransitStructs.TransitSwapDescription calldata desc, TransitStructs.CallbytesDescription calldata callbytesDesc) external payable nonReentrant whenNotPaused {
        require(callbytesDesc.calldatas.length > 0, "TransitSwap: data should be not zero");
        require(desc.amount > 0, "TransitSwap: amount should be greater than 0");
        require(desc.dstReceiver != address(0), "TransitSwap: receiver should be not address(0)");
        require(desc.minReturnAmount > 0, "TransitSwap: minReturnAmount should be greater than 0");
        if (callbytesDesc.flag == uint8(TransitStructs.Flag.aggregate)) {
            require(desc.srcToken == callbytesDesc.srcToken, "TransitSwap: invalid callbytesDesc");
        }
        bool preTradeModel = !_swap_type_mode[desc.swapType];
        (uint256 swapAmount, uint256 fee, uint256 beforeBalance) = _beforeSwap(preTradeModel, desc);

        {
            //bytes4(keccak256(bytes('callbytes(TransitStructs.CallbytesDescription)')));
            (bool success, bytes memory result) = _transit_swap.call{value:swapAmount}(abi.encodeWithSelector(0xccbe4007, callbytesDesc));
            if (!success) {
                revert(RevertReasonParser.parse(result,"TransitSwap:"));
            }
        }

        (uint256 returnAmount, uint256 postFee) = _afterSwap(preTradeModel, desc, beforeBalance);
        if (postFee > fee) {
            fee = postFee;
        }
        _emitTransit(desc, preTradeModel, fee, returnAmount);
    }

    function _beforeCross(TransitStructs.TransitSwapDescription calldata desc) private returns (uint256 swapAmount, uint256 fee, uint256 beforeBalance) {
        fee = ITransitSwapFees(_transit_fees).getFeeRate(msg.sender, desc.amount, desc.swapType, desc.channel);
        if (TransferHelper.isETH(desc.srcToken)) {
            require(msg.value == desc.amount, "TransitSwap: invalid msg.value");
            swapAmount = desc.amount.sub(fee);
        } else {
            beforeBalance = IERC20(desc.srcToken).balanceOf(_transit_cross);
            if (fee == 0) {
                TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, _transit_cross, desc.amount);
            } else {
                TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, address(this), desc.amount);
                TransferHelper.safeTransfer(desc.srcToken, _transit_cross, desc.amount.sub(fee));
            }
        }
    }

    function cross(TransitStructs.TransitSwapDescription calldata desc, TransitStructs.CallbytesDescription calldata callbytesDesc) external payable nonReentrant whenNotPaused {
        require(callbytesDesc.calldatas.length > 0, "TransitSwap: data should be not zero");
        require(desc.amount > 0, "TransitSwap: amount should be greater than 0");
        require(desc.srcToken == callbytesDesc.srcToken, "TransitSwap: invalid callbytesDesc");
        (uint256 swapAmount, uint256 fee, uint256 beforeBalance) = _beforeCross(desc);
        
        {
            //bytes4(keccak256(bytes('callbytes(TransitStructs.CallbytesDescription)')));
            (bool success, bytes memory result) = _transit_cross.call{value:swapAmount}(abi.encodeWithSelector(0xccbe4007, callbytesDesc));
            if (!success) {
                revert(RevertReasonParser.parse(result,"TransitSwap:"));
            }
        }
        
        if (!TransferHelper.isETH(desc.srcToken)) {
            require(IERC20(desc.srcToken).balanceOf(_transit_cross) >= beforeBalance, "TransitSwap: invalid cross");
        }

        _emitTransit(desc, true, fee, 0);
    }

    function _emitTransit(TransitStructs.TransitSwapDescription calldata desc, bool preTradeModel, uint256 fee, uint256 returnAmount) private {
        emit TransitSwapped(
            desc.srcToken, 
            desc.dstToken, 
            desc.dstReceiver, 
            msg.sender, 
            preTradeModel, 
            desc.amount, 
            returnAmount, 
            desc.minReturnAmount, 
            fee, 
            desc.toChainID, 
            desc.channel,
            block.timestamp
        );
    }

    function withdrawTokens(address[] memory tokens, address recipient) external onlyExecutor {
        for(uint index; index < tokens.length; index++) {
            uint amount;
            if(TransferHelper.isETH(tokens[index])) {
                amount = address(this).balance;
                TransferHelper.safeTransferETH(recipient, amount);
            } else {
                amount = IERC20(tokens[index]).balanceOf(address(this));
                TransferHelper.safeTransferWithoutRequire(tokens[index], recipient, amount);
            }
            emit Withdraw(tokens[index], msg.sender, recipient, amount);
        }
    }
}