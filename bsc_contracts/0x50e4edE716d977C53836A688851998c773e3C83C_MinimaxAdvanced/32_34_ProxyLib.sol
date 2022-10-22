// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/RevertLib.sol";
import "../ProxyCaller.sol";
import "../IProxyOwner.sol";
import "../pool/IPoolAdapter.sol";
import "./IToken.sol";

library ProxyLib {
    function deposit(
        IProxyOwner owner,
        ProxyCaller proxy,
        IPoolAdapter adapter,
        address pool,
        bytes memory poolArgs,
        uint256 amount
    ) public {
        (bool success, bytes memory data) = owner.proxyExec(
            proxy,
            true, /* delegate */
            address(adapter), /* target */
            abi.encodeWithSignature("deposit(address,uint256,bytes)", pool, amount, poolArgs) /* data */
        );

        RevertLib.propagateError(success, data, "deposit");
    }

    function withdraw(
        IProxyOwner owner,
        ProxyCaller proxy,
        IPoolAdapter adapter,
        address pool,
        bytes memory poolArgs,
        uint256 amount
    ) public {
        (bool success, bytes memory data) = owner.proxyExec(
            proxy,
            true, /* delegate */
            address(adapter), /* target */
            abi.encodeWithSignature("withdraw(address,uint256,bytes)", pool, amount, poolArgs) /* data */
        );

        RevertLib.propagateError(success, data, "withdraw");
    }

    function withdrawAll(
        IProxyOwner owner,
        ProxyCaller proxy,
        IPoolAdapter adapter,
        address pool,
        bytes memory poolArgs
    ) public {
        (bool success, bytes memory data) = owner.proxyExec(
            proxy,
            true, /* delegate */
            address(adapter), /* target */
            abi.encodeWithSignature("withdrawAll(address,bytes)", pool, poolArgs) /* data */
        );

        RevertLib.propagateError(success, data, "withdrawAll");
    }

    function stakeBalance(
        IProxyOwner owner,
        ProxyCaller proxy,
        IPoolAdapter adapter,
        address pool,
        bytes memory poolArgs
    ) public returns (uint256) {
        (bool success, bytes memory data) = owner.proxyExec(
            proxy,
            true, /* delegate */
            address(adapter), /* target */
            abi.encodeWithSignature("stakingBalance(address,bytes)", pool, poolArgs) /* data */
        );

        RevertLib.propagateError(success, data, "stakeBalance");

        return abi.decode(data, (uint256));
    }

    function rewardBalances(
        IProxyOwner owner,
        ProxyCaller proxy,
        IPoolAdapter adapter,
        address pool,
        bytes memory poolArgs
    ) public returns (uint256[] memory) {
        (bool success, bytes memory data) = owner.proxyExec(
            proxy,
            true, /* delegate */
            address(adapter), /* target */
            abi.encodeWithSignature("rewardBalances(address,bytes)", pool, poolArgs) /* data */
        );

        RevertLib.propagateError(success, data, "rewardBalances");

        return abi.decode(data, (uint256[]));
    }

    function approve(
        IProxyOwner owner,
        ProxyCaller proxy,
        IToken token,
        address destination,
        uint amount
    ) public {
        (bool success, bytes memory data) = owner.proxyExec(
            proxy,
            false, /* delegate */
            address(token), /* target */
            abi.encodeWithSignature("approve(address,uint256)", destination, amount) /* data */
        );

        RevertLib.propagateError(success, data, "approve");
        require(abi.decode(data, (bool)), "approve");
    }

    function transfer(
        IProxyOwner owner,
        ProxyCaller proxy,
        IToken token,
        address destination,
        uint256 amount
    ) public {
        (bool success, bytes memory data) = owner.proxyExec(
            proxy,
            false, /* delegate */
            address(token), /* target */
            abi.encodeWithSignature("transfer(address,uint256)", destination, amount) /* data */
        );
        RevertLib.propagateError(success, data, "transfer");
    }

    function transferAll(
        IProxyOwner owner,
        ProxyCaller proxy,
        IToken token,
        address destination
    ) public returns (uint256) {
        uint256 amount = token.balanceOf(address(proxy));
        if (amount > 0) {
            transfer(owner, proxy, token, destination, amount);
        }
        return amount;
    }
}