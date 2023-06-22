// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IDigitalReserve.sol";

contract DigitalReserveWithdrawal {
    using SafeMath for uint256;

    constructor(address _drcAddress) public {
        drcToken = IERC20(_drcAddress);
    }

    IERC20 private immutable drcToken;

    function withdrawPercentage(
        address _digitalReserve,
        uint8 percentage,
        uint256 minAmountOut,
        uint32 deadline
    ) external {
        require(percentage <= 100, "Attempt to withdraw more than 100% of the asset");

        IDigitalReserve digitalReserve = IDigitalReserve(_digitalReserve);
        IERC20 drPod = IERC20(_digitalReserve);
        uint256 drPodToWithdraw = drPod.balanceOf(msg.sender).mul(percentage).div(100);

        require(drPod.allowance(msg.sender, address(this)) >= drPodToWithdraw, "Contract is not allowed to spend user's DR-POD.");

        (, uint256 amountOut, ) = digitalReserve.getUserVaultInDrc(msg.sender, percentage);
        require(amountOut >= minAmountOut, "The amount of DRC can withdraw is lower than reqested");

        SafeERC20.safeTransferFrom(drPod, msg.sender, address(this), drPodToWithdraw);

        digitalReserve.withdrawPercentage(100, deadline);

        SafeERC20.safeTransfer(drcToken, msg.sender, drcToken.balanceOf(address(this)));
    }
}