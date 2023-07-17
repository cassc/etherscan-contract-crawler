// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    // Mappings
    mapping(address => mapping(address => bool)) public whitelist;

    // Events
    event WhitelistInitialized(address owner);
    event AddedToWhitelist(address indexed paymaster, address indexed account);
    event AddedBatchToWhitelist(
        address indexed paymaster,
        address[] indexed accounts
    );
    event RemovedFromWhitelist(
        address indexed paymaster,
        address indexed account
    );
    event RemovedBatchFromWhitelist(
        address indexed paymaster,
        address[] indexed accounts
    );

    // External
    function check(
        address _sponsor,
        address _account
    ) external view returns (bool) {
        return _check(_sponsor, _account);
    }

    function add(address _account) external {
        _add(_account);
        emit AddedToWhitelist(msg.sender, _account);
    }

    function addBatch(address[] calldata _accounts) external {
        _addBatch(_accounts);
        emit AddedBatchToWhitelist(msg.sender, _accounts);
    }

    function remove(address _account) external {
        _remove(_account);
        emit RemovedFromWhitelist(msg.sender, _account);
    }

    function removeBatch(address[] calldata _accounts) external {
        _removeBatch(_accounts);
        emit RemovedBatchFromWhitelist(msg.sender, _accounts);
    }

    // Internal
    function _check(
        address _sponsor,
        address _account
    ) internal view returns (bool) {
        return whitelist[_sponsor][_account];
    }

    function _add(address _account) internal {
        require(_account != address(0), "Whitelist:: Zero address");
        require(
            !_check(msg.sender, _account),
            "Whitelist:: Account is already whitelisted"
        );
        whitelist[msg.sender][_account] = true;
    }

    function _addBatch(address[] calldata _accounts) internal {
        for (uint256 ii; ii < _accounts.length; ++ii) {
            _add(_accounts[ii]);
        }
    }

    function _remove(address _account) internal {
        require(_account != address(0), "Whitelist:: Zero address");
        require(
            _check(msg.sender, _account),
            "Whitelist:: Account is not whitelisted"
        );
        whitelist[msg.sender][_account] = false;
    }

    function _removeBatch(address[] calldata _accounts) internal {
        for (uint256 ii; ii < _accounts.length; ++ii) {
            _remove(_accounts[ii]);
        }
    }
}