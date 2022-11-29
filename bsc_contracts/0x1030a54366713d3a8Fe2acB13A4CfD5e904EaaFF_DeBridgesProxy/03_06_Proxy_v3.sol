// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyWithdrawal.sol";
import "./ProxyUtils.sol";
import "./ProxyFee.sol";

contract DeBridgesProxy is Ownable, ProxyWithdrawal, ProxyFee {

    event ProxyCoinsEvent(address to, uint amount, uint routerAmount, uint systemFee);
    event ProxyTokensEvent(address tokenAddress, uint amount, uint routerAmount, uint systemFee, address approveTo, address callDataTo);

    /**
     * Receive
     */
    receive() external payable {}

    /**
     * Meta proxy
     */
    function metaProxy(address tokenAddress, address approveTo, address callDataTo, bytes memory data) external payable {
        require(ProxyUtils.isContract(callDataTo), "Proxy: call to non-contract");

        if (tokenAddress == address(0)) {
            proxyCoins(callDataTo, data);
        } else {
            proxyTokens(tokenAddress, approveTo, callDataTo, data);
        }
    }

    /**
     * Proxy coins
     */
    function proxyCoins(address to, bytes memory data) internal {
        uint amount = msg.value;
        require(amount > 0, "Proxy: amount is to small");

        uint resultAmount = calcAmount(amount);
        require(resultAmount > 0, "Proxy: resultAmount is to small");

        bool success = true;
        uint feeAmount = calcFee(amount);
        if (feeAmount > 0) {
            (success, ) = payable(owner()).call{value: feeAmount}("");
            require(success, "Proxy: fee not sended");
        }

        (success, ) = to.call{value: resultAmount}(data);
        require(success, "Proxy: transfer not sended");

        emit ProxyCoinsEvent(to, amount, resultAmount, feeAmount);
    }

    /**
     * Proxy tokens
     */
    function proxyTokens(address tokenAddress, address approveTo, address callDataTo, bytes memory data) internal {
        address selfAddress = address(this);
        address fromAddress = msg.sender;

        (bool success, bytes memory result) = tokenAddress.call(
            abi.encodeWithSignature("allowance(address,address)", fromAddress, selfAddress)
        );
        require(success, "Proxy: allowance request failed");
        uint amount = abi.decode(result, (uint));
        require(amount > 0, "Proxy: amount is to small");

        uint routerAmount = calcAmount(amount);
        require(routerAmount > 0, "Proxy: routerAmount is to small");

        (success, ) = tokenAddress.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", fromAddress, selfAddress, amount)
        );
        require(success, "Proxy: transferFrom request failed");

        uint feeAmount = calcFee(amount);
        if (feeAmount > 0) {
            (success, ) = tokenAddress.call(
                abi.encodeWithSignature("transfer(address,uint256)", owner(), feeAmount)
            );
            require(success, "Proxy: fee transfer request failed");
        }

        (success, ) = tokenAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", approveTo, routerAmount)
        );
        require(success, "Proxy: approve request failed");

        (success, ) = callDataTo.call(data);
        require(success, "Proxy: call data request failed");

        emit ProxyTokensEvent(tokenAddress, amount, routerAmount, feeAmount, approveTo, callDataTo);
    }
}