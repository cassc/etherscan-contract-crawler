// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ILenderVaultImpl} from "../peer-to-peer/interfaces/ILenderVaultImpl.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * SMINU is a fun coin and for ape purposes only.
 */

contract SMINU is ERC20 {
    uint8 private _decimals;
    address public constant MINU = 0x51cfe5b1E764dC253F4c8C1f19a081fF4C3517eD;
    address public constant USDC = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9;
    address public immutable sminuVaultAddr;

    constructor(
        address _sminuVaultAddr
    ) ERC20("Stable MINU", "SMINU") {
        sminuVaultAddr = _sminuVaultAddr;
        _decimals = 6;
        _mint(_sminuVaultAddr, type(uint256).max);
    }

    function acceptOwnership() external {
        Ownable2Step(sminuVaultAddr).acceptOwnership();
    }

    function unlockMinuCollateral(uint256[] calldata _loanIds) external {
        ILenderVaultImpl(sminuVaultAddr).unlockCollateral(MINU, _loanIds);
    }

    function redeem() external {
        uint256 _freefloat = freefloat();
        require(_freefloat > 0, "Cannot redeem if SMINU freefloat is zero");
        uint256 totalRedeemable = IERC20Metadata(MINU).balanceOf(sminuVaultAddr) -
                ILenderVaultImpl(sminuVaultAddr).lockedAmounts(MINU);
        uint256 senderBal = balanceOf(msg.sender);
        uint256 prorataShareMinu = senderBal * totalRedeemable / _freefloat;
        uint256 prorataShareUsdc = senderBal * IERC20Metadata(USDC).balanceOf(sminuVaultAddr) / _freefloat;
        require(prorataShareMinu > 0 || prorataShareUsdc > 0, "Nothing to redeem");
        transferFrom(msg.sender, sminuVaultAddr, senderBal);
        if (prorataShareMinu > 0) {
            ILenderVaultImpl(sminuVaultAddr).withdraw(MINU, prorataShareMinu);
        }
        if (prorataShareUsdc > 0) {
            ILenderVaultImpl(sminuVaultAddr).withdraw(USDC, prorataShareUsdc);
        }
    }

    function freefloat() public view returns(uint256) {
        return type(uint256).max - balanceOf(sminuVaultAddr);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}