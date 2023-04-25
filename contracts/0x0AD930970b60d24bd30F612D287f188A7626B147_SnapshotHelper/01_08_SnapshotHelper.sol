//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SnapshotHelper is AccessControl {
    PoolGauge[] internal _poolGauge;

    struct PoolGauge {
        IERC20 pool;
        bool enabled;
    }

    event AddedPoolGauge(uint256 pid, address poolAddr);
    event ToggledEnabledPoolGaugeStatus(address poolAddr, bool newStatus);

    constructor(address[] memory poolGaugeAddr) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < poolGaugeAddr.length; i++) {
            _poolGauge.push(PoolGauge({pool: IERC20(poolGaugeAddr[i]), enabled: true}));

            emit AddedPoolGauge(_poolGauge.length - 1, poolGaugeAddr[i]);
        }
    }

    function aggregatedBalanceOf(address _account) external view returns (uint256) {
        uint256 aggregatedBalance;

        for (uint256 i = 0; i < _poolGauge.length; i++) {
            if (_poolGauge[i].enabled) {
                aggregatedBalance += _poolGauge[i].pool.balanceOf(_account);
            }
        }

        return aggregatedBalance;
    }

    function addPoolGauge(address _poolAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_poolAddress != address(0), 'zero addr');
        for (uint256 i = 0; i < _poolGauge.length; i++) {
            require(_poolAddress != address(_poolGauge[i].pool), 'duplicate');
        }

        _poolGauge.push(PoolGauge({pool: IERC20(_poolAddress), enabled: true}));
        emit AddedPoolGauge(_poolGauge.length - 1, _poolAddress);
    }

    function poolGaugeCount() external view returns (uint256) {
        return _poolGauge.length;
    }

    function togglePoolGaugeStatus(uint256 _pid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_pid < _poolGauge.length, 'incorrect pid');

        _poolGauge[_pid].enabled = !_poolGauge[_pid].enabled;

        emit ToggledEnabledPoolGaugeStatus(address(_poolGauge[_pid].pool), _poolGauge[_pid].enabled);
    }
}