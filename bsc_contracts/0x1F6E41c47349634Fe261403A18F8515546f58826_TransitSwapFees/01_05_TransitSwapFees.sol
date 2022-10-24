// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./libraries/TransferHelper.sol";

contract TransitSwapFees is Ownable {

    using SafeMath for uint256;

    bool private _support_discount;
    mapping(uint8 => mapping(string => uint256)) private _fees;
    address[] private _support_tokens;
    //gradient
    uint256[] private _gradient_threshold;
    uint256[] private _gradient_discount;

    event SupportDiscount(bool newSupport);
    event SetupTokens(address[] tokens);
    event SetupFees(uint8[] swapType, uint256[] feeRate, string[] channel);
    event SetupGradient(uint256[] threshold, uint256[] discount);
    event Withdraw(address indexed token, address indexed executor, address indexed recipient, uint amount);
    
    constructor(address executor) Ownable (executor) {
        _support_discount = true;
    }

    function supportDiscount() public view returns (bool) {
        return _support_discount;
    }

    /**
     * @dev Returns the channel of the fees.
     */
    function fees(uint8 swapType, string memory channel) public view returns (uint256) {
        return _fees[swapType][channel];
    }

    function changeSupportDiscount() public onlyExecutor {
        emit SupportDiscount(_support_discount);
        _support_discount = !_support_discount;
    }

    function setupTokens(address[] memory tokens) public onlyExecutor {
        _support_tokens = tokens;
        emit SetupTokens(tokens);
    }

    function setupFees(uint8[] memory swapType, uint256[] memory feeRate, string[] memory channel) public onlyExecutor {
        require(swapType.length == feeRate.length, "TransitSwap: invalid data");
        require(swapType.length == channel.length, "TransitSwap: invalid data");
        for(uint256 index; index < swapType.length; index++) {
            _fees[swapType[index]][channel[index]] = feeRate[index];
        }
        emit SetupFees(swapType, feeRate, channel);
    }

    function setupGradient(uint256[] memory gradientThreshold, uint256[] memory gradientDiscount) public onlyExecutor {
        _gradient_threshold = gradientThreshold;
        _gradient_discount = gradientDiscount;
        emit SetupGradient(gradientThreshold, gradientDiscount);
    }

    /**
     * @dev Returns the swap of the current fees.
     */
    function getFeeRate(address trader, uint256 tradeAmount, uint8 swapType, string memory channel) public view returns (uint payFees) {
        uint256 feeRate = _fees[swapType][channel];
        if (feeRate == 0) {
            feeRate = _fees[swapType]["default"];
            require(feeRate > 0, "TransitSwap: invalid swapType");
        }
        if(feeRate == 1) {
            payFees = 0;
        } else {
            uint256 normalPayFees = tradeAmount.mul(feeRate).div(10000);
            payFees = normalPayFees;
            if (_support_discount) {
                uint256 sumTokenBalance;
                for (uint256 index; index < _support_tokens.length; index++) {
                    if (_support_tokens[index] != address(0)) {
                        sumTokenBalance = sumTokenBalance.add(IERC20(_support_tokens[index]).balanceOf(trader));
                    }
                }
                for (uint256 index; index < _gradient_threshold.length; index++) {
                    if (sumTokenBalance < _gradient_threshold[index]) {
                        payFees = normalPayFees.mul(_gradient_discount[index]).div(10000);
                        break;
                    }
                }
            }
        }
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