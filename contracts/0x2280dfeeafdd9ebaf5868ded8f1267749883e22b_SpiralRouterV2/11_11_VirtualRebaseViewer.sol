// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStaking {
    struct Epoch {
        uint256 length;
        uint256 number;
        uint256 endBlock;
        uint256 apr;
    }

    function epoch() external view returns (Epoch memory);
    function index() external view returns (uint256);
    /* function stakedCoil() external view returns(uint256); */
}

interface IVirtualRebaseViewer {
    function epoch() external view returns (IStaking.Epoch memory);
    function nextRebaseAt() external view returns (uint256);
    function pendingIndex() external view returns (uint256, uint256);
    function pendingCoil() external view returns (uint256);
    function allInOne() external view returns (uint256, uint256, uint256, uint256);
}

contract VirtualRebaseViewer is IVirtualRebaseViewer {
    address private constant staking = address(0x6701E792b7CD344BaE763F27099eEb314A4b4943);
    address private constant spiral = address(0x85b6ACaBa696B9E4247175274F8263F99b4B9180);
    address private constant coil = address(0x823E1B82cE1Dc147Bbdb25a203f046aFab1CE918);
    uint256 private constant initialIndex = 10 ** 18;
    uint256 private constant blocksPerYear = 2628000;
    uint256 private constant aprBase = 10000;

    constructor() {}

    function epoch() external view returns (IStaking.Epoch memory) {
        return IStaking(staking).epoch();
    }

    function nextRebaseAt() external view returns (uint256) {
        (,, uint256 endBlock,) = _virtualRebase();
        return endBlock;
    }

    function pendingIndex() external view returns (uint256, uint256) {
        (uint256 pendingRebasesCount, uint256 futureIndex,,) = _virtualRebase();
        return (pendingRebasesCount, futureIndex);
    }

    function pendingCoil() external view returns (uint256) {
        (,,, uint256 stakedCoil) = _virtualRebase();
        return stakedCoil;
    }

    function allInOne() external view returns (uint256, uint256, uint256, uint256) {
        return _virtualRebase();
    }

    function _virtualRebase()
        internal
        view
        returns (uint256 pendingRebasesCount, uint256 futureIndex, uint256 endBlock, uint256 stakedCoil)
    {
        IStaking.Epoch memory epoch = IStaking(staking).epoch();
        futureIndex = IStaking(staking).index();
        /* stakedCoil = IStaking(staking).stakedCoil(); */
        stakedCoil = IERC20(coil).balanceOf(staking);
        uint256 totalSpiral = IERC20(spiral).totalSupply();

        while (epoch.endBlock <= block.number) {
            pendingRebasesCount++;
            futureIndex = futureIndex + ((epoch.apr * futureIndex * epoch.length) / blocksPerYear / aprBase);
            epoch.endBlock = epoch.endBlock + epoch.length;
            epoch.number++;
            if (totalSpiral > 0 && stakedCoil > 0 && epoch.apr > 0) {
                uint256 mintAmount = (totalSpiral * futureIndex / initialIndex) - stakedCoil;
                stakedCoil += mintAmount;
            }
        }

        return (pendingRebasesCount, futureIndex, epoch.endBlock, stakedCoil);
    }
}