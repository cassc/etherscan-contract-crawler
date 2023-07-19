/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8;

contract Bridger {
    address public immutable omnibridge;

    constructor(address omnibridge_) {
        omnibridge = omnibridge_;
    }

    function getAccountAddress(address user) view public returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            bytes32(0),
            keccak256(abi.encodePacked(
                type(BridgeAccount).creationCode,
                abi.encode(user, omnibridge)
            ))
        )))));
    }

    function getAccountBalance(address user, address token) view public returns (uint256) {
        return IERC20(token).balanceOf(getAccountAddress(user));
    }

    function ensureAccount(address user) public returns (BridgeAccount) {
        address accountAddress = getAccountAddress(user);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(accountAddress)
        }

        if (codeSize > 0) {
            return BridgeAccount(accountAddress);
        } else {
            BridgeAccount newAccount = new BridgeAccount{salt: bytes32(0)}(user, omnibridge);
            require(
                accountAddress == address(newAccount),
                "account does not expected deployment address"
            );

            return newAccount;
        }
    }

    function bridge(address user, address token, uint256 amount) public {
        ensureAccount(user).bridge(token, amount);
    }

    function bridgeAll(address user, address token) external {
        bridge(user, token, getAccountBalance(user, token));
    }

    function withdraw(address user, address token, uint256 amount) public {
        ensureAccount(user).withdraw(token, amount);
    }

    function withdrawAll(address user, address token) external {
        withdraw(user, token, getAccountBalance(user, token));
    }
}

contract BridgeAccount {
    address public immutable user;
    address public immutable omnibridge;

    constructor(address user_, address omnibridge_) {
        user = user_;
        omnibridge = omnibridge_;
    }

    function bridge(address token, uint256 amount) external {
        IERC20(token).approve(omnibridge, amount);
        IOmnibridge(omnibridge).relayTokens(token, user, amount);
    }

    function withdraw(address token, uint256 amount) external {
        IERC20(token).transfer(user, amount);
    }
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) view external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IOmnibridge {
    function relayTokens(address token, address receiver, uint256 value) external;
}