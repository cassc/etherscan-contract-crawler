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

contract ETHBridge is BridgeBase {
    constructor(address token, address _admin) BridgeBase(token, _admin) {}

    uint256 nonce_count;

    function depositTokens(
        uint256 amount,
        address recipient,
        // uint256 nonce,
        string memory _transactionID
    ) external override {
        address sender = msg.sender;
        require(
            !whiteListOn || isWhiteList[sender],
            "ETHBridge: Forbidden in White List mode"
        );

        // require(
        //     !processedNonces[msg.sender][nonce],
        //     "ETH Bridge: transfer already processed"
        // );
        //processedNonces[msg.sender][nonce] = true;

        uint256 balBeforeTrans = token.balanceOf(address(this));
        
        nonce[sender] += 1;

        token.transferFrom(sender, address(this), amount);
        

        uint256 balAfterTrans = token.balanceOf(address(this));

        uint256 transAmount = balAfterTrans - balBeforeTrans;
        emit TokenDeposit(
            sender,
            recipient,
            transAmount,
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
        require(
            !whiteListOn || isWhiteList[msg.sender],
            "ETHBridge: Forbidden in White List mode"
        );
        
        require(msg.sender == from, "Irrelevant sender");
        address signAddress;


        bytes32 message = prefixed(
            keccak256(abi.encodePacked(from, to, amount, nonce))
        );

        signAddress = recoverSigner(message, signature);

        require(admin == signAddress, "ETH Bridge: wrong signature");

        uint256 adminBal = token.balanceOf(address(this));
        require(
            adminBal >= amount,
            "ETH Bridge: insuffient funds in admin account."
        );

        require(
            !processedNonces[msg.sender][nonce],
            "ETHBridge: transfer already processed"
        );
        processedNonces[msg.sender][nonce] = true;

       
        token.transfer(to, amount);
        emit TokenWithdraw(from, to, amount, nonce, signature);
    }
}