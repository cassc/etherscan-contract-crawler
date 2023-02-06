// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {LockedXMON} from "./LockedXMON.sol";
import {ILockDrop} from "./interfaces/ILockDrop.sol";
import {ISudoToken} from "./interfaces/ISudoToken.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract wSUDO is ERC20, Owned {
    using SafeTransferLib for ERC20;

    ILockDrop public constant lockDrop = ILockDrop(0xadA31F59e70AD18665380f21CE49d4C43F9865c2);

    ERC20 public immutable oldToken;

    address public immutable newToken;

    LockedXMON public immutable lockedNewToken;

    bool public unlocked;

    constructor() ERC20("WRAPPED SUDO", "wSUDO", ERC20(lockDrop.newToken()).decimals()) Owned(msg.sender) {
        ERC20 _oldToken = ERC20(lockDrop.oldToken());
        oldToken = _oldToken;
        newToken = lockDrop.newToken();
        lockedNewToken = new LockedXMON(_oldToken.decimals());
    }

    function delegate(address delegatee) external onlyOwner {
        ISudoToken(newToken).delegate(delegatee);
    }

    function lock(uint256 oldTokenAmount, address recipient) external returns (uint256 newTokenAmount) {
        if (oldTokenAmount == 0) {
            return 0;
        }

        require(!unlocked, "UNLOCKED");

        ERC20(oldToken).safeTransferFrom(msg.sender, address(this), oldTokenAmount);

        ERC20(oldToken).approve(address(lockDrop), oldTokenAmount);

        newTokenAmount = lockDrop.lock(oldTokenAmount, address(this));

        lockedNewToken.mint(recipient, oldTokenAmount);

        _mint(recipient, newTokenAmount);
    }

    function unlock() external returns (uint256 oldTokenAmount) {
        require(!unlocked, "UNLOCKED");

        oldTokenAmount = lockDrop.unlock(address(this));

        unlocked = true;
    }

    function unlock(uint256 oldTokenAmount, address recipient) external {
        require(unlocked, "LOCKED");

        if (oldTokenAmount == 0) {
            return;
        }

        lockedNewToken.burn(msg.sender, oldTokenAmount);

        oldToken.safeTransfer(recipient, oldTokenAmount);
    }

    function swap(uint256 newTokenAmount, address recipient) external {
        if (newTokenAmount == 0) {
            return;
        }

        _burn(msg.sender, newTokenAmount);

        ERC20(newToken).safeTransfer(recipient, newTokenAmount);
    }
}