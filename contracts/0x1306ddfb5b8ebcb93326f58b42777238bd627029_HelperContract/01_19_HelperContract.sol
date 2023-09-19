// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../dependencies/openzeppelin/upgradeability/Initializable.sol";
import "../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import "../dependencies/openzeppelin/upgradeability/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IPoolCore.sol";
import "../interfaces/IAutoCompoundApe.sol";
import "../interfaces/ICApe.sol";
import {IERC20, SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";

contract HelperContract is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address internal immutable apeCoin;
    address internal immutable cApeV1;
    address internal immutable cApe;
    address internal immutable pcApe;
    address internal immutable lendingPool;

    constructor(
        address _apeCoin,
        address _cApeV1,
        address _cApe,
        address _pcApe,
        address _lendingPool
    ) {
        apeCoin = _apeCoin;
        cApeV1 = _cApeV1;
        cApe = _cApe;
        pcApe = _pcApe;
        lendingPool = _lendingPool;
    }

    function initialize() public initializer {
        __Ownable_init();

        //approve ApeCoin for cApe
        uint256 allowance = IERC20(apeCoin).allowance(address(this), cApe);
        if (allowance == 0) {
            IERC20(apeCoin).safeApprove(cApe, type(uint256).max);
        }

        //approve cApe for lendingPool
        allowance = IERC20(cApe).allowance(address(this), lendingPool);
        if (allowance == 0) {
            IERC20(cApe).safeApprove(lendingPool, type(uint256).max);
        }
    }

    function convertApeCoinToPCApe(uint256 amount) external {
        IERC20(apeCoin).safeTransferFrom(msg.sender, address(this), amount);
        IAutoCompoundApe(cApe).deposit(address(this), amount);
        IPoolCore(lendingPool).supply(cApe, amount, msg.sender, 0);
    }

    function convertPCApeToApeCoin(uint256 amount) external {
        IERC20(pcApe).safeTransferFrom(msg.sender, address(this), amount);
        IPoolCore(lendingPool).withdraw(cApe, amount, address(this));
        IAutoCompoundApe(cApe).withdraw(amount);
        IERC20(apeCoin).safeTransfer(msg.sender, amount);
    }

    function cApeMigration(uint256 amount, address to) external {
        IERC20(cApeV1).safeTransferFrom(msg.sender, address(this), amount);
        IAutoCompoundApe(cApeV1).withdraw(amount);
        IAutoCompoundApe(cApe).deposit(to, amount);
    }
}