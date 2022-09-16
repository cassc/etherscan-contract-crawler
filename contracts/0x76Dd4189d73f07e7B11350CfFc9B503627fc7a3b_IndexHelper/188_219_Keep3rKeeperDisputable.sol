// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rKeeperFundable.sol";
import "../Keep3rDisputable.sol";
import "../../../interfaces/external/IKeep3rV1.sol";
import "../../../interfaces/peripherals/IKeep3rKeepers.sol";

abstract contract Keep3rKeeperDisputable is IKeep3rKeeperDisputable, Keep3rDisputable, Keep3rKeeperFundable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @inheritdoc IKeep3rKeeperDisputable
    function slash(
        address _keeper,
        address _bonded,
        uint256 _amount
    ) public override onlySlasher {
        if (!disputes[_keeper]) revert NotDisputed();
        _slash(_keeper, _bonded, _amount);
        emit KeeperSlash(_keeper, msg.sender, _amount);
    }

    /// @inheritdoc IKeep3rKeeperDisputable
    function revoke(address _keeper) external override onlySlasher {
        if (!disputes[_keeper]) revert NotDisputed();
        _keepers.remove(_keeper);
        _slash(_keeper, keep3rV1, bonds[_keeper][keep3rV1]);
        emit KeeperRevoke(_keeper, msg.sender);
    }

    function _slash(
        address _keeper,
        address _bonded,
        uint256 _amount
    ) internal {
        if (_bonded != keep3rV1) {
            try IERC20(_bonded).transfer(governance, _amount) returns (bool) {} catch (bytes memory) {}
        }
        bonds[_keeper][_bonded] -= _amount;
    }
}