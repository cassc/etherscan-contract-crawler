// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../child/IChildERC20.sol";
import "./IL2StateReceiver.sol";

interface IChildMintableERC20Predicate is IL2StateReceiver {
    event MintableERC20Deposit(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 amount
    );
    event MintableERC20Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 amount
    );
    event MintableTokenMapped(address indexed rootToken, address indexed childToken);

    function initialize(
        address newL2StateSender,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate
    ) external;

    function withdraw(IChildERC20 childToken, uint256 amount) external;

    function withdrawTo(IChildERC20 childToken, address receiver, uint256 amount) external;
}