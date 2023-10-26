// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IPowerTONSwapperEvent.sol";
import "../interfaces/IAutoCoinageSnapshot.sol";
import {ILockTOSDividend} from "../interfaces/ILockTOSDividend.sol";

import "../../common/AccessiblePowerTon.sol";
import "./PowerTONSwapperStorage.sol";
import {PowerTONHammerDAOStorage} from "./PowerTONHammerDAOStorage.sol";


contract PowerTONUpgrade is
    PowerTONSwapperStorage,
    AccessiblePowerTon,
    IPowerTONSwapperEvent,
    PowerTONHammerDAOStorage
{

    function setAutocoinageSnapshot(address _autocoinageSnapshot)
        external
        onlyOwner
    {
        autocoinageSnapshot = _autocoinageSnapshot;
    }

    function setSeigManager(address _seigManager)
        external
        onlyOwner
    {
        seigManager = _seigManager;
    }

    /// @notice PowerTON으로 쌓인 WTON 전체를 LockTOSDividendProxy 컨트랙트에 위임
    function approveToDividendPool() private {
        IERC20(wton).approve(address(dividiedPool), type(uint256).max);
    }

    /// @notice LockTOSDividendProxy 컨트랙트를 사용해서 WTON을 sTOS 홀더에게 에어드랍
    function distribute() external {
        uint256 wtonBalance = getWTONBalance();
        require(wtonBalance > 0, "balance of WTON is 0");

        // WTON 잔고보다 allowance가 낮으면 최대 값으로 위임 재설정
        if (
            wtonBalance >
            IERC20(wton).allowance(address(this), address(dividiedPool))
        ) {
            approveToDividendPool();
        }

        dividiedPool.distribute(wton, wtonBalance);
        emit Distributed(wton, wtonBalance);
    }

    function getWTONBalance() public view returns (uint256) {
        return IERC20(wton).balanceOf(address(this));
    }

    function onDeposit(
        address layer2,
        address account,
        uint256 amount
    ) external  {

    }

    function onWithdraw(
        address layer2,
        address account,
        uint256 amount
    ) external  {

    }

    function updateSeigniorage(
        uint256 amount
    ) external  {

    }
}