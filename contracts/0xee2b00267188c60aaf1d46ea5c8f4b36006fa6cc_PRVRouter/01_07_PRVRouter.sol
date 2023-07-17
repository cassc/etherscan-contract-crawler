// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";
import {IERC20Permit} from "@oz/token/ERC20/extensions/IERC20Permit.sol";
import "@oz/token/ERC20/IERC20.sol";
import "@interfaces/IPRV.sol";
import "@interfaces/IRollStaker.sol";

contract PRVRouter {
    using SafeERC20 for IERC20;

    address public immutable AUXO;
    address public immutable PRV;
    address public immutable Staker;

    constructor(address _auxo, address _prv, address _staker) {
        AUXO = _auxo;
        PRV = _prv;
        Staker = _staker;
    }

    function convertAndStake(uint256 amount) external {
        IERC20(AUXO).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(AUXO).approve(PRV, amount);
        IPRV(PRV).depositFor(address(this), amount);

        IERC20(PRV).approve(Staker, amount);
        IRollStaker(Staker).depositFor(amount, msg.sender);
    }

    function convertAndStake(uint256 amount, address _receiver) external {
        IERC20(AUXO).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(AUXO).approve(PRV, amount);
        IPRV(PRV).depositFor(address(this), amount);

        IERC20(PRV).approve(Staker, amount);
        IRollStaker(Staker).depositFor(amount, _receiver);
    }

    function convertAndStakeWithSignature(
        uint256 amount,
        address _receiver,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20Permit(AUXO).permit(msg.sender, address(this), amount, _deadline, v, r, s);
        IERC20(AUXO).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(AUXO).approve(PRV, amount);
        IPRV(PRV).depositFor(address(this), amount);

        IERC20(PRV).approve(Staker, amount);
        IRollStaker(Staker).depositFor(amount, _receiver);
    }
}