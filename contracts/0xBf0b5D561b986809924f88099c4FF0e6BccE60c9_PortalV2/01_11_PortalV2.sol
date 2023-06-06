// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EndPoint.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IAddressBook.sol";


contract PortalV2 is EndPoint, Ownable {

    /// @dev fee denominator
    uint256 public constant FEE_DENOMINATOR = 10000;
    /// @dev locked balances
    mapping(address => uint256) public balanceOf;

    event Locked(address token, uint256 amount, address from, address to);
    event Unlocked(address token, uint256 amount, address from, address to);

    modifier checkAmount(uint256 amount, address token) {
        address whitelist = IAddressBook(addressBook).whitelist();
        require(
            amount >= IWhitelist(whitelist).tokenMin(token) && amount <= IWhitelist(whitelist).tokenMax(token),
            "Portal: wrong amount"
        );
        _;
    }

    modifier onlyRouter() {
        address router = IAddressBook(addressBook).router(uint64(block.chainid));
        require(router == msg.sender, "Portal: router only");
        _;
    }

    constructor (address addressBook_) EndPoint(addressBook_) {}

    /**
     * @dev Sets address book.
     *
     * Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
     *
     * @param addressBook_ address book contract address.
     */
    function setAddressBook(address addressBook_) external onlyOwner {
        _setAddressBook(addressBook_);
    }

    /**
     * @dev Lock token.
     *
     * @param token token address to synthesize;
     * @param amount amount to synthesize;
     * @param from sender address;
     * @param to receiver address.
     */
    function lock(
        address token,
        uint256 amount,
        address from,
        address to
    ) external onlyRouter checkAmount(amount, token) {
        address whitelist = IAddressBook(addressBook).whitelist();
        require(IWhitelist(whitelist).tokenState(token) == uint8(IWhitelist.TokenState.InOut), "Portal: token must be whitelisted");
        _updateBalance(token, amount);
        emit Locked(token, amount, from, to);
    }

    /**
     * @dev Unlock. Can be called only by router after initiation on a second chain.
     *
     * @param otoken token address to unsynth;
     * @param amount amount to unsynth;
     * @param from sender address;
     * @param to recipient address.
     */
    function unlock(
        address otoken,
        uint256 amount,
        address from,
        address to
    ) external onlyRouter returns (uint256 amountOut) {
        IAddressBook addressBookImpl = IAddressBook(addressBook);
        address whitelist = addressBookImpl.whitelist();
        address treasury = addressBookImpl.treasury();
        require(IWhitelist(whitelist).tokenState(otoken) == uint8(IWhitelist.TokenState.InOut), "Portal: token must be whitelisted");

        uint256 feeAmount = amount * IWhitelist(whitelist).bridgeFee(otoken) / FEE_DENOMINATOR;
        amountOut = amount - feeAmount;
        SafeERC20.safeTransfer(IERC20(otoken), to, amountOut);
        SafeERC20.safeTransfer(IERC20(otoken), treasury, feeAmount);
        balanceOf[otoken] -= amount;

        emit Unlocked(otoken, amount, from, to);
    }

    /**
     * @dev Emergency unlock. Can be called only by router after initiation on opposite chain.
     *
     * @param otoken token address to unsynth;
     * @param amount amount to unsynth;
     * @param from sender address;
     * @param to recipient address.
     */
    function emergencyUnlock(
        address otoken,
        uint256 amount,
        address from,
        address to
    ) external onlyRouter returns (uint256 amountOut) {
        address whitelist = IAddressBook(addressBook).whitelist();
        require(IWhitelist(whitelist).tokenState(otoken) == uint8(IWhitelist.TokenState.InOut), "Portal: token must be whitelisted");

        amountOut = amount;
        SafeERC20.safeTransfer(IERC20(otoken), to, amountOut);
        balanceOf[otoken] -= amount;

        emit Unlocked(otoken, amount, from, to);
    }

    function _updateBalance(address token, uint256 expectedAmount) private {
        uint256 oldBalance = balanceOf[token];
        require(
            (IERC20(token).balanceOf(address(this)) - oldBalance) >= expectedAmount,
            "Portal: insufficient balance"
        );
        balanceOf[token] += expectedAmount;
    }
}