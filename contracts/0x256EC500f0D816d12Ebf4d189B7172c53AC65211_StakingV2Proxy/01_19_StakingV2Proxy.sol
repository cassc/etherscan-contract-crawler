// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./StakingV2Storage.sol";
import "./proxy/VaultProxy.sol";

contract StakingV2Proxy is
    StakingV2Storage,
    VaultProxy
{
    // addr[0] = tos, addr[1] = lockTOS
    //_epoch[0] = _epochLength, _epoch[1] =  _firstEpochTime
    function initialize(
        address _tos,
        uint256[2] memory _epoch,
        address _lockTOS,
        address _treasury,
        uint256 _basicBondPeriod
    )
        external onlyProxyOwner
        nonZeroAddress(_tos)
        nonZeroAddress(_lockTOS)
        nonZeroAddress(_treasury)
        nonZero(_basicBondPeriod)
    {
        require(_epoch[0] > 0 && _epoch[1] > 0, "zero epoch value");
        require(address(tos) == address(0), "already initialized.");

        tos = IERC20(_tos);
        lockTOS = _lockTOS;
        treasury = _treasury;

        epoch = LibStaking.Epoch({length_: _epoch[0], end: _epoch[1]});

        basicBondPeriod = _basicBondPeriod;

        index_ = 1 ether;
    }

    function isTreasury() public pure returns (bool) {
        return false;
    }
}