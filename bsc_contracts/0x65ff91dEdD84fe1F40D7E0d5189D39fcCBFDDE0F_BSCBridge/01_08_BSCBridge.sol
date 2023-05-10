// SPDX-License-Identifier: UNLICENSED

/*
 * "See, I'm a degen of simple tastes. I like memes...and speed...and BSC! And you know they have in common? They're cheap!"
 *
 * https://pepebridge.io
 * https://t.me/OfficialPepeBridge
 *
 */

pragma solidity ^0.8.0;
import "./Bridgebase.sol";
import "hardhat/console.sol";

contract BSCBridge is BridgeBase {
    constructor(address token, address _admin) BridgeBase(token, _admin) {}


    function depositTokens(
        uint256 amount,
        address recipient,
        // uint256 nonce,
        string memory _transactionID
    ) external override {
        address sender = msg.sender;
        require(
            !whiteListOn || isWhiteList[msg.sender],
            "BSCBridge: Forbidden in White List mode"
        );
        // require(
        //     !processedNonces[msg.sender][nonce],
        //     "BSCBridge: transfer already processed"
        // );
        //processedNonces[msg.sender][nonce] = true;
        uint256 AmountwithFees = amount;
       
        nonce[sender] += 1;

        token.burn(sender, AmountwithFees);

        emit TokenDeposit(
            sender,
            recipient,
            AmountwithFees,
            nonce[sender],
            _transactionID
        );
    }

    function withdrawTokens(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external override {
        address sender = msg.sender;
        require(
            !whiteListOn || isWhiteList[sender],
            "BSCBridge: Forbidden in White List mode"
        );

        require(sender == from, "Irrelevant sender");
        address signAddress;
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(from, to, amount, nonce))
        );

        signAddress = recoverSigner(message, signature);

        require(admin == signAddress, "BSCBridge: wrong signature");

        require(
            !processedNonces[sender][nonce],
            "BSCBridge: transfer already processed"
        );
        processedNonces[sender][nonce] = true;

        token.mint(to, amount);

        emit TokenWithdraw(from, to, amount, nonce, signature);
    }
}