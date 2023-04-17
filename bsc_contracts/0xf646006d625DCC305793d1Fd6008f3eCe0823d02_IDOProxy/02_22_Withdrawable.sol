// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../Adminable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

abstract contract Withdrawable is Adminable {
    using SafeERC20 for IERC20;

    bool public fundByTokens = false;
    IERC20 public fundToken;
    uint256 public currencyDecimals = 18;
    address public fundsReceiver;

    event FundTokenChanged(address tokenAddress);
    event FundsReceiverChanged(address account);

    constructor(address _fundToken, address _fundsReceiver) {
        fundByTokens = _fundToken != address(0);
        if (fundByTokens) {
            fundToken = IERC20(_fundToken);
            currencyDecimals = IERC20Metadata(_fundToken).decimals();
        }
        fundsReceiver = _fundsReceiver == address(0) ? msg.sender : _fundsReceiver;
    }

    function setFundToken(address tokenAddress) external onlyOwnerOrAdmin {
        fundByTokens = tokenAddress != address(0);
        fundToken = IERC20(tokenAddress);
        emit FundTokenChanged(tokenAddress);
    }

    function setFundsReceived(address _receiver) external onlyOwnerOrAdmin {
        fundsReceiver = _receiver;
        emit FundsReceiverChanged(_receiver);
    }

    /**
     * Withdraw ALL both BNB and the currency token if specified
     */
    function withdrawAll() external onlyOwnerOrAdmin {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(fundsReceiver).transfer(balance);
        }

        if (fundByTokens && fundToken.balanceOf(address(this)) > 0) {
            fundToken.transfer(fundsReceiver, fundToken.balanceOf(address(this)));
        }
    }

    /**
     * Withdraw the specified amount of BNB or currency token
     */
    function withdrawBalance(uint256 amount) external onlyOwnerOrAdmin {
        require(amount > 0, 'Withdrawable: amount should be greater than zero');
        if (fundByTokens) {
            fundToken.transfer(fundsReceiver, amount);
        } else {
            payable(fundsReceiver).transfer(amount);
        }
    }

    /**
     * When tokens are sent to the sale by mistake: withdraw the specified token.
     */
    function withdrawToken(address token, uint256 amount) external onlyOwnerOrAdmin {
        require(amount > 0, 'Withdrawable: amount should be greater than zero');
        IERC20(token).transfer(fundsReceiver, amount);
    }
}