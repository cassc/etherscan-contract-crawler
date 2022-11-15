// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ManagerUpgradeable is OwnableUpgradeable {
    address public keeper;

    event KeeperUpdated(address _keeper);

    function __ManagerUpgradeable_init() internal initializer {
        __Ownable_init_unchained();

        __ManagerUpgradeable_init_unchained();
    }

    function __ManagerUpgradeable_init_unchained() internal initializer {}

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    function isManager(address _user) internal view returns (bool) {
        return _user == owner() || _user == keeper;
    }

    /**
     * @dev Updates keeper address.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) public onlyOwner {
        keeper = _keeper;

        emit KeeperUpdated(_keeper);
    }
}