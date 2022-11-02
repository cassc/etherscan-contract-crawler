// SPDX-License-Identifier: AGPL-1.0-only

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./crypto_verifysignatures.sol";

/// @custom:security-contact [email protected]
contract Withdrawer is SignatureVerifier, Ownable {
    using SafeERC20 for IERC20;
    mapping(address => uint256) public nonces;
    bool public canWithdraw;

    IERC20 private immutable SUPS;

    constructor(address SUPSAddr, address signer) SignatureVerifier(signer) {
        SUPS = IERC20(SUPSAddr);
    }

    // setCanWithdraw when platform is ready to allow users to transfer
    function setCanWithdraw(bool _canWithdraw) public onlyOwner {
        canWithdraw = _canWithdraw;
        emit SetCanWithdraw(_canWithdraw);
    }

    // devSetSigner updates the signer
    function devSetSigner(address _signer) public onlyOwner {
        setSigner(_signer);
    }

    // flushSUPS returns the SUPS to the owner
    function flushSUPS() public onlyOwner {
        uint256 amt = SUPS.balanceOf(address(this));
        SUPS.safeTransfer(msg.sender, amt);
    }

    // withdrawSUPS will transfer SUPS to the caller if the signature is valid
    function withdrawSUPS(
        uint256 supsAmount,
        bytes calldata signature,
        uint256 expiry
    ) public {
        require(canWithdraw, "withdraws disabled");
        require(expiry > block.timestamp, "signature expired");
        uint256 nonce = nonces[msg.sender]++;
        bytes32 messageHash = getMessageHash(
            msg.sender,
            supsAmount,
            nonce,
            expiry
        );
        require(verify(messageHash, signature), "Invalid Signature");
        require(
            SUPS.balanceOf(address(this)) >= supsAmount,
            "not enough SUPS in hot wallet"
        );
        SUPS.safeTransfer(msg.sender, supsAmount);
        emit WithdrawSUPS(msg.sender, supsAmount, nonce);
    }

    // getMessageHash builds the hash
    function getMessageHash(
        address account,
        uint256 sups,
        uint256 nonce,
        uint256 expiry
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(account, sups, nonce, expiry));
    }

    event WithdrawSUPS(
        address indexed account,
        uint256 supsRecieved,
        uint256 nonce
    );
    event SetCanWithdraw(bool _canWithdraw);
}