// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "hardhat/console.sol";
import "../base/Multicall.sol";

interface IDepegShieldWrapper {
    function isTriggered(uint256 _pid, address _underlyingToken) external view returns (bool);

    function getInfo(uint256 _pid, address _underlyingToken)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function checkAndToggleTrigger(uint256 _pid, address _underlyingToken) external returns (bool);
}

interface IDepegShield {
    function checkTrigger(address _pool, bytes calldata _args) external view returns (bool);
}

interface ILendingMarket {
    struct PoolInfo {
        uint256 convexPid;
    }

    function triggerDepegShield(uint256 _pid) external;

    function depegShields(uint256 _pid) external view returns (address);

    function convexBooster() external view returns (address);

    function getCurveCoinId(uint256 _pid, uint256 _supportPid) external view returns (int128);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
}

contract ChainlinkKeeper is Ownable, Multicall, KeeperCompatibleInterface {
    using SafeERC20 for IERC20;

    bool public paused;

    event Triggered(address lendingMarket, address depegShieldWrapper, uint256 pid, address underlyingToken);
    event Report(uint256 blockNumber, uint256 gasPrice, uint256 gasUsed);

    function checkUpkeep(bytes calldata _data) external override returns (bool upkeepNeeded, bytes memory performData) {
        require(!paused, "!Paused");

        (address lendingMarket, address depegShieldWrapper, uint256 pid, address underlyingToken) = abi.decode(_data, (address, address, uint256, address));

        if (depegShieldWrapper != address(0)) {
            bool isTriggered = IDepegShieldWrapper(depegShieldWrapper).isTriggered(pid, underlyingToken);

            if (isTriggered) return (false, abi.encode(0x0));

            if (IDepegShieldWrapper(depegShieldWrapper).checkAndToggleTrigger(pid, underlyingToken)) {
                return (true, _data);
            }
        }

        return (false, abi.encode(0x0));
    }

    function performUpkeep(bytes calldata _data) external override {
        uint256 gasBefore = gasleft();

        require(!paused, "!Paused");

        (address lendingMarket, address depegShieldWrapper, uint256 pid, address underlyingToken) = abi.decode(_data, (address, address, uint256, address));

        ILendingMarket(lendingMarket).triggerDepegShield(pid);

        emit Triggered(lendingMarket, depegShieldWrapper, pid, underlyingToken);

        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        _report(gasUsed);
    }

    function _report(uint256 _gasUsed) internal {
        emit Report(block.number, tx.gasprice, _gasUsed);
    }

    function setPause(bool _pauseState) external onlyOwner {
        paused = _pauseState;
    }

    function recoverFunds(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);

        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function encode(
        address _lendingMarket,
        address _depegShieldWrapper,
        uint256 _pid,
        address _underlyingToken
    ) public pure returns (bytes memory) {
        return abi.encode(_lendingMarket, _depegShieldWrapper, _pid, _underlyingToken);
    }
}